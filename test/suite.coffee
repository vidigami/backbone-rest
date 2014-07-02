path = require 'path'
_ = require 'underscore'

BackboneORM = require 'backbone-orm'
Queue = BackboneORM.Queue

DirectoryUtils = require './lib/directory_utils'

FRAMEWORK_APP_FACTORIES = DirectoryUtils.functionModules(path.resolve(path.dirname(module.filename), './lib/frameworks'))

option_sets = require 'backbone-orm/test/option_sets'
# option_sets = option_sets.slice(0, 1)

framework_queue = new Queue(1)
for app_factory_name, app_factory of FRAMEWORK_APP_FACTORIES
  do (app_factory_name, app_factory) -> framework_queue.defer (callback) ->

    queue = new Queue(1)
    for options in option_sets
      do (options) -> queue.defer (callback) ->
        console.log "\nBackbone REST (#{app_factory_name}): Running tests with options: ", options
        require('./unit/all_generators')(_.extend({app_factory, app_factory_name}, options), callback)
    queue.await -> console.log "Backbone REST: Completed tests for framework #{app_factory_name}"; callback()

framework_queue.await -> console.log "Backbone REST: Completed all tests"
