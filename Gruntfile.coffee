sh = require("sh")

module.exports = (grunt) ->
  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")
    jade:
      all:
        files:
          "index.html": "index.jade"
    coffee:
      production:
        options:
          sourceMap: false
        expand: true
        flatten: false
        src: ['*.coffee','test/*.coffee','!Gruntfile.coffee']
        ext: '.js'
      debug:
        options:
          sourceMap: true
        expand: true
        flatten: false
        src: ['*.coffee','test/*.coffee','!Gruntfile.coffee']
        ext: '.js'
    coffeelint:
      app: ['*.coffee']
    docco:
      debug:
        src: ['*.coffee','test/*.coffee','!Gruntfile.coffee']
        options:
          output: 'docs'
    clean: ["*.html",
            "main.js",
            "args.js",
            "update.js",
            "test/*.js",
            "test/*.map",
            "*.map",
            "test_storage"]
    watch:
      all:
        files: ['index.jade', '*.coffee', 'test/*.coffee']
        tasks: ['newer:coffee:debug', 'newer:jade', 'newer:docco:debug']

  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-jade"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-newer"
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-docco'

  grunt.registerTask "default", ['coffeelint', "jade", "coffee:production"]
  grunt.registerTask "debug", ['coffeelint',
                               "jade",
                               "coffee:debug",
                               'docco:debug']
