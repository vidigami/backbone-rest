_ = require 'underscore'
Queue = require 'backbone-orm/lib/queue'

express = require 'express'
restify = require 'restify'

module.exports = (options, callback) ->
  test_parameters = _.extend options,
    database_url: '/test'
    schema:
      name: ['String', indexed: true]
      created_at: 'DateTime'
      updated_at: 'DateTime'
    sync: require('backbone-orm/lib/memory/sync')
    embed: true

  app_factories = [
    -> app = express(); app.use(express.bodyParser()); app,
    # TODO: set up restify for testing
    # -> app = restify.createServer({
    #     name: 'testapp'
    #     version: '0.0.0'
    #   }); app.use(restify.bodyParser()); app.address = (-> {address: {port: 80}}); app
  ]

  queue = new Queue(1)
  for app_factory in app_factories
    do (app_factory) ->
      queue.defer (callback) ->
        require('../generators/all')(_.extend({app_factory}, test_parameters), callback)

  queue.await callback
