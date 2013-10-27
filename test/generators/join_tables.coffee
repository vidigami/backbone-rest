util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'backbone-orm/lib/queue'

Fabricator = require 'backbone-orm/test/fabricator'
Utils = require 'backbone-orm/lib/utils'
JSONUtils = require 'backbone-orm/lib/json_utils'

request = require 'supertest'
express = require 'express'

ModelCache = require('backbone-orm/lib/cache/singletons').ModelCache
QueryCache = require('backbone-orm/lib/cache/singletons').QueryCache

RestController = require '../../src/rest_controller'

sortO = (array, field) -> _.sortBy(array, (obj) -> JSON.stringify(obj[field]))
sortA = (array) -> _.sortBy(array, (item) -> JSON.stringify(item))

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  MODELS_JSON = null
  OWNER_ROUTE = '/test/owners'
  JOIN_TABLE_ROUTE = '/test/owners_reverses'

  ModelCache.configure(if options.cache then {max: 100} else null).hardReset() # configure model cache

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    @schema: _.defaults({
      owners: -> ['hasMany', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    @schema: _.defaults({
      reverses: -> ['hasMany', Reverse]
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  mockApp = ->
    app = express(); app.use(express.bodyParser())
    new RestController(app, {model_type: Owner, route: OWNER_ROUTE}) # this should auto-generated the join table controller and route
    return app

  describe "Many to Many (cache: #{options.cache} embed: #{options.embed})", ->

    before (done) -> return done() unless options.before; options.before([Reverse, Owner], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../lib/join_table_controller_singleton').reset() # reset join tables
      MODELS = {}

      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure query cache
      queue.defer (callback) -> QueryCache.configure({enabled: !!options.query_cache, verbose: false}).reset(callback) # configure query cache

      # destroy all
      queue.defer (callback) -> Utils.resetSchemas [Reverse, Owner], callback

      # create all
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create(Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverses_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owners_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err))

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        MODELS_JSON = []

        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.set({reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]})
            MODELS_JSON.push({owner_id: owner.id, reverse_id: reverse.id}) for reverse in owner.get('reverses').models # save relations
            owner.save {}, Utils.bbCallback callback

        save_queue.await callback

      queue.await done

    it 'Handles a get query for a hasMany and hasMany two sided relation', (done) ->
      app = mockApp()
      request(app)
        .get(OWNER_ROUTE)
        .query({$one: true})
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
          owner_id = JSONUtils.parse(res.body).id
          assert.ok(!!owner_id, "found owner")

          request(app)
            .get(JOIN_TABLE_ROUTE)
            .query({owner_id: owner_id})
            .type('json')
            .end (err, res) ->
              assert.ok(!err, "no errors: #{err}")
              assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
              expected = sortO(_.select(MODELS_JSON, (test) -> test.owner_id is owner_id), 'reverse_id')
              actual = sortO(_.map(JSONUtils.parse(res.body), (item) -> _.pick(item, 'owner_id', 'reverse_id')), 'reverse_id')
              assert.deepEqual(expected, actual, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")

              reverse_id = actual[0].reverse_id
              request(app)
                .get(JOIN_TABLE_ROUTE)
                .query({reverse_id: reverse_id})
                .type('json')
                .end (err, res) ->
                  assert.ok(!err, "no errors: #{err}")
                  assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
                  expected = sortO(_.select(MODELS_JSON, (test) -> test.reverse_id is reverse_id), 'owner_id')
                  actual = sortO(_.map(JSONUtils.parse(res.body), (item) -> _.pick(item, 'owner_id', 'reverse_id')), 'owner_id')
                  assert.deepEqual(expected, actual, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
                  done()

    # it 'Can include related (two-way hasMany) models', (done) ->
    #   app = mockApp()
    #   request(app)
    #     .get(OWNER_ROUTE)
    #     .query({$one: true, $include: 'reverses'})
    #     .type('json')
    #     .end (err, res) ->
    #       assert.ok(!err, "no errors: #{err}")
    #       assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
    #       owner_id = JSONUtils.parse(res.body).id
    #       assert.ok(!!owner_id, "found owner")

    #   Owner.cursor({$one: true}).include('reverses').toJSON (err, test_model) ->
    #     assert.ok(!err, "No errors: #{err}")
    #     assert.ok(test_model, 'found model')
    #     assert.ok(test_model.reverses, 'Has related reverses')
    #     assert.equal(test_model.reverses.length, 2, "Has the correct number of related reverses \nExpected: #{2}\nActual: #{test_model.reverses.length}")
    #     done()

    # it 'Can query on related (two-way hasMany) models', (done) ->
    #   Reverse.findOne (err, reverse) ->
    #     assert.ok(!err, "No errors: #{err}")
    #     assert.ok(reverse, 'found model')
    #     Owner.cursor({'reverses.name': reverse.get('name')}).toJSON (err, json) ->
    #       test_model = json[0]
    #       assert.ok(!err, "No errors: #{err}")
    #       assert.ok(test_model, 'found model')
    #       assert.equal(json.length, 1, "Found the correct number of owners \nExpected: #{1}\nActual: #{json.length}")
    #       done()

    # it 'Can query on related (two-way hasMany) models with included relations', (done) ->
    #   Reverse.findOne (err, reverse) ->
    #     assert.ok(!err, "No errors: #{err}")
    #     assert.ok(reverse, 'found model')
    #     Owner.cursor({'reverses.name': reverse.get('name')}).include('reverses').toJSON (err, json) ->
    #       test_model = json[0]
    #       assert.ok(!err, "No errors: #{err}")
    #       assert.ok(test_model, 'found model')
    #       assert.ok(test_model.reverses, 'Has related reverses')
    #       assert.equal(test_model.reverses.length, 2, "Has the correct number of related reverses \nExpected: #{2}\nActual: #{test_model.reverses.length}")
    #       done()

    # it 'Clears its reverse relations on delete when the reverse relation is loaded', (done) ->
    #   Owner.cursor({$one: true, $include: 'reverses'}).toModels (err, owner) ->
    #     assert.ok(!err, "No errors: #{err}")
    #     assert.ok(owner, 'found model')
    #     owner.get 'reverses', (err, reverses) ->
    #       assert.ok(!err, "No errors: #{err}")
    #       assert.ok(reverses, 'found model')

    #       owner.destroy Utils.bbCallback (err, owner) ->
    #         assert.ok(!err, "No errors: #{err}")

    #         Owner.relation('reverses').join_table.find {owner_id: owner.id}, (err, null_reverses) ->
    #           assert.ok(!err, "No errors: #{err}")
    #           assert.equal(null_reverses.length, 0, 'No reverses found for this owner after save')
    #           done()

    # it 'Clears its reverse relations on delete when the reverse relation isnt loaded (one-way hasMany)', (done) ->
    #   Owner.cursor({$one: true}).toModels (err, owner) ->
    #     assert.ok(!err, "No errors: #{err}")
    #     assert.ok(owner, 'found model')
    #     owner.get 'reverses', (err, reverses) ->
    #       assert.ok(!err, "No errors: #{err}")
    #       assert.ok(reverses, 'found model')

    #       owner.destroy Utils.bbCallback (err, owner) ->
    #         assert.ok(!err, "No errors: #{err}")

    #         Owner.relation('reverses').join_table.find {owner_id: owner.id}, (err, null_reverses) ->
    #           assert.ok(!err, "No errors: #{err}")
    #           assert.equal(null_reverses.length, 0, 'No reverses found for this owner after save')
    #           done()

    # it 'Can query on a ManyToMany relation by related id', (done) ->
    #   Owner.findOne (err, owner) ->
    #     assert.ok(!err, "No errors: #{err}")
    #     assert.ok(owner, 'found model')
    #     Reverse.cursor({owner_id: owner.id}).toModels (err, reverses) ->
    #       assert.ok(!err, "No errors: #{err}")
    #       assert.ok(reverses, 'found models')
    #       assert.equal(reverses.length, 2, "Found the correct number of reverses\n expected: #{2}, actual: #{reverses.length}")
    #       done()
