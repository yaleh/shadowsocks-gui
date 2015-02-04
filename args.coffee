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
  @DEFAULT_CONFIG_INDEX = -2
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
#    console.log "getConfig(): #{ n }"
    if n == null or n == Configs.DEFAULT_CONFIG_INDEX
      return @defaultConfig
    else if n == Configs.PUBLIC_CONFIG_INDEX
      return @publicConfig
    else
      return @configs[n]

  # Set the **n**th config
  #
  setConfig: (n, config) ->
    if n < 0 or n >= @getConfigCount()
      return null
    @configs[n] = config

  # Add a new config to the end
  #
  addConfig: (config) ->
    @configs.push config

  # Get the count of configs
  #
  getConfigCount: ->
    @configs.length

  # Delete a config
  #
  deleteConfig: (n) ->
    if (n != null) and
    (n != Configs.DEFAULT_CONFIG_INDEX) and
    (n != Configs.PUBLIC_CONFIG_INDEX)
      @configs.splice n,1
    # setActiveConfigIndex will adjust the active index after deleting a config
    @setActiveConfigIndex @getActiveConfigIndex()

  # Get the current active config index
  #
  getActiveConfigIndex: ->
    return if @activeConfigIndex? and not isNaN(@activeConfigIndex) \
      then @activeConfigIndex \
      else Configs.DEFAULT_CONFIG_INDEX

  # Set the active config index
  #
  setActiveConfigIndex: (n) ->
    if not n?
      @activeConfigIndex = Configs.PUBLIC_CONFIG_INDEX
    if n >= @getConfigCount()
      n = @getConfigCount() - 1
    if n >= 0 or
    n == Configs.DEFAULT_CONFIG_INDEX or
    n == Configs.PUBLIC_CONFIG_INDEX
      @activeConfigIndex = n
    else
      @activeConfigIndex = Configs.PUBLIC_CONFIG_INDEX

  # Get the active config
  #
  getActiveConfig: ->
#    console.log "getActiveConfig(): #{ @getActiveConfigIndex() }"
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
#      confs = configsStorage.loadConfigs
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
  loadConfigs: (defaultConfig = null, publicConfig = null) ->
    s = @loadString(@key)
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
      localStorage.setItem @key, s

  # Save configs to storage.
  #
  saveConfigs: (configs) ->
    s = @hydrate.stringify configs
    if window?
      localStorage[@key] = s
    else
      localStorage.setItem @key, s

  # A function to test localStorage
  #
  loadString: (k=@key) ->
    return if window? then localStorage[k] else localStorage.getItem k

  # Return the key for server history
  #
  getServerHistoryKey: ->
    "#{ @key }/history"

  # Get server history
  #
  getServerHistory: ->
    s = @loadString @getServerHistoryKey()
    return (s || '').split('|')

  # Add a new item to server history
  #
  addServerHistory: (server) ->
    servers = @getServerHistory()
    servers.push server
    newServers = []
    for server in servers
      if server and server not in newServers
        newServers.push server
    s = newServers.join '|'
    if window?
      localStorage[@getServerHistoryKey()] = s
    else
      localStorage.setItem @getServerHistoryKey(), s

  reset: ->
    if window?
      delete localStorage[@key]
      delete localStorage[@getServerHistoryKey()]
    else
      localStorage.removeItem @key
      localStorage.removeItem @getServerHistoryKey()

exports.ServerConfig = ServerConfig
exports.Configs = Configs
exports.ConfigsLocalStorage = ConfigsLocalStorage

