express = require 'express'
bodyParser = require 'body-parser'

module.exports = ->
  app = express()
  app.use(bodyParser())
  return app
