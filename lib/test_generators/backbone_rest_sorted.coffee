# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  MODEL_TYPE = options.model_type
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null
  ROUTE = options.route

  util = require 'util'
  assert = require 'assert'
  request = require 'supertest'
  express = require 'express'
  _ = require 'underscore'

  RestController = require '../../rest_controller'

  sortO = (array, field) -> _.sortBy(array, (obj) -> JSON.stringify(obj[field]))
  sortA = (array) -> _.sortBy(array, (item) -> JSON.stringify(item))

  describe 'RestController with sort', ->
    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = sortO(models_json, 'name') # need to sort because not sure what order will come back from database
        done()

    ######################################
    # index
    ######################################

    describe 'index', ->
      it 'should return json for all models with no query', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = MODELS_JSON, actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name', $select: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, 'name')), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key respecting whitelist (key included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $select: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, 'name')), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by single key respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'created_at', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $select: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> []), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $select: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (keys included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $select: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'created_at', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'created_at',  $select: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortO(_.map(MODELS_JSON, (item) -> _.pick(item, ['created_at'])), 'created_at'), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (keys excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $select: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = _.map(MODELS_JSON, (item) -> {}), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $values: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key (in array)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $values: ['name']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key respecting whitelist (key included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $values: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> item['name'])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by single key respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'created_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $values: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> null)), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $values: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at'])))), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (keys included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $values: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at'])))), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $values: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name'])))), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (keys excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$sort: 'name',  $values: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(expected = sortA(_.map(MODELS_JSON, (item) -> [])), actual = res.body, "Expected: #{util.inspect(expected)}. Actual: #{util.inspect(actual)}")
            done()