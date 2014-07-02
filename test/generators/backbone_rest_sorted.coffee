util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'

BackboneORM = require 'backbone-orm'
Queue = BackboneORM.Queue
JSONUtils = BackboneORM.JSONUtils
Utils = BackboneORM.Utils
Fabricator = BackboneORM.Fabricator
ModelCache = BackboneORM.CacheSingletons.ModelCache

request = require 'supertest'

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

  describe "RestController (sorted: true, cache: #{options.cache} embed: #{options.embed}, framework: #{options.app_factory_name})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure query cache

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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
        app = APP_FACTORY()
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
