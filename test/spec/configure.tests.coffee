util = require 'util'
assert = require 'assert'

BackboneORM = require 'backbone-orm'
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

request = require 'supertest'

RestController = require '../../lib/rest_controller'

sortO = (array, field) -> _.sortBy(array, (obj) -> JSON.stringify(obj[field]))
sortA = (array) -> _.sortBy(array, (item) -> JSON.stringify(item))

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
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

  describe "RestController (blocked: true, #{options.$tags}, framework: #{options.app_framework.name})", ->
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
            MODELS_JSON = JSONUtils.parse(sortO(_.map(models, (test) -> test.toJSON()), 'name')) # need to sort because not sure what order will come back from database
            callback()

    it 'Blocking routes: index', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['index']})

      request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")
          done()

    it 'Blocking routes: show', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['show']})

      request(app)
        .get("#{ROUTE}/1")
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")
          done()

    it 'Blocking routes: create', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['create']})

      request(app)
        .post(ROUTE)
        .send({stuff: 100})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")
          done()

    it 'Blocking routes: update', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['update']})

      request(app)
        .put("#{ROUTE}/1")
        .send({stuff: 100})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")
          done()

    it 'Blocking routes: destroy', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['destroy']})

      request(app)
        .del("#{ROUTE}/1")
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")
          done()

    it 'Blocking routes: destroyByQuery', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['destroyByQuery']})

      request(app)
        .del(ROUTE)
        .send({stuff: 100})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")
          done()

    it 'Blocking routes: head', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['head']})

      request(app)
        .head("#{ROUTE}/1")
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")
          done()

    it 'Blocking routes: headByQuery', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['headByQuery']})

      request(app)
        .head(ROUTE)
        .send({stuff: 100})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")
          done()

    it 'configure headers', (done) ->
      app = APP_FACTORY()
      controller = new RestController(app, {model_type: Flat, route: ROUTE, blocked: ['headByQuery']})
      RestController.configure({headers: {ETag: '1234'}})

      request(app)
        .head(ROUTE)
        .send({stuff: 100})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(405, res.status, "Expected: #{405}, Actual: #{res.status}")

          assert.equal res.headers.etag, '1234', 'ETag header was returned'

          assert.equal RestController.headers.ETag, '1234', 'ETag header was set'
          delete RestController.headers.ETag
          assert.ok _.isUndefined(RestController.headers.ETag), 'ETag header was removed'

          done()
