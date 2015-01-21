chai = require 'chai'
chai.should()
expect = chai.expect

args = require '../args'

describe 'ServerConfig', ->
  serverConfig = null
  it "should have a server", ->
    serverConfig = new args.ServerConfig
    serverConfig.server.should.equal 'localhost'

describe 'Configs', ->
  configs = null
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
    configs.getActiveConfigIndex().should.equal 0
    configs.setActiveConfigIndex -100
    configs.getActiveConfigIndex().should.equal 0
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
    expect(storage.save(configs)).to.not.exist
  it "should load configs", ->
    configs = storage.load()
    configs.should.exist()
    configs.configs.length.should.equal 2
    configs.activeConfigIndex.should.equal 0
  it "should failed on load a non-existing storage", ->
    storageNew = new args.ConfigsLocalStorage "New"
    configs = storageNew.load()
    console.log configs
    expect(configs).to.be.null