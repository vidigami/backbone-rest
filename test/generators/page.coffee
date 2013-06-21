util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require 'backbone-orm/fabricator'
Utils = require 'backbone-orm/utils'
adapters = Utils.adapters

request = require 'supertest'
express = require 'express'

RestController = require '../../rest_controller'

sortO = (array, field) -> _.sortBy(array, (obj) -> JSON.stringify(obj[field]))
sortA = (array) -> _.sortBy(array, (item) -> JSON.stringify(item))

runTests = (options, cache, embed) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  MODELS_JSON = null
  ROUTE = "#{DATABASE_URL}/flats"

  class Flat extends Backbone.Model
    url: "#{DATABASE_URL}/flats"
    sync: SYNC(Flat, cache)

  describe "RestController (page: true, cache: #{cache} embed: #{embed})", ->

    beforeEach (done) ->
      queue = new Queue(1)

      queue.defer (callback) -> Flat.destroy callback

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, (err, models) ->
        return callback(err) if err
        MODELS_JSON = sortO(_.map(models, (test) -> test.toJSON()), 'name') # need to sort because not sure what order will come back from database
        callback()
      )

      queue.await done

    it 'Cursor can chain limit with paging', (done) ->
      LIMIT = 3

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: true, $limit: LIMIT})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          assert.ok(data.rows, 'received models')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can chain limit with paging (no true or false)', (done) ->
      LIMIT = 3

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get("#{ROUTE}?$page&$limit=#{LIMIT}")
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          assert.ok(data.rows, 'received models')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can chain limit without paging', (done) ->
      LIMIT = 3

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: false, $limit: LIMIT})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!(data = res.body), 'got data')
          assert.equal(LIMIT, data.length, "Expected: #{LIMIT}, Actual: #{data.length}")
          done()

    it 'Cursor can chain limit and offset with paging', (done) ->
      LIMIT = 2; OFFSET = 1

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: true, $limit: LIMIT, $offset: OFFSET})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(OFFSET, data.offset, 'has the correct offset')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can select fields with paging', (done) ->
      FIELD_NAMES = ['id', 'name']

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: true, $select: FIELD_NAMES})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          for json in data.rows
            assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Cursor can select values with paging', (done) ->
      FIELD_NAMES = ['id', 'name']

      app = express(); app.use(express.bodyParser())
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: true, $values: FIELD_NAMES})
        .set('Accept', 'application/json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          assert.ok(_.isArray(data.rows), 'cursor values is an array')
          for json in data.rows
            assert.ok(_.isArray(json), 'cursor item values is an array')
            assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Ensure the correct value is returned', (done) ->
      Flat.find {$one: true}, (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!model, 'model')

        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$page: true, name: model.get('name')})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(!!data = res.body, 'got data')
            assert.equal(data.total_rows, 1, 'has the correct total_rows')
            assert.equal(data.rows.length, 1, 'has the correct row.length')
            assert.deepEqual(expected = JSON.stringify(model.toJSON()), actual = JSON.stringify(data.rows[0]), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false, false)
  runTests(options, true, false)
  # runTests(options, false, true) if options.embed # TODO
  # runTests(options, true, true) if options.embed # TODO
