util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'backbone-orm/lib/queue'

Fabricator = require 'backbone-orm/test/fabricator'
JSONUtils = require 'backbone-orm/lib/json_utils'
Utils = require 'backbone-orm/lib/utils'

request = require 'supertest'

ModelCache = require('backbone-orm/lib/cache/singletons').ModelCache
QueryCache = require('backbone-orm/lib/cache/singletons').QueryCache

RestController = require '../../lib/rest_controller'

sortO = (array, field) -> _.sortBy(array, (obj) -> JSON.stringify(obj[field]))
sortA = (array) -> _.sortBy(array, (item) -> JSON.stringify(item))

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  APP_FACTORY = options.app_factory
  BASE_COUNT = 5
  MODELS_JSON = null
  ROUTE = '/test/flats'

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: _.defaults({
      boolean: 'Boolean'
    }, BASE_SCHEMA)
    sync: SYNC(Flat, options.cache)

  describe "RestController (page: true, cache: #{options.cache} embed: #{options.embed}, framework: #{options.app_factory_name})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure query cache
      queue.defer (callback) -> QueryCache.configure({enabled: !!options.query_cache, verbose: false}).reset(callback) # configure query cache

      queue.defer (callback) -> Utils.resetSchemas [Flat], callback

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, (err, models) ->
        return callback(err) if err
        Flat.find {id: {$in: _.map(models, (test) -> test.id)}}, (err, models) -> # reload models in case they are stored with different date precision
          return callback(err) if err
          MODELS_JSON = JSONUtils.parse(sortO(_.map(models, (test) -> test.toJSON()), 'name')) # need to sort because not sure what order will come back from database
          callback()
      )

      queue.await done

    it 'Cursor can chain limit with paging', (done) ->
      LIMIT = 3

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: true, $limit: LIMIT})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          assert.ok(data.rows, 'received models')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can chain limit with paging (no true or false)', (done) ->
      LIMIT = 3

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get("#{ROUTE}?$page&$limit=#{LIMIT}")
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          assert.ok(data.rows, 'received models')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can chain limit without paging', (done) ->
      LIMIT = 3

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: false, $limit: LIMIT})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!(data = res.body), 'got data')
          assert.equal(LIMIT, data.length, "Expected: #{LIMIT}, Actual: #{data.length}")
          done()

    it 'Cursor can chain limit and offset with paging', (done) ->
      LIMIT = 2; OFFSET = 1

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: true, $limit: LIMIT, $offset: OFFSET})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(OFFSET, data.offset, 'has the correct offset')
          assert.equal(LIMIT, data.rows.length, "Expected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can select fields with paging', (done) ->
      FIELD_NAMES = ['id', 'name']

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: true, $select: FIELD_NAMES})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          for json in data.rows
            assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Cursor can select values with paging', (done) ->
      FIELD_NAMES = ['id', 'name']

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE})

      request(app)
        .get(ROUTE)
        .query({$page: true, $values: FIELD_NAMES})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!data = res.body, 'got data')
          assert.ok(_.isArray(data.rows), 'cursor values is an array')
          for json in data.rows
            assert.ok(_.isArray(json), 'cursor item values is an array')
            assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Ensure the correct value is returned', (done) ->
      Flat.findOne (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!model, 'model')

        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$page: true, name: model.get('name')})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(!!data = res.body, 'got data')
            assert.equal(data.total_rows, 1, 'has the correct total_rows')
            assert.equal(data.rows.length, 1, 'has the correct row.length')
            assert.deepEqual(expected = model.toJSON(), actual = JSONUtils.parse(data.rows[0]), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()
