flour = require 'flour'

{print} = require 'util'
{spawn} = require 'child_process'

flour.compilers.coffee.sourceMap = on

flour.compilers['jade'] = (file, cb) ->
  jade = require 'jade'
  file.read (code) ->
     fn = jade.compile code
     cb fn()

build_html = () ->
  compile 'index.jade', 'index.html'

build = () ->
  compile 'args.coffee', 'args.js'
  compile 'main.coffee', 'main.js'
  compile 'update.coffee', 'update.js'

clean = () ->
  os = require 'os'
  if os.platform() == 'win32'
    rmCmd = 'del'
  else
    rmCmd = 'rm'
  rm = spawn rmCmd, ['index.html', 'args.js', 'main.js', 'update.js']
  rm.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  rm.stdout.on 'data', (data) ->
    print data.toString()
  rm.on 'exit', (code) ->
    if code != 0
      process.exit code  


task 'build', 'Build ./ from src/', ->
  build()
  build_html()

task 'clean', 'Clean the project', ->
  clean()
