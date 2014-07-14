{print} = require 'util'
{spawn} = require 'child_process'

build_html = () ->
  jade   = require 'jade'
  fs     = require 'fs'
  
  content = fs.readFileSync('index.jade').toString()
  buff     = jade.compile content               # create buffer of jade content
  html     = buff { title: 'async-flow' }       # jade => html
  filename = 'index.html'    # get file name
  compiled = fs.writeFileSync filename, html    # save compiled .jade to .html

build = () ->
  os = require 'os'
  if os.platform() == 'win32'
    coffeeCmd = 'coffee.cmd'
  else
    coffeeCmd = 'coffee'
  coffee = spawn coffeeCmd, ['-c', '-o', '.', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    if code != 0
      process.exit code

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