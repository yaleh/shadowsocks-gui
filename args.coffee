localStorage = null
if window?
  # node-webkit, apply windows.localStroage
  localStorage = window.localStorage
else
  # node.js, load node-localstorage
  LocalStorage = require('node-localstorage').LocalStorage
  localStorage = new LocalStorage './test_storage'
util = require 'util'

fs = require 'fs'
hydrate = require 'hydrate'

# A config of a shadowsocks server
#
class ServerConfig

  # Constructor of ServerConfig
  #
  constructor: (@server=null, # server address, IP or hostname
                @server_port=8388, # server port
                @local_port=1080, # local SOCKS5 proxy port
                @password=null, # shadowsocks password
                @method='aes-256-cfb', # encrypting method
                @timeout=600 ) -> # timeout in seconds

# A container of ServerConfig items
#
# Accessing config items:
#
#     configs.setConfig n, new ServerConfig()
#     config = configs.getConfig n
#
class Configs
  # The index of the default config
  @DEFAULT_CONFIG_INDEX = NaN
  # The index of the public config
  @PUBLIC_CONFIG_INDEX = -1

  # Constructor of Configs
  #
  constructor: (@defaultConfig = null, # object of the default config
                @publicConfig = null ) -> # object of the public config
    @configs = []
    @activeConfigIndex = NaN

  # Get the **n**th config
  #
  getConfig: (n) ->
    if n == null or isNaN(n)
      return @defaultConfig
    else if n == Configs.PUBLIC_CONFIG_INDEX
      return @publicConfig
    else
      return @configs[n]

  # Set the **n**th config
  #
  setConfig: (n, config) ->
    @configs[n] = config

  # Add a new config to the end
  #
  addConfig: (config) ->
    @configs.push config
    @setActiveConfigIndex @getActiveConfigIndex()

  # Get the count of configs
  #
  getConfigCount: ->
    @configs.length

  # Delete a config
  #
  deleteConfig: (n) ->
    if (n != null) and (not isNaN(n)) and not (n == Configs.PUBLIC_CONFIG_INDEX)
      @configs.splice n,1
    @setActiveConfigIndex @getActiveConfigIndex()

  # Get the current active config index
  #
  getActiveConfigIndex: ->
    return if @activeConfigIndex? then @activeConfigIndex else NaN

  # Set the active config index
  #
  setActiveConfigIndex: (n) ->
    if n?
      if n >= @getConfigCount()
        n = @getConfigCount()
      else if n < Configs.PUBLIC_CONFIG_INDEX
        n = Configs.PUBLIC_CONFIG_INDEX
    @activeConfigIndex = n

  # Get the active config
  #
  getActiveConfig: ->
    return @getConfig @getActiveConfigIndex()

  # Set default config
  #
  setDefaultConfig: (config) ->
    @defaultConfig = config

  # Set public config
  #
  setPublicConfig: (config) ->
    @publicConfig = config

# The storage of configs, handling loading/saving ops
#
# Example:
#
#      configsStorage = new args.ConfigsLocalStorage 'key'
#      confs = configsStorage.load
#        new args.ServerConfig,
#        new args.ServerConfig
#          '209.141.36.62',
#          8348,
#          1080,
#          '$#HAL9000!',
#          'aes-256-cfb',
#          600
#
class ConfigsLocalStorage

  # Constructor
  #
  # **@key** for the storage key
  #
  constructor: (@key) ->
    resolver = new hydrate.ContextResolver
      Configs:Configs
      ServerConfig:ServerConfig
    @hydrate = new hydrate resolver

  # A private function to initializing config container
  #
  initConfigs: (defaultConfig, publicConfig) ->
    configs = new Configs(defaultConfig, publicConfig)
    return configs

  # Load configs from storage.
  #
  # * localStorage[] for node-webkit
  # * node-localstorage for node.js ( mocha test )
  #
  load: (defaultConfig = null, publicConfig = null) ->
    s = @loadString()
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

  # Save configs to storage.
  #
  save: (configs) ->
    s = @hydrate.stringify configs
    if window?
      localStorage[@key] = s
    else
      localStorage.setItem(@key, s)

  # A function to test localStorage
  #
  loadString: ->
    return if window? then localStorage[@key] else localStorage.getItem @key

exports.ServerConfig = ServerConfig
exports.Configs = Configs
exports.ConfigsLocalStorage = ConfigsLocalStorage

