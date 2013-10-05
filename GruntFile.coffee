
config =
  useLocalIp: true

module.exports = (grunt) ->

  # Load our our dustom grunt tasks  - - - - - - - - - - - -

  grunt.loadNpmTasks 'grunt-contrib'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadTasks 'build-tasks'


  # Main config - - - - - - - - - - - - - - - - - - - - - -

  grunt.initConfig
    connect:
      server:
        options:
          port: 5020
          hostname: if config.useLocalIp then getLocalIp() else 'localhost'
          base: 'build'

    coffee:
      compile:
        files:
          'build/dollar.js': ['src/dollar.coffee' ]

    coffeelint:
      src: ['src/coffee/**/*.coffee', 'GruntFile.coffee']
      options:
        # Let us have classes named $, _
        camel_case_classes:
          level: 'ignore'

    watch:
      lint:
        files: ['GruntFile.coffee', 'grunt-tasks/**/*.coffee']
        tasks: ['coffeelint']

      coffee:
        files: ['src/coffee/**/*.coffee']
        tasks: ['coffeelint', 'coffee', 'refresh']

    uglify:
      main:
        files:
          'build/dollar.min.js': ['build/dollar.js']

    refresh:
      chrome:
        # Only refresh active tab if in url
        urlContains: ['localhost', ':50']
        # Add your computer's username here to activate auto refresh
        users: ['steve']


  # Task Groups - - - - - - - - - - - - - - - - - - - - - -

  # build
  grunt.registerTask 'build', ['coffeelint', 'stylus', 'coffee', 'uglify']

  # 'ws' is for watch + serve
  grunt.registerTask 'ws', ['connect', 'watch']


# Helpers - - - - - - - - - - - - - - - - - - - - - - - - -

os = require 'os'

getLocalIp = ->
  interfaces = os.networkInterfaces()
  for name, value of interfaces
    for details in value
      if details.family is 'IPv4' and name is 'en1'
        return details.address