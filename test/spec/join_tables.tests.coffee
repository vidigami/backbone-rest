util = require 'util'
assert = require 'assert'

BackboneORM = require 'backbone-orm'
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

request = require 'supertest'

RestController = require '../../lib/index'

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
  OWNER_ROUTE = '/test/owners'
  JOIN_TABLE_ROUTE = '/test/owners_reverses'

  describe "Many to Many (#{options.$tags}, framework: #{options.app_framework.name})", ->
    Reverse = Owner = mockApp = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Reverse extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/reverses"
        schema: _.defaults({
          owners: -> ['hasMany', Owner]
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class Owner extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/owners"
        schema: _.defaults({
          reverses: -> ['hasMany', Reverse]
        }, BASE_SCHEMA)
        sync: SYNC(Owner)

      mockApp = ->
        app = APP_FACTORY()
        new RestController(app, {model_type: Owner, route: OWNER_ROUTE}) # this should auto-generated the join table controller and route
        return app

    after (callback) -> Utils.resetSchemas [Reverse, Owner], callback

    beforeEach (callback) ->
      require('../../lib/lib/join_table_controller_singleton').reset() # reset join tables
      MODELS = {}

      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [Reverse, Owner], callback
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverses_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owners_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err)

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        MODELS_JSON = []

        save_queue = new Queue(1)

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            reverses = [MODELS.reverse.pop(), MODELS.reverse.pop()]
            # console.log "linking #{owner.id} to #{reverses[0]?.id}, #{reverses[1]?.id}"
            owner.set({reverses})
            MODELS_JSON.push({owner_id: owner.id, reverse_id: reverse.id}) for reverse in owner.get('reverses').models # save relations
            owner.save callback

        save_queue.await callback

      queue.await callback

    it 'Handles a get query for a hasMany and hasMany two sided relation', (done) ->
      app = mockApp()
      request(app)
        .get(OWNER_ROUTE)
        .query(JSONUtils.querify({$one: true}))
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{JSONUtils.stringify(res.body)}")
          owner_id = JSONUtils.parse(res.body).id
          assert.ok(!!owner_id, 'found owner')

          request(app)
            .get(JOIN_TABLE_ROUTE)
            .query(JSONUtils.querify({owner_id: owner_id}))
            .type('json')
            .end (err, res) ->
              assert.ok(!err, "no errors: #{err}")
              assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{JSONUtils.stringify(res.body)}")
              expected = sortO(_.select(MODELS_JSON, (test) -> test.owner_id is owner_id), 'reverse_id')
              actual = sortO(_.map(JSONUtils.parse(res.body), (item) -> _.pick(item, 'owner_id', 'reverse_id')), 'reverse_id')
              assert.deepEqual(expected, actual, "Expected: #{JSONUtils.stringify(expected)}. Actual: #{JSONUtils.stringify(actual)}")

              reverse_id = actual[0].reverse_id
              request(app)
                .get(JOIN_TABLE_ROUTE)
                .query(JSONUtils.querify({reverse_id: reverse_id}))
                .type('json')
                .end (err, res) ->
                  assert.ok(!err, "no errors: #{err}")
                  assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{JSONUtils.stringify(res.body)}")
                  expected = sortO(_.select(MODELS_JSON, (test) -> test.reverse_id is reverse_id), 'owner_id')
                  actual = sortO(_.map(JSONUtils.parse(res.body), (item) -> _.pick(item, 'owner_id', 'reverse_id')), 'owner_id')
                  assert.deepEqual(expected, actual, "Expected: #{JSONUtils.stringify(expected)}. Actual: #{JSONUtils.stringify(actual)}")
                  done()

    # TODO: re-enable
    it.skip 'Responds with a 409 when creating the same model twice', (done) ->
      app = mockApp()

      send_post = (callback) ->
        request(app)
          .post(JOIN_TABLE_ROUTE)
          .send({owner_id: 1, reverse_id: 1})
          .type('json')
          .end callback

      send_post (err, res) ->
        assert.ok(!err, "no errors: #{err}")
        assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{JSONUtils.stringify(res.body)}")
        owner_id = JSONUtils.parse(res.body).owner_id
        assert.ok(!!owner_id, "found owner_id")

        send_post (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 409, "status not 409. Status: #{res.status}. Body: #{JSONUtils.stringify(res.body)}")
          done()

    it.skip 'Can include related (two-way hasMany) models', (done) ->
      app = mockApp()
      request(app)
        .get(OWNER_ROUTE)
        .query(JSONUtils.querify({$one: true, $include: 'reverses'}))
        .type('json')
        .end (err, res) ->
          assert.ok(!err, "no errors: #{err}")
          assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{JSONUtils.stringify(res.body)}")
          owner_id = JSONUtils.parse(res.body).id
          assert.ok(!!owner_id, 'found owner')

      Owner.cursor({$one: true}).include('reverses').toJSON (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        assert.ok(test_model.reverses, 'Has related reverses')
        assert.equal(test_model.reverses.length, 2, "Has the correct number of related reverses \nExpected: #{2}\nActual: #{test_model.reverses.length}")
        done()

    it.skip 'Can query on related (two-way hasMany) models', (done) ->
      Reverse.findOne (err, reverse) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(reverse, 'found model')
        Owner.cursor({'reverses.name': reverse.get('name')}).toJSON (err, json) ->
          test_model = json[0]
          assert.ok(!err, "No errors: #{err}")
          assert.ok(test_model, 'found model')
          assert.equal(json.length, 1, "Found the correct number of owners \nExpected: #{1}\nActual: #{json.length}")
          done()

    it.skip 'Can query on related (two-way hasMany) models with included relations', (done) ->
      Reverse.findOne (err, reverse) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(reverse, 'found model')
        Owner.cursor({'reverses.name': reverse.get('name')}).include('reverses').toJSON (err, json) ->
          test_model = json[0]
          assert.ok(!err, "No errors: #{err}")
          assert.ok(test_model, 'found model')
          assert.ok(test_model.reverses, 'Has related reverses')
          assert.equal(test_model.reverses.length, 2, "Has the correct number of related reverses \nExpected: #{2}\nActual: #{test_model.reverses.length}")
          done()

    it.skip 'Clears its reverse relations on delete when the reverse relation is loaded', (done) ->
      Owner.cursor({$one: true, $include: 'reverses'}).toModels (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found model')

          owner.destroy (err, owner) ->
            assert.ok(!err, "No errors: #{err}")

            Owner.relation('reverses').join_table.find {owner_id: owner.id}, (err, null_reverses) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(null_reverses.length, 0, 'No reverses found for this owner after save')
              done()

    it.skip 'Clears its reverse relations on delete when the reverse relation isnt loaded (one-way hasMany)', (done) ->
      Owner.cursor({$one: true}).toModels (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found model')

          owner.destroy (err, owner) ->
            assert.ok(!err, "No errors: #{err}")

            Owner.relation('reverses').join_table.find {owner_id: owner.id}, (err, null_reverses) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(null_reverses.length, 0, 'No reverses found for this owner after save')
              done()

    it.skip 'Can query on a ManyToMany relation by related id', (done) ->
      Owner.findOne (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        Reverse.cursor({owner_id: owner.id}).toModels (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found models')
          assert.equal(reverses.length, 2, "Found the correct number of reverses\n expected: #{2}, actual: #{reverses.length}")
          done()
