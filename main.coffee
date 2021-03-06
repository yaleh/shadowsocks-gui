# Copyright (c) 2014 clowwindy, Yale Huang
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

$ ->
  os = require 'os'
  gui = require 'nw.gui'
  npm_args = require 'args'

  divWarning = $('#divWarning')
  divWarningShown = false

  # hack util.log to show logs with the status bar
  util = require 'util'
  util.log = (s) ->
    console.log new Date().toLocaleString() + " - #{s}"
    if not divWarningShown
      divWarning.removeClass('hide')
      divWarningShown = true
    divWarning.text(s)

  args = require './args'
  local = require 'shadowsocks'
  update = require './update'

  configsStorage = null
  confs = null

  update.checkUpdate (url, version) ->
    divNewVersion = $('#divNewVersion')
    span = $ "<span style='cursor:pointer'>New version #{version} found,
      click here to download</span>"
    span.click ->
      gui.Shell.openExternal url
    divNewVersion.find('.msg').append span
    divNewVersion.fadeIn()

  chooseServer = ->
    index = +$(this).attr('data-key')
    confs.setActiveConfigIndex index
    load false
    reloadServerList()

  reloadServerList = ->
    divider = $('#serverIPMenu .insert-point')
    serverMenu = $('#serverIPMenu .divider')
    $('#serverIPMenu li.server').remove()
    i = 0
    for serverConfig in confs.configs
      if i == confs.getActiveConfigIndex()
        menuItem = $("<li class='server'>
          <a tabindex='-1' data-key='#{i}' href='#'>
          <i class='icon-ok'></i> #{serverConfig.server}</a>
          </li>")
      else
        menuItem = $("<li class='server'>
          <a tabindex='-1' data-key='#{i}' href='#'>
          <i class='icon-not-ok'></i> #{serverConfig.server}</a>
          </li>")
      menuItem.find('a').click chooseServer
      menuItem.insertBefore divider, serverMenu
      i++

  addConfig = ->
    # active the default config first
    # create and save the new config until saving it
    confs.setActiveConfigIndex args.Configs.DEFAULT_CONFIG_INDEX
    reloadServerList()
    load false

  deleteConfig = ->
    confs.deleteConfig confs.getActiveConfigIndex()
    # Configs will adjust the active index
    reloadServerList()
    load false

  publicConfig = ->
    confs.setActiveConfigIndex args.Configs.PUBLIC_CONFIG_INDEX
    reloadServerList()
    load false

  save = ->
    config = {}
    $('input,select').each ->
      key = $(this).attr 'data-key'
      val = $(this).val()
      config[key] = val
    serverConfig = new args.ServerConfig \
      config.server,
      config.server_port,
      config.local_port,
      config.password,
      config.method,
      config.timeout
    n = confs.getActiveConfigIndex()
    if n == args.Configs.PUBLIC_CONFIG_INDEX
      # if modified based on public server, add a profile,
      # don't modify public server
      n = args.Configs.DEFAULT_CONFIG_INDEX
    if n == args.Configs.DEFAULT_CONFIG_INDEX
      # create a new config, see addconfig()
      confs.addConfig serverConfig
      confs.setActiveConfigIndex confs.getConfigCount()-1
    else
      confs.setConfig n, serverConfig
    configsStorage.saveConfigs confs
    reloadServerList()
    util.log 'config saved'
    restartServer confs.getActiveConfig()
    false

  load = (restart)->
    $('input,select').each ->
      key = $(this).attr 'data-key'
      try
        $(this).val confs.getActiveConfig()[key]
      catch TypeError

    if restart
      restartServer confs.getActiveConfig()

  isRestarting = false

  restartServer = (config) ->
    if config.server and +config.server_port and config.password and
    +config.local_port and config.method and +config.timeout
      if isRestarting
        util.log "Already restarting"
        return
      isRestarting = true
      start = ->
        try
          isRestarting = false
          util.log 'Starting shadowsocks...'
          window.local = local.createServer \
            config.server,
            config.server_port,
            config.local_port,
            config.password,
            config.method,
            1000 * (config.timeout or 600),
            '127.0.0.1'
          configsStorage.addServerHistory config.server
          $('#divError').fadeOut()

          # Don't hide the window, since the tray icon doesn't work for Ubuntu
          #
#          gui.Window.get().hide()

        catch e
          util.log e
      if window.local?
        try
          util.log 'Restarting shadowsocks'
          if window.local.address()
            window.local.close()
          setTimeout start, 1000
        catch e
          isRestarting = false
          util.log e
      else
        start()
    else
      $('#divError').fadeIn()

  $('#buttonSave').on 'click', save
  $('#buttonNewProfile').on 'click', addConfig
  $('#buttonDeleteProfile').on 'click', deleteConfig
  $('#buttonPublicServer').on 'click', publicConfig
  $('#buttonConsole').on 'click', ->
    gui.Window.get().showDevTools()
  $('#buttonAbout').on 'click', ->
    gui.Shell.openExternal 'https://github.com/yaleh/shadowsocks-gui'

  tray = new gui.Tray icon: 'menu_icon@2x.png'
  menu = new gui.Menu()

  tray.on 'click', ->
    gui.Window.get().show()

  show = new gui.MenuItem
    type: 'normal'
    label: 'Show'
    click: ->
      gui.Window.get().show()

  quit = new gui.MenuItem
    type: 'normal'
    label: 'Quit'
    click: ->
      gui.Window.get().close true

  options = npm_args.Options.parse [{
    name: 'config',
    shortName: 'c',
    type: 'string',
    help: 'config file',
    defaultValue: 'default'
  },{
    name: 'reset',
    shortName: 'r',
    type: 'bool',
    help: 'reset configs and server history',
    defaultValue: false
  },{
    name: 'help',
    shortName: 'h',
    type: 'bool',
    help: 'show this help',
    defaultValue: false
  }]

#  process.stdout.write options.getHelp()

  # npm_args requires two faked parameters at the beginning of argv
  try
    parsed = npm_args.parser([].concat(["node", "ss"],
      gui.App.argv)).parse(options)
  catch UnknownArg
    parsed =
      config: 'default'

  if parsed.help
    process.stdout.write options.getHelp()
    process.exit 0

  if parsed.reset or parsed.config != 'default'
    process.stdout.write \
      (if parsed.reset then "Resetting config" else "Loading config ") + \
      parsed.config + " .\n"

  configsStorage = new args.ConfigsLocalStorage parsed.config
  if parsed.reset
    # reset configs and server history
    configsStorage.reset()

  confs = configsStorage.loadConfigs \
    new args.ServerConfig,
    new args.ServerConfig \
      '209.141.36.62',
      8348,
      1080,
      '$#HAL9000!',
      'aes-256-cfb',
      600

  $('#inputServerIP').typeahead
    source: ->
      configsStorage.getServerHistory()

  show.add
  menu.append show
  menu.append quit
  tray.menu = menu
  window.tray = tray

  win = gui.Window.get()

  win.on 'minimize', ->
    this.hide() unless os.platform() == 'linux'

  win.on 'close', (quit) ->
    if os.platform() == 'darwin' and not quit
      this.hide()
    else
      this.close true

  win.setResizable(true)

  reloadServerList()
  load true
