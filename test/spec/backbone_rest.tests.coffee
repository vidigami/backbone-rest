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

  describe "RestController (sorted: false, #{options.$tags}, framework: #{options.app_framework.name})", ->
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

    ######################################
    # index
    ######################################

    describe 'index', ->

      it 'should return json for all models with no query', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = MODELS_JSON, actual = sortO(JSONUtils.parse(res.body), 'name'), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$select: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, 'name')), actual = sortO(res.body, 'name'), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key respecting whitelist (key included)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at']}})

        request(app)
          .get(ROUTE)
          .query({$select: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, 'name')), actual = sortO(res.body, 'name'), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key respecting whitelist (key excluded)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'created_at', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$select: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> []), actual = sortO(res.body, 'name'), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$select: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), actual = sortO(JSONUtils.parse(res.body), 'name'), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (keys included)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$select: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), actual = sortO(JSONUtils.parse(res.body), 'name'), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (key excluded)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'created_at', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$select: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortO(_.map(MODELS_JSON, (item) -> _.pick(item, ['created_at'])), 'created_at'), actual = sortO(JSONUtils.parse(res.body), 'created_at'), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (keys excluded)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$select: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> {}), actual = sortO(res.body, 'name'), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$values: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = sortA(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key (when a template is present)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, templates: {show: {$select: ['name']}}, default_template: 'show'})

        request(app)
        .get(ROUTE)
        .query({$values: 'name'})
        .type('json')
        .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = sortA(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key (in array)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$values: ['name']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = sortA(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key respecting whitelist (key included)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name']}})

        request(app)
          .get(ROUTE)
          .query({$values: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = sortA(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key respecting whitelist (key excluded)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'created_at']}})

        request(app)
          .get(ROUTE)
          .query({$values: 'name'})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> null)), actual = sortA(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get(ROUTE)
          .query({$values: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at'])))), actual = sortA(JSONUtils.parse(res.body)), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (keys included)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at']}})

        request(app)
          .get(ROUTE)
          .query({$values: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at'])))), actual = sortA(JSONUtils.parse(res.body)), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (key excluded)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'name']}})

        request(app)
          .get(ROUTE)
          .query({$values: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name'])))), actual = sortA(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (keys excluded)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {index: ['id', 'updated_at']}})

        request(app)
          .get(ROUTE)
          .query({$values: ['name', 'created_at']})
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> [])), actual = sortA(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should trigger pre:index and post:index events on index', (done) ->
        app = APP_FACTORY()

        class EventController extends RestController
          constructor: ->
            super(app, {model_type: Flat, route: ROUTE})
        controller = new EventController()

        pre_triggered = false
        post_triggered = false
        EventController.on 'pre:index', (req) -> pre_triggered = true if req
        EventController.on 'post:index', (json) -> post_triggered = true if json

        request(app)
        .get(ROUTE)
        .type('json')
        .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(pre_triggered, "Pre event trigger: #{pre_triggered}")
            assert.ok(pre_triggered, "Post event trigger: #{post_triggered}")
            done()

    ######################################
    # show
    ######################################

    describe 'show', ->
      it 'should find an existing model', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        request(app)
          .get("#{ROUTE}/#{MODELS_JSON[0].id}")
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = MODELS_JSON[0], actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should find an existing model with whitelist', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {show: ['id', 'name', 'created_at']}})

        attributes = _.clone(MODELS_JSON[0])
        request(app)
          .get("#{ROUTE}/#{attributes.id}")
          .type('json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.pick(attributes, ['id', 'name', 'created_at']), actual = JSONUtils.parse(res.body), "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should trigger pre:show and post:show events on show', (done) ->
        app = APP_FACTORY()

        class EventController extends RestController
          constructor: ->
            super(app, {model_type: Flat, route: ROUTE})
        controller = new EventController()

        pre_triggered = false
        post_triggered = false
        EventController.on 'pre:show', (req) -> pre_triggered = true if req
        EventController.on 'post:show', (json) -> post_triggered = true if json

        request(app)
        .get("#{ROUTE}/#{MODELS_JSON[0].id}")
        .type('json')
        .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(pre_triggered, "Pre event trigger: #{pre_triggered}")
            assert.ok(pre_triggered, "Post event trigger: #{post_triggered}")
            done()

    ######################################
    # create
    ######################################

    describe 'create', ->
      it 'should create a new model and assign an id', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        attributes = {name: _.uniqueId('name_'), created_at: (new Date).toISOString(), updated_at: (new Date).toISOString()}
        request(app)
          .post(ROUTE)
          .send(attributes)
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(!!res.body.id, 'assigned an id')
            assert.equal(attributes.name, res.body.name, 'name matches')
            done()

      it 'should create a new model and assign an id with whitelist', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {create: ['id', 'name', 'updated_at']}})

        attributes = {name: _.uniqueId('name_'), created_at: (new Date).toISOString(), updated_at: (new Date).toISOString()}
        request(app)
          .post(ROUTE)
          .send(attributes)
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(!!res.body.id, 'assigned an id')
            assert.equal(attributes.name, res.body.name, 'name matches')
            assert.equal(attributes.updated_at, res.body.updated_at, 'updated_at matches')
            assert.ok(!res.body.created_at, 'created_at was not returned')
            done()

      it 'should trigger pre:create and post:create events on create', (done) ->
        app = APP_FACTORY()

        class EventController extends RestController
          constructor: ->
            super(app, {model_type: Flat, route: ROUTE})
        controller = new EventController()

        pre_triggered = false
        post_triggered = false
        EventController.on 'pre:create', (req) -> pre_triggered = true if req
        EventController.on 'post:create', (json) -> post_triggered = true if json

        attributes = {name: _.uniqueId('name_'), created_at: (new Date).toISOString(), updated_at: (new Date).toISOString()}
        request(app)
        .post(ROUTE)
        .send(attributes)
        .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(pre_triggered, "Pre event trigger: #{pre_triggered}")
            assert.ok(pre_triggered, "Post event trigger: #{post_triggered}")
            done()

    ######################################
    # update
    ######################################

    describe 'update', ->
      it 'should update an existing model', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        attributes = _.clone(MODELS_JSON[1])
        attributes.name = "#{attributes.name}_#{_.uniqueId('name')}"
        request(app)
          .put("#{ROUTE}/#{attributes.id}")
          .send(attributes)
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.omit(attributes, '_rev'), _.omit(JSONUtils.parse(res.body), '_rev'), 'model was updated') # there could be _rev added
            done()

      it 'should update an existing model with whitelist', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE, white_lists: {update: ['id', 'name', 'updated_at']}})

        attributes = _.clone(MODELS_JSON[1])
        attributes.name = "#{attributes.name}_#{_.uniqueId('name')}"
        request(app)
          .put("#{ROUTE}/#{attributes.id}")
          .send(attributes)
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.pick(attributes, ['id', 'name', 'updated_at']), JSONUtils.parse(res.body), 'model was updated')
            done()

      it 'should trigger pre:update and post:create events on update', (done) ->
        app = APP_FACTORY()

        class EventController extends RestController
          constructor: ->
            super(app, {model_type: Flat, route: ROUTE})
        controller = new EventController()

        pre_triggered = false
        post_triggered = false
        EventController.on 'pre:update', (req) -> pre_triggered = true if req
        EventController.on 'post:update', (json) -> post_triggered = true if json

        attributes = _.clone(MODELS_JSON[1])
        attributes.name = "#{attributes.name}_#{_.uniqueId('name')}"
        request(app)
        .put("#{ROUTE}/#{attributes.id}")
        .send(attributes)
        .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(pre_triggered, "Pre event trigger: #{pre_triggered}")
            assert.ok(pre_triggered, "Post event trigger: #{post_triggered}")
            done()

    ######################################
    # delete
    ######################################

    describe 'delete', ->
      it 'should delete an existing model', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        id = MODELS_JSON[1].id
        request(app)
          .del("#{ROUTE}/#{id}")
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")

            request(app)
              .get("#{ROUTE}/#{id}")
              .end (err, res) ->
                assert.ok(!err, "no errors: #{err}")
                assert.equal(res.status, 404, "status 404 on subsequent request. Status: #{res.status}. Body: #{util.inspect(res.body)}")
                done()

      it 'should trigger pre:destroy and post:destroy events on destroy', (done) ->
        app = APP_FACTORY()

        class EventController extends RestController
          constructor: ->
            super(app, {model_type: Flat, route: ROUTE})
        controller = new EventController()

        pre_triggered = false
        post_triggered = false
        EventController.on 'pre:destroy', (req) -> pre_triggered = true if req
        EventController.on 'post:destroy', (json) -> post_triggered = true if json

        id = MODELS_JSON[1].id
        request(app)
        .del("#{ROUTE}/#{id}")
        .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(pre_triggered, "Pre event trigger: #{pre_triggered}")
            assert.ok(pre_triggered, "Post event trigger: #{post_triggered}")
            done()

    ######################################
    # head
    ######################################

    describe 'head', ->
      it 'should test existence of a model by id', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        id = MODELS_JSON[1].id
        request(app)
          .head("#{ROUTE}/#{id}")
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")

            # delete it
            request(app)
              .del("#{ROUTE}/#{id}")
              .end (err, res) ->
                assert.ok(!err, "no errors: #{err}")
                assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")

                # check again
                request(app)
                  .head("#{ROUTE}/#{id}")
                  .end (err, res) ->
                    assert.ok(!err, "no errors: #{err}")
                    assert.equal(res.status, 404, "status not 404. Status: #{res.status}. Body: #{util.inspect(res.body)}")
                    done()

      it 'should test existence of a model by id ($exists)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        id = MODELS_JSON[1].id
        request(app)
          .get("#{ROUTE}")
          .query({id: id, $exists: ''})
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(res.body.result, "Exists by id. Body: #{util.inspect(res.body)}")

            # delete it
            request(app)
              .del("#{ROUTE}/#{id}")
              .end (err, res) ->
                assert.ok(!err, "no errors: #{err}")
                assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")

                # check again
                request(app)
                  .get("#{ROUTE}")
                  .query({id: id, $exists: ''})
                  .end (err, res) ->
                    assert.ok(!err, "no errors: #{err}")
                    assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
                    assert.ok(!res.body.result, "Not longer exists by id. Body: #{util.inspect(res.body)}")
                    done()

      it 'should test existence of a model by name', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        id = MODELS_JSON[1].id
        name = MODELS_JSON[1].name
        request(app)
          .head("#{ROUTE}")
          .query({name: name})
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")

            # delete it
            request(app)
              .del("#{ROUTE}/#{id}")
              .end (err, res) ->
                assert.ok(!err, "no errors: #{err}")
                assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")

                # check again
                request(app)
                  .head("#{ROUTE}")
                  .query({name: name})
                  .end (err, res) ->
                    assert.ok(!err, "no errors: #{err}")
                    assert.equal(res.status, 404, "status not 404. Status: #{res.status}. Body: #{util.inspect(res.body)}")
                    done()

      it 'should test existence of a model by name ($exists)', (done) ->
        app = APP_FACTORY()
        controller = new RestController(app, {model_type: Flat, route: ROUTE})

        id = MODELS_JSON[1].id
        name = MODELS_JSON[1].name
        request(app)
          .get("#{ROUTE}")
          .query({name: name, $exists: ''})
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(res.body.result, "Exists by name. Body: #{util.inspect(res.body)}")

            # delete it
            request(app)
              .del("#{ROUTE}/#{id}")
              .end (err, res) ->
                assert.ok(!err, "no errors: #{err}")
                assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")

                # check again
                request(app)
                  .get("#{ROUTE}")
                  .query({name: name, $exists: ''})
                  .end (err, res) ->
                    assert.ok(!err, "no errors: #{err}")
                    assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
                    assert.ok(!res.body.result, "No longer exists by name. Body: #{util.inspect(res.body)}")
                    done()
