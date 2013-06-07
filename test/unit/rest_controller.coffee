util = require 'util'
assert = require 'assert'
request = require 'supertest'
express = require 'express'
_ = require 'underscore'

RestController = require '../../rest_controller'

MockServerModel = require '../mocks/server_model'

describe 'RestController', ->
  beforeEach (done) ->
    counter = 0
    MockServerModel.ACTIVE_MODELS_JSON = [
      {id: _.uniqueId('id'), name: _.uniqueId('name_'), created_at: (new Date).toISOString(), value1: counter++}
      {id: _.uniqueId('id'), name: _.uniqueId('name_'), created_at: (new Date).toISOString(), value1: counter++}
      {id: _.uniqueId('id'), name: _.uniqueId('name_'), created_at: (new Date).toISOString(), value1: counter++}
    ]
    done()

  describe 'index', ->
    it 'should return json for all models with no query', (done) ->
      app = express(); app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      request(app)
        .get('/mock_models')
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(MockServerModel.ACTIVE_MODELS_JSON, res.body, 'models json returned')
          done()

    it 'should select requested keys by single key', (done) ->
      app = express(); app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      request(app)
        .get('/mock_models')
        .query({$select: 'name'})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(_.map(MockServerModel.ACTIVE_MODELS_JSON, (item) -> _.pick(item, 'name')), res.body, 'models json returned')
          done()

    it 'should select requested keys by an array of keys', (done) ->
      app = express(); app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      request(app)
        .get('/mock_models')
        .query({$select: ['name', 'created_at']})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(_.map(MockServerModel.ACTIVE_MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), res.body, 'models json returned')
          done()

    it 'should select requested values by single key', (done) ->
      app = express(); app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      request(app)
        .get('/mock_models')
        .query({$values: 'name'})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(_.map(MockServerModel.ACTIVE_MODELS_JSON, (item) -> _.values(_.pick(item, 'name'))), res.body, 'models json returned')
          done()

    it 'should select requested values by an array of keys', (done) ->
      app = express(); app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      request(app)
        .get('/mock_models')
        .query({$values: ['name', 'created_at']})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(_.map(MockServerModel.ACTIVE_MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at']))), res.body, 'models json returned')
          done()

  describe 'show', ->
    it 'should find an existing model', (done) ->
      app = express(); app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      request(app)
        .get("/mock_models/#{MockServerModel.ACTIVE_MODELS_JSON[0].id}")
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(MockServerModel.ACTIVE_MODELS_JSON[0], res.body, 'found the model')
          done()

  describe 'create', ->
    it 'should create a new model and assign an id', (done) ->
      app = express()
      app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      attributes = {name: 'modelE'}
      request(app)
        .post('/mock_models')
        .send(attributes)
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.ok(!!res.body.id, 'assigned an id')
          assert.equal(attributes.name, res.body.name, 'name matches')
          done()

  describe 'update', ->
    it 'should update an existing model', (done) ->
      app = express()
      app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      attributes = _.clone(MockServerModel.ACTIVE_MODELS_JSON[1])
      attributes.name = "#{attributes.name}_#{_.uniqueId('name')}"
      attributes.something = true
      request(app)
        .put("/mock_models/#{attributes.id}")
        .send(attributes)
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(attributes, res.body, 'model was updated')
          done()

  describe 'delete', ->
    it 'should delete an existing model', (done) ->
      app = express()
      app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      id = MockServerModel.ACTIVE_MODELS_JSON[1].id
      request(app)
        .del("/mock_models/#{id}")
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          done()
