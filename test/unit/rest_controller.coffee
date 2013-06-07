util = require 'util'
assert = require 'assert'
request = require 'supertest'
express = require 'express'
_ = require 'underscore'

Backbone = require 'backbone'
RestController = require '../../rest_controller'

class MockCursor
  constructor: (@json, options={}) ->
    @[key] = value for key, value of options

  select: (keys) ->
    keys = [keys] unless _.isArray(keys)
    @$select = if @$select then _.intersection(@$select, keys) else keys
    return @

  values: (keys) ->
    keys = [keys] unless _.isArray(keys)
    @$values = if @$values then _.intersection(@$values, keys) else keys
    return @

  toJSON: (callback) ->
    if @$values
      json = []
      for item in @json
        result = []
        result.push(item[key]) for key in @$values where item.hasOwnProperty(key)
        json.push(result)
    else if @$select
      json = _.map(@json, (item) => _.pick(item, @$select))
    else
      json = @json
    callback(null, json)

ACTIVE_MODELS_JSON = []

class MockServerModel extends Backbone.Model
  @find: (query, callback) ->
    @queries = MockServerModel._parseQueries(query)
    json = _.find(ACTIVE_MODELS_JSON, (test) => test.id is @queries.find.id)
    callback(null, if json then new MockServerModel(json) else null)

  @cursor: (query, callback) ->
    @queries = MockServerModel._parseQueries(query)
    callback(null, new MockCursor(ACTIVE_MODELS_JSON, @queries.cursor))

  save: (attributes={}, options={}) ->
    @set(_.extend({id: _.uniqueId()}, attributes))
    ACTIVE_MODELS_JSON.push(@toJSON())
    options.success?(@)

  destroy: (options={}) ->
    id = @get('id')
    for index, json of ACTIVE_MODELS_JSON
      if json.id is id
        delete ACTIVE_MODELS_JSON[index]
        return options.success?(@)
     options.error?(@)

  @_parseQueries: (query) ->
    unless _.isObject(query)
      single_item = true
      query = {id: query}

    queries = {find: {}, cursor: {}}
    for key, value of query
      if key[0] is '$'
        queries.cursor[key] = value
      else
        queries.find[key] = value
    return queries

describe 'RestController', ->
  beforeEach (done) ->
    counter = 0
    ACTIVE_MODELS_JSON = [
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
          assert.deepEqual(ACTIVE_MODELS_JSON, res.body, 'models json returned')
          done()

    it 'should select requested keys by single string', (done) ->
      app = express(); app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      request(app)
        .get('/mock_models')
        .query({$select: 'name'})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(ACTIVE_MODELS_JSON, res.body, 'models json returned')
          done()

  describe 'show', ->
    it 'should find an existing model', (done) ->
      app = express(); app.use express.bodyParser()
      controller = new RestController(app, {model_type: MockServerModel, route: 'mock_models'})

      request(app)
        .get("/mock_models/#{ACTIVE_MODELS_JSON[0].id}")
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          assert.deepEqual(ACTIVE_MODELS_JSON[0], res.body, 'found the model')
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

      attributes = _.clone(ACTIVE_MODELS_JSON[1])
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

      id = ACTIVE_MODELS_JSON[1].id
      request(app)
        .del("/mock_models/#{id}")
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          done()
