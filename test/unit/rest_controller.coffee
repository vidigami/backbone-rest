_ = require 'underscore'
Queue = require 'queue-async'

Fabricator = require 'backbone-node/fabricator'
MockServerModel = require 'backbone-node/mocks/server_model'

test_parameters =
  model_type: MockServerModel
  route: 'mock_models'
  beforeEach: (callback) ->
    queue = new Queue(1)
    queue.defer (callback) -> MockServerModel.destroy {}, callback
    queue.defer (callback) -> Fabricator.create(MockServerModel, 10, {id: Fabricator.uniqueId('id_'), name: Fabricator.uniqueId('mock_')}, callback)
    queue.await (err) -> callback(null, _.map(MockServerModel.MODELS = _.toArray(arguments).pop(), (test) -> test.attributes))

require('../../lib/test_generators/backbone_rest')(test_parameters)
