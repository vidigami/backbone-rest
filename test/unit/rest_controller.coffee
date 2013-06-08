testGenerator = require '../lib/test_generator'

_ = require 'underscore'
MockServerModel = require '../mocks/server_model'

testGenerator {
  model_type: MockServerModel
  route: 'mock_models'
  beforeEach: (callback) ->
    counter = 0
    MockServerModel.MODELS_JSON = [
      {id: _.uniqueId('id'), name: _.uniqueId('name_'), created_at: (new Date).toISOString(), value1: counter++}
      {id: _.uniqueId('id'), name: _.uniqueId('name_'), created_at: (new Date).toISOString(), value1: counter++}
      {id: _.uniqueId('id'), name: _.uniqueId('name_'), created_at: (new Date).toISOString(), value1: counter++}
    ]
    callback(null, MockServerModel.MODELS_JSON)
}