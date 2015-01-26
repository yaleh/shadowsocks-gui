localStorage = null
if window?
  localStorage = window.localStorage
else
  LocalStorage = require('node-localstorage').LocalStorage
  localStorage = new LocalStorage './test_storage'
util = require 'util'

fs = require 'fs'
hydrate = require 'hydrate'

guiconfigFilename = fs.realpathSync(process.execPath + '/..') + '/gui-config.json'

class ServerConfig
  constructor: (@server=null,
                @server_port=8388,
                @local_port=1080,
                @password=null,
                @method='aes-256-cfb',
                @timeout=600) ->

class Configs
  @DEFAULT_CONFIG_INDEX = NaN
  @PUBLIC_CONFIG_INDEX = -1

  constructor: (@defaultConfig = null, @publicConfig = null) ->
    @configs = []
    @activeConfigIndex = NaN

  getConfig: (n) ->
    if n == null or isNaN(n)
      return @defaultConfig
    else if n == Configs.PUBLIC_CONFIG_INDEX
      return @publicConfig
    else
      return @configs[n]

  setConfig: (n, config) ->
    @configs[n] = config

  addConfig: (config) ->
    @configs.push config
    @setActiveConfigIndex @getActiveConfigIndex()

  getConfigCount: ->
    @configs.length

  deleteConfig: (n) ->
    if (n != null) and (not isNaN(n)) and not (n == Configs.PUBLIC_CONFIG_INDEX)
      @configs.splice n,1
    @setActiveConfigIndex @getActiveConfigIndex()

  getActiveConfigIndex: ->
    return if @activeConfigIndex? then @activeConfigIndex else NaN

  setActiveConfigIndex: (n) ->
    if n?
      if n >= @getConfigCount()
        n = @getConfigCount()
      else if n < Configs.PUBLIC_CONFIG_INDEX
        n = Configs.PUBLIC_CONFIG_INDEX
    @activeConfigIndex = n

  getActiveConfig: ->
    return @getConfig @getActiveConfigIndex()

  setDefaultConfig: (config) ->
    @defaultConfig = config

  setPublicConfig: (config) ->
    @publicConfig = config

class ConfigsLocalStorage
  constructor: (@key) ->
    resolver = new hydrate.ContextResolver
      Configs:Configs
      ServerConfig:ServerConfig
    @hydrate = new hydrate resolver

  initConfigs: (defaultConfig, publicConfig) ->
    configs = new Configs(defaultConfig, publicConfig)
    return configs

  load: (defaultConfig = null, publicConfig = null) ->
    s = @loadString()
#    console.log s
    try
      if s?
        configs = @hydrate.parse s
        configs.setDefaultConfig defaultConfig
        configs.setPublicConfig publicConfig
        return configs
      else
        return new Configs defaultConfig, publicConfig
    catch SyntaxError
      return new Configs defaultConfig, publicConfig

  save: (configs) ->
    s = @hydrate.stringify configs
    if window?
      localStorage[@key] = s
    else
      localStorage.setItem(@key, s)

  loadString: ->
    return if window? then localStorage[@key] else localStorage.getItem @key

loadFromJSON = ->
  # Windows users are happy to see a config file within their shadowsocks-gui folder
  if process.platform == 'win32'
    try
      data = fs.readFileSync guiconfigFilename
      temp = JSON.parse data.toString('utf-8')
      # make config file easier to read
      if temp.configs
        temp.configs = JSON.stringify(temp.configs)
      localStorage = temp
      util.log 'reading config file'
    catch e
      console.log e

loadFromJSON()

saveToJSON = ->
  if process.platform == 'win32'
    util.log 'saving config file'
    # make config file easier to read
    temp = JSON.parse(JSON.stringify(localStorage))
    if temp.configs
      temp.configs = JSON.parse(temp.configs)
    data = JSON.stringify(temp, null, 2)
    try
      fs.writeFileSync guiconfigFilename, data, 'encoding': 'utf-8'
    catch e
      util.log e

# This is a public server
publicConfig =
  server: '209.141.36.62'
  server_port: 8348
  local_port: 1080
  password: '$#HAL9000!'
  method: 'aes-256-cfb'
  timeout: 600

defaultConfig =
  server_port: 8388
  local_port: 1080
  method: 'aes-256-cfb'
  timeout: 600


loadConfigs = ->
  try
    JSON.parse(localStorage['configs'] or '[]')
  catch e
    util.log e
    []

allConfigs = ->
  try
    localStorage['configs']
  catch e
    return []

  if localStorage['configs']
    result = []
    try
      configs = loadConfigs()
      for i of configs
        c = configs[i]
        result.push "#{c.server}:#{c.server_port}"
      return result
    catch e
  []

saveIndex = (index) ->
  localStorage['index'] = index
  saveToJSON()

loadIndex = ->
  try
    return +localStorage['index']
  catch e
    return 1

saveConfigs = (configs) ->
  localStorage['configs'] = JSON.stringify(configs)
  saveToJSON()

saveConfig = (index, config) ->
  if index == -1
    # if modified based on public server, add a profile, not to modify public server
    index = NaN
  configs = loadConfigs()
  if isNaN(index)
    configs.push config
    index = configs.length - 1
  else
    configs[index] = config
  saveConfigs configs
  index

loadConfig = (index) ->
  if isNaN(index)
    return defaultConfig
  if index == -1
    return publicConfig
  configs = loadConfigs()
  return configs[index] or defaultConfig

deleteConfig = (index) ->
  if (not isNaN(index)) and not (index == -1)
    configs = loadConfigs()
    configs.splice index, 1
    saveConfigs configs

exports.ServerConfig = ServerConfig
exports.Configs = Configs
exports.ConfigsLocalStorage = ConfigsLocalStorage

exports.allConfigs = allConfigs
exports.saveConfig = saveConfig
exports.loadConfig = loadConfig
exports.deleteConfig = deleteConfig
exports.loadIndex = loadIndex
exports.saveIndex = saveIndex
exports.publicConfig = publicConfig
