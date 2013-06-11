_ = require 'underscore'
Queue = require 'queue-async'

JSONUtils = require 'backbone-node/json_utils'
MockServerModel = require 'backbone-node/mocks/server_model'
Fabricator = require 'backbone-node/fabricator'

test_parameters =
  model_type: MockServerModel
  route: 'mock_models'
  beforeEach: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> MockServerModel.destroy {}, callback
    queue.defer (callback) -> Fabricator.create(MockServerModel, 10, {name: Fabricator.uniqueId('album_'), created_at: Fabricator.date, updated_at: Fabricator.date}, callback)
    queue.await (err) -> callback(null, _.map(_.toArray(arguments).pop(), (test) -> JSONUtils.valueToJSON(test.toJSON())))

require('../../lib/test_generators/backbone_rest')(test_parameters)
require('../../lib/test_generators/backbone_rest_sorted')(test_parameters)
