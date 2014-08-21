util = require 'util'
assert = require 'assert'

BackboneORM = require 'backbone-orm'
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

request = require 'supertest'

RestController = require '../../lib/rest_controller'

sortO = (array, field) -> _.sortBy(array, (obj) -> JSON.stringify(obj[field]))
sortA = (array) -> _.sortBy(array, (item) -> JSON.stringify(item))

_.each [BackboneORM.TestUtils.optionSets()[0]], exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  options.app_framework = __test__app_framework if __test__app_framework?
  return if options.embed and not options.sync.capabilities(options.database_url or '').embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  APP_FACTORY = options.app_framework.factory
  MODELS_JSON = null
  ROUTE = '/test/flats'

  describe "RestController (blocked: true, #{options.$tags}, framework: #{options.app_framework.name}) @auth", ->
    Flat = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: _.defaults({
          boolean: 'Boolean'
        }, BASE_SCHEMA)
        sync: SYNC(Flat, options.cache)

    after (callback) -> Utils.resetSchemas [Flat], callback

    beforeEach (callback) ->
      Utils.resetSchemas [Flat], (err) ->
        return callback(err) if err

        Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, (err, models) ->
          return callback(err) if err

          Flat.find {$ids: _.pluck(models, 'id')}, (err, models) -> # reload models in case they are stored with different date precision
            return callback(err) if err
            MODELS_JSON = JSONUtils.parseDates(sortO(_.map(models, (test) -> test.toJSON()), 'name')) # need to sort because not sure what order will come back from database
            callback()

    it 'Function auth (pass through)', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auth})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.body.length, BASE_COUNT, "Expected: #{BASE_COUNT}, Actual: #{res.body.length}")
          assert.equal(count, 1, "Correct counts. Expected: #{1}. Actual: #{count}")
          done()

    it 'Function auth (405)', (done) ->
      count = 0
      auth405 = (req, res, next) -> count++; res.status(405); res.json({})

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auth405})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.status, 405, "Expected: #{405}, Actual: #{res.status}")
          assert.equal(count, 1, "Correct counts. Expected: #{1}. Actual: #{count}")
          done()

    it 'Function auths (pass through)', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()
      auths = [auth, auth]

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auths})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.body.length, BASE_COUNT, "Expected: #{BASE_COUNT}, Actual: #{res.body.length}")
          assert.equal(count, 2, "Correct counts. Expected: #{2}. Actual: #{count}")
          done()

    it 'Object auths (pass through) - none', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()
      auths = {}

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auths})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.body.length, BASE_COUNT, "Expected: #{BASE_COUNT}, Actual: #{res.body.length}")
          assert.equal(count, 0, "Correct counts. Expected: #{0}. Actual: #{count}")
          done()

    it 'Object auths (pass through) - default', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()
      auths =
        default: auth

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auths})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.body.length, BASE_COUNT, "Expected: #{BASE_COUNT}, Actual: #{res.body.length}")
          assert.equal(count, 1, "Correct counts. Expected: #{1}. Actual: #{count}")
          done()

    it 'Object auths (pass through) - defaults', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()
      auths =
        default: [auth, auth]

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auths})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.body.length, BASE_COUNT, "Expected: #{BASE_COUNT}, Actual: #{res.body.length}")
          assert.equal(count, 2, "Correct counts. Expected: #{2}. Actual: #{count}")
          done()

    it 'Object auths (pass through) - index', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()
      auths =
        index: auth

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auths})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.body.length, BASE_COUNT, "Expected: #{BASE_COUNT}, Actual: #{res.body.length}")
          assert.equal(count, 1, "Correct counts. Expected: #{1}. Actual: #{count}")
          done()

    it 'Object auths (pass through) - indexs', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()
      auths =
        index: [auth, auth]

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auths})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.body.length, BASE_COUNT, "Expected: #{BASE_COUNT}, Actual: #{res.body.length}")
          assert.equal(count, 2, "Correct counts. Expected: #{2}. Actual: #{count}")
          done()

    it 'Object auths (405) - indexs', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()
      auth405 = (req, res, next) -> count++; res.status(405); res.json({})
      auths =
        index: [auth, auth405]

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auths})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.status, 405, "Expected: #{405}, Actual: #{res.status}")
          assert.equal(count, 2, "Correct counts. Expected: #{2}. Actual: #{count}")
          done()

    it 'Object auths (pass through) - show', (done) ->
      count = 0
      auth = (req, res, next) -> count++; next()
      auths =
        show: auth

      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, auth: auths})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(res.body.length, BASE_COUNT, "Expected: #{BASE_COUNT}, Actual: #{res.body.length}")
          assert.equal(count, 0, "Correct counts. Expected: #{0}. Actual: #{count}")
          done()
