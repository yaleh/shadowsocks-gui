localStorage = null
if window?
  localStorage = window.localStorage
else
  LocalStorage = require('node-localstorage').LocalStorage
  localStorage = new LocalStorage './test_storage'
util = require 'util'

fs = require 'fs'
hydrate = require 'hydrate'

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

    s = @hydrate.stringify configs
    if window?
      localStorage[@key] = s
    else
      localStorage.setItem(@key, s)

  loadString: ->
    return if window? then localStorage[@key] else localStorage.getItem @key

exports.ServerConfig = ServerConfig
exports.Configs = Configs
exports.ConfigsLocalStorage = ConfigsLocalStorage

