chai = require 'chai'
chai.should()
expect = chai.expect

args = require '../args'

describe 'ServerConfig', ->
  serverConfig = null
  it "should have a server with server of null", ->
    serverConfig = new args.ServerConfig
    expect(serverConfig.server).to.be.a 'null'
  it "should returns an ss uri of a default server config", ->
    (new Buffer serverConfig.uri().slice(5), 'base64').toString('ascii'). \
      should.equal 'aes-256-cfb:null@null:8388'
    serverConfig.uri().should.equal 'ss://YWVzLTI1Ni1jZmI6bnVsbEBudWxsOjgzODg='
  it "should return an ss uri", ->
    serverConfig = new args.ServerConfig '8.8.8.8'
    (new Buffer serverConfig.uri().slice(5), 'base64').toString('ascii'). \
      should.equal 'aes-256-cfb:null@8.8.8.8:8388'


describe 'Configs', ->
  configs = null

  it "should has correct consts", ->
    args.Configs.DEFAULT_CONFIG_INDEX.should.equal -2
    args.Configs.PUBLIC_CONFIG_INDEX.should.equal -1

  it "should has no config", ->
    configs = new args.Configs
    configs.getConfigCount().should.equal 0

  it "should add a new config", ->
    configs.addConfig new args.ServerConfig
    configs.getConfigCount().should.equal 1

  it "should set an existing config", ->
    configs.setConfig 0, new args.ServerConfig '8.8.8.8'
    configs.getConfigCount().should.equal 1
    configs.getConfig(0).server.should.equal '8.8.8.8'

  it "should add one more config", ->
    configs.addConfig new args.ServerConfig
    configs.getConfigCount().should.equal 2

  it "should delete a config", ->
    configs.deleteConfig 0
    configs.getConfigCount().should.equal 1

  it "should set a valid active config index", ->
    configs.setActiveConfigIndex 0
    configs.getActiveConfigIndex().should.equal 0

  it "should revert to a valid active config index on setting an invalid one", ->
    configs.setActiveConfigIndex 100
    configs.getActiveConfigIndex().should.equal configs.getConfigCount()-1
    configs.setActiveConfigIndex -100
    configs.getActiveConfigIndex().should.equal args.Configs.PUBLIC_CONFIG_INDEX

  it "should reset active config index on clearing configs", ->
    configs.deleteConfig 0
    configs.getConfigCount().should.equal 0
    configs.getActiveConfigIndex().should.equal -1

describe 'ConfigsLocalStorage', ->
  storage = null
  storageNew = new

  it "should reset", ->
    storage = new args.ConfigsLocalStorage "Test"
    storage.reset()
    storage.getServerHistory().length.should.equal 1
    configs = storage.loadConfigs()
    configs.should.exist()
    configs.getConfigCount().should.equal 0
    expect(configs.getConfig args.Configs.DEFAULT_CONFIG_INDEX).to.be.null
    expect(configs.getConfig args.Configs.PUBLIC_CONFIG_INDEX).to.be.null

  it "should write to file", ->
    configs = new args.Configs
    configs.addConfig new args.ServerConfig
    configs.addConfig new args.ServerConfig '8.8.8.8'
    configs.addConfig new args.ServerConfig '1.2.3.4'
    r = storage.saveConfigs configs
    # save returns null if it creates a new file and an int when it rewrites a file
    expect(not r? or r > 0).to.be.true

  it "should load configs and save again", ->
    configs = storage.loadConfigs()
    configs.should.exist()
    configs.getConfigCount().should.equal 3
    configs.getActiveConfigIndex().should.equal args.Configs.DEFAULT_CONFIG_INDEX
    configs.addConfig new args.ServerConfig '4.4.4.4'
    r = storage.saveConfigs configs
    # save returns null if it creates a new file and an int when it rewrites a file
    expect(not r? or r > 0).to.be.true

  it "should loads configs for the 3rd time", ->
    configs = storage.loadConfigs()
    configs.should.exist()

    configs.configs[1].server.should.equal '8.8.8.8'
    configs.getConfigCount().should.equal 4
    configs.getActiveConfigIndex().should.equal args.Configs.DEFAULT_CONFIG_INDEX

  it "should create a new Configs if failed to load", ->
    storageNew = new args.ConfigsLocalStorage "New"
    configs = storageNew.loadConfigs()
    configs.getConfigCount().should.equal 0

  it "should return an empty history", ->
    h = storage.getServerHistory()
    h.length.should.equal 1
    h[0].should.equal ''

  it "should add new history item", ->
    storage.addServerHistory '1st.com'
    h = storage.getServerHistory()
    h.length.should.equal 1
    h[0].should.equal '1st.com'

  it "should add one more history item", ->
    storage.addServerHistory '2nd.com'
    h = storage.getServerHistory()
    h.length.should.equal 2
    h[0].should.equal '1st.com'
    h[1].should.equal '2nd.com'

  it "should reset again", ->
    storage = new args.ConfigsLocalStorage "Test"
    storage.reset()
    storage.getServerHistory().length.should.equal 1
    configs = storage.loadConfigs()
    configs.should.exist()
    configs.getConfigCount().should.equal 0
    expect(configs.getConfig args.Configs.DEFAULT_CONFIG_INDEX).to.be.null
    expect(configs.getConfig args.Configs.PUBLIC_CONFIG_INDEX).to.be.null