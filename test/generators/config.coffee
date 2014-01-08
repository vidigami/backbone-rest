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

  describe "RestController (blocked: true, cache: #{options.cache} embed: #{options.embed}, framework: #{options.app_factory_name})", ->

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
