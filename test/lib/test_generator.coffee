module.exports = (options) ->

  # each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
  # beforeEach should return the models_json for the current run

  MODEL_TYPE = options.model_type
  ROUTE = options.route
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null

  util = require 'util'
  assert = require 'assert'
  request = require 'supertest'
  express = require 'express'
  _ = require 'underscore'

  RestController = require '../../rest_controller'

  describe 'RestController', ->
    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
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
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(MODELS_JSON, res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested keys by single key', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$select: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.pick(item, 'name')), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested keys by single key respecting whitelist (key included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$select: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.pick(item, 'name')), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested keys by single key respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'created_at', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$select: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> []), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested keys by an array of keys', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$select: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (keys included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$select: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.pick(item, ['name', 'created_at'])), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'created_at', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$select: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.pick(item, ['created_at'])), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested keys by an array of keys respecting whitelist (keys excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$select: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> {}), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested values by single key', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$values: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, 'name'))), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested values by single key respecting whitelist (key included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$values: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, 'name'))), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested values by single key respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'created_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$values: 'name'})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> []), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested values by an array of keys', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}")
          .query({$values: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at']))), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (keys included)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name', 'created_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$values: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name', 'created_at']))), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (key excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'name']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$values: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> _.values(_.pick(item, ['name']))), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should select requested values by an array of keys respecting whitelist (keys excluded)', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {index: ['id', 'updated_at']}})

        request(app)
          .get("/#{ROUTE}")
          .query({$values: ['name', 'created_at']})
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.map(MODELS_JSON, (item) -> []), res.body, "models json returned. Body: #{util.inspect(res.body)}")
            done()

    ######################################
    # show
    ######################################

    describe 'show', ->
      it 'should find an existing model', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        request(app)
          .get("/#{ROUTE}/#{MODELS_JSON[0].id}")
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(MODELS_JSON[0], res.body, "model json returned. Body: #{util.inspect(res.body)}")
            done()

      it 'should find an existing model with whitelist', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {show: ['id', 'name', 'created_at']}})

        attributes = _.clone(MODELS_JSON[0])
        request(app)
          .get("/#{ROUTE}/#{attributes.id}")
          .set('Accept', 'application/json')
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.pick(attributes, ['id', 'name', 'created_at']), res.body, "model json returned. Body: #{util.inspect(res.body)}")
            done()

    ######################################
    # create
    ######################################

    describe 'create', ->
      it 'should create a new model and assign an id', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        attributes = {name: _.uniqueId('name_'), created_at: (new Date).toISOString(), updated_at: Math.floor(Math.random()*10)}
        request(app)
          .post("/#{ROUTE}")
          .send(attributes)
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(!!res.body.id, 'assigned an id')
            assert.equal(attributes.name, res.body.name, 'name matches')
            done()

      it 'should create a new model and assign an id with whitelist', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {create: ['id', 'name', 'updated_at']}})

        attributes = {name: _.uniqueId('name_'), created_at: (new Date).toISOString(), updated_at: Math.floor(Math.random()*10)}
        request(app)
          .post("/#{ROUTE}")
          .send(attributes)
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.ok(!!res.body.id, 'assigned an id')
            assert.equal(attributes.name, res.body.name, 'name matches')
            assert.equal(attributes.updated_at, res.body.updated_at, 'updated_at matches')
            assert.ok(!res.body.created_at, 'created_at was not returned')
            done()

    ######################################
    # update
    ######################################

    describe 'update', ->
      it 'should update an existing model', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        attributes = _.clone(MODELS_JSON[1])
        attributes.name = "#{attributes.name}_#{_.uniqueId('name')}"
        request(app)
          .put("/#{ROUTE}/#{attributes.id}")
          .send(attributes)
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.omit(attributes, '_rev'), _.omit(res.body, '_rev'), 'model was updated') # there could be _rev added
            done()

      it 'should update an existing model with whitelist', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE, white_lists: {update: ['id', 'name', 'updated_at']}})

        attributes = _.clone(MODELS_JSON[1])
        attributes.name = "#{attributes.name}_#{_.uniqueId('name')}"
        request(app)
          .put("/#{ROUTE}/#{attributes.id}")
          .send(attributes)
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            assert.deepEqual(_.pick(attributes, ['id', 'name', 'updated_at']), res.body, 'model was updated')
            done()

    ######################################
    # delete
    ######################################

    describe 'delete', ->
      it 'should delete an existing model', (done) ->
        app = express(); app.use(express.bodyParser())
        controller = new RestController(app, {model_type: MODEL_TYPE, route: ROUTE})

        id = MODELS_JSON[1].id
        request(app)
          .del("/#{ROUTE}/#{id}")
          .end (err, res) ->
            assert.ok(!err, "no errors: #{err}")
            assert.equal(res.status, 200, "status not 200. Status: #{res.status}. Body: #{util.inspect(res.body)}")
            done()
