util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require 'backbone-orm/test/fabricator'
JSONUtils = require 'backbone-orm/lib/json_utils'
Utils = require 'backbone-orm/lib/utils'

request = require 'supertest'
express = require 'express'

ModelCache = require('backbone-orm/lib/cache/singletons').ModelCache
QueryCache = require('backbone-orm/lib/cache/singletons').QueryCache

RestController = require '../../rest_controller'

sortO = (array, field) -> _.sortBy(array, (obj) -> JSON.stringify(obj[field]))
sortA = (array) -> _.sortBy(array, (item) -> JSON.stringify(item))

runTests = (options, cache, embed, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  MODELS_JSON = null
  ROUTE = '/test/flats'

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: _.defaults({
      boolean: 'Boolean'
    }, BASE_SCHEMA)
    sync: SYNC(Flat, cache)

  describe "RestController (sorted: true, cache: #{cache} embed: #{embed})", ->

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

    ######################################
    # index
    ######################################

    describe 'index', ->
      it 'should return json for all models with no query', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = MODELS_JSON, actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name', $select: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, 'name')), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key respecting whitelist (key included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $select: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, 'name')), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'created_at', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $select: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> []), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $select: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (keys included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $select: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'created_at', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'created_at',  $select: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortO(_.map(MODELS_JSON, (item) -> _.pick(item, ['created_at'])), 'created_at'), actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (keys excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $select: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> {}), actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $values: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key (in array)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $values: ['name']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key respecting whitelist (key included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $values: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'created_at']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $values: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> null)), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $values: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at'])))), actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (keys included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $values: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at'])))), actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $values: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name'])))), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (keys excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$sort: 'name',  $values: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> [])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> runTests(options, false, false, callback)
  queue.defer (callback) -> runTests(options, true, false, callback)
  not options.embed or queue.defer (callback) -> runTests(options, false, true, callback)
  not options.embed or queue.defer (callback) -> runTests(options, true, true, callback)
  queue.await callback
