_ = require 'underscore'
Queue = require 'queue-async'

JSONUtils = require 'backbone-node/json_utils'
Fabricator = require 'backbone-node/fabricator'
MockServerModel = require 'backbone-node/mocks/server_model'

test_parameters =
  model_type: MockServerModel
  route: 'mock_models'
  beforeEach: (callback) ->
    MockServerModel.MODELS = Fabricator.new(MockServerModel, 10, {id: Fabricator.uniqueId('id_'), name: Fabricator.uniqueId('name_'), created_at: Fabricator.date, updated_at: Fabricator.date})
    callback(null, _.map(MockServerModel.MODELS, (model) -> JSONUtils.valueToJSON(model.toJSON())))

require('../../lib/test_generators/backbone_rest')(test_parameters)
