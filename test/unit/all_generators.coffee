_ = require 'underscore'
path = require 'path'
Queue = require 'backbone-orm/lib/queue'
DirectoryUtils = require '../lib/directory_utils'

FRAMEWORK_APP_FACTORIES = DirectoryUtils.functionModules path.resolve path.dirname(module.filename), '../lib/frameworks'

module.exports = (options, callback) ->
  test_parameters = _.extend options,
    database_url: '/test'
    schema:
      name: ['String', indexed: true]
      created_at: 'DateTime'
      updated_at: 'DateTime'
    sync: require('backbone-orm/lib/memory/sync')
    embed: true

  queue = new Queue(1)
  _.each FRAMEWORK_APP_FACTORIES, (app_factory, app_factory_name) ->
    queue.defer (callback) ->
      require('../generators/all')(_.extend({app_factory, app_factory_name}, test_parameters), callback)

  queue.await callback
