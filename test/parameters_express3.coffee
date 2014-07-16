express = require '../vendor/express'

module.exports = ->
  app = express()
  app.use(express.json())
  return app

global.__test__app_framework = factory: module.exports, name: require('path').basename(module.id, '.coffee')
