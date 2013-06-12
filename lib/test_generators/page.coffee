# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  MODEL_TYPE = options.model_type
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null
  ROUTE = options.route

  util = require 'util'
  assert = require 'assert'
  request = require 'supertest'
  express = require 'express'
  _ = require 'underscore'

  RestController = require '../../rest_controller'

  describe 'RestController', ->
    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'Cursor can chain limit with paging', (done) ->
      LIMIT = 3

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

      request(app)
        .get("/#{ROUTE}")
        .query({$page: true, $limit: LIMIT})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, 'no errors')
          assert.ok(!!data = res.body, 'got data')
          assert.ok(data.rows, 'received models')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can chain limit with paging (no true or false)', (done) ->
      LIMIT = 3

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

      request(app)
        .get("/#{ROUTE}?$page&$limit=#{LIMIT}")
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, 'no errors')
          assert.ok(!!data = res.body, 'got data')
          assert.ok(data.rows, 'received models')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can chain limit without paging', (done) ->
      LIMIT = 3

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

      request(app)
        .get("/#{ROUTE}")
        .query({$page: false, $limit: LIMIT})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, 'no errors')
          assert.ok(!!(data = res.body), 'got data')
          assert.equal(LIMIT, data.length, "Expected: #{LIMIT}, Actual: #{data.length}")
          done()

    it 'Cursor can chain limit and offset with paging', (done) ->
      LIMIT = 2; OFFSET = 1

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

      request(app)
        .get("/#{ROUTE}")
        .query({$page: true, $limit: LIMIT, $offset: OFFSET})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, 'no errors')
          assert.ok(!!data = res.body, 'got data')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(OFFSET, data.offset, 'has the correct offset')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can select fields with paging', (done) ->
      FIELD_NAMES = ['id', 'name']

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

      request(app)
        .get("/#{ROUTE}")
        .query({$page: true, $select: FIELD_NAMES})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, 'no errors')
          assert.ok(!!data = res.body, 'got data')
          for json in data.rows
            assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Cursor can select values with paging', (done) ->
      FIELD_NAMES = ['id', 'name']

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

      request(app)
        .get("/#{ROUTE}")
        .query({$page: true, $values: FIELD_NAMES})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, 'no errors')
          assert.ok(!!data = res.body, 'got data')
          assert.ok(_.isArray(data.rows), 'cursor values is an array')
          for json in data.rows
            assert.ok(_.isArray(json), 'cursor item values is an array')
            assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
          done()
