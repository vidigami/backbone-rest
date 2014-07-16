express = require 'express'
bodyParser = require 'body-parser'

module.exports = ->
  app = express()
  app.use(bodyParser.json())
  return app

global.__test__app_framework = factory: module.exports, name: require('path').basename(module.id, '.coffee')
