path = require 'path'
_ = require 'underscore'

BackboneORM = require 'backbone-orm'
Queue = BackboneORM.Queue

option_sets = require 'backbone-orm/test/option_sets'
# option_sets = option_sets.slice(0, 1)

framework_queue = new Queue(1)
for app_factory_name, app_factory of require './lib/all_frameworks'
  do (app_factory_name, app_factory) -> framework_queue.defer (callback) ->

    queue = new Queue(1)
    for options in option_sets
      do (options) -> queue.defer (callback) ->
        console.log "\nBackbone REST (#{app_factory_name}): Running tests with options: ", options
        require('./unit/all_generators')(_.extend({app_factory, app_factory_name}, options), callback)
    queue.await -> console.log "Backbone REST: Completed tests for framework #{app_factory_name}"; callback()

framework_queue.await -> console.log "Backbone REST: Completed all tests"
