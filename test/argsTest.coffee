chai = require 'chai'
chai.should()
expect = chai.expect

args = require '../args'

describe 'ServerConfig', ->
  serverConfig = null
  it "should have a server with server of null", ->
    serverConfig = new args.ServerConfig
    expect(serverConfig.server).to.be.a('null')

describe 'Configs', ->
  configs = null
  it "should has correct consts", ->
    expect(args.Configs.DEFAULT_CONFIG_INDEX).to.deep.equal NaN
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
    configs.getActiveConfigIndex().should.equal configs.getConfigCount()
    configs.setActiveConfigIndex -100
    configs.getActiveConfigIndex().should.equal args.Configs.PUBLIC_CONFIG_INDEX
  it "should reset active config index on clearing configs", ->
    configs.deleteConfig 0
    configs.getConfigCount().should.equal 0
    configs.getActiveConfigIndex().should.equal -1

describe 'ConfigsLocalStorage', ->
  storage = null
  storageNew = new
  it "should write to file", ->
    storage = new args.ConfigsLocalStorage "Test"
    configs = new args.Configs
    configs.addConfig new args.ServerConfig
    configs.addConfig new args.ServerConfig '8.8.8.8'
    configs.addConfig new args.ServerConfig '1.2.3.4'
    r = storage.save configs
    # save returns null if it creates a new file and an int when it rewrites a file
    expect(not r? or r > 0).to.be.true
#    console.log storage.loadString()
  it "should load configs and save again", ->
    configs = storage.load()
    configs.should.exist()
    configs.getConfigCount().should.equal 3
    expect(configs.getActiveConfigIndex()).to.deep.equal(NaN)
    configs.addConfig new args.ServerConfig '4.4.4.4'
    r = storage.save configs
    # save returns null if it creates a new file and an int when it rewrites a file
    expect(not r? or r > 0).to.be.true
  it "should loads configs for the 3rd time", ->
    configs = storage.load()
    configs.should.exist()
    console.log storage.loadString()
    console.log configs
    configs.configs[1].server.should.equal '8.8.8.8'
    configs.getConfigCount().should.equal 4
    expect(configs.getActiveConfigIndex()).to.deep.equal(NaN)
  it "should create a new Configs if failed to load", ->
    storageNew = new args.ConfigsLocalStorage "New"
    configs = storageNew.load()
#    console.log configs
    configs.getConfigCount().should.equal 0