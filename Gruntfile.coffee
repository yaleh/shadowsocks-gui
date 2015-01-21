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
        src: ['*.coffee','!Gruntfile.coffee']
        ext: '.js'
      debug:
        options:
          sourceMap: true
        expand: true
        flatten: false
        src: ['*.coffee','!Gruntfile.coffee']
        ext: '.js'
    clean: ["*.html","main.js","args.js","update.js","*.map","test_storage"]
    watch:
      all:
        files: ['index.jade', '*.coffee']
        tasks: ['newer:coffee:debug', 'newer:jade']

  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-jade"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-newer"

  grunt.registerTask "default", ["jade", "coffee:production"]
  grunt.registerTask "debug", ["jade", "coffee:debug"]
