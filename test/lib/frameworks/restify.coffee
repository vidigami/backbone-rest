restify = require 'restify'

# TODO: set up restify for testing
module.exports = ->
  app = restify.createServer({name: 'testapp', version: '0.0.0'})
  app.use(restify.queryParser())
  app.use(restify.bodyParser())
  app
