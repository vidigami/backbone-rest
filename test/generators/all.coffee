BackboneORM = require 'backbone-orm'
Queue = BackboneORM.Queue

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> require('./backbone_rest')(options, callback)
  queue.defer (callback) -> require('./backbone_rest_sorted')(options, callback)
  queue.defer (callback) -> require('./page')(options, callback)
  queue.defer (callback) -> require('./join_tables')(options, callback)
  queue.defer (callback) -> require('./config')(options, callback)
  queue.await callback
