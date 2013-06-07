  # # allow cross-origin
  # app.all route, (req, res, next) ->
  #   res.set('Access-Control-Allow-Origin', bind_options.origins)
  #   res.set('Access-Control-Allow-Headers', 'X-Requested-With,CONTENT-TYPE')
  #   res.set('Access-Control-Allow-Methods', 'GET,POST,PUT')
  #   next()
  # app.all "#{route}/:id", (req, res, next) ->
  #   res.set('Access-Control-Allow-Origin', bind_options.origins)
  #   res.set('Access-Control-Allow-Headers', 'X-Requested-With,CONTENT-TYPE')
  #   res.set('Access-Control-Allow-Methods', 'GET,PUT,DELETE')
  #   next()

# module.exports = class RESTController

#   parse_json: true
#   route: ''
#   cors:
#     enabled: true
#     origins: '*'

#   @model_type: null

#   constructor: (app) ->
#     @_enableCors(app, url) for url in [@route, "#{@route}/:id"] if @cors.enabled
#     @_bindDefaultRoutes(app)

#   index: (req, res) =>
#     query = req.params
#     logger.info("Get index, query: #{query}")
#     @model_type.find query, (err, photos) ->
#       return res.json({ error: err }) if err
#       res.json(photo.attributes for photo in photos)

#   show: (req, res) =>
#     id = req.params.id
#     logger.info("Get id: #{id}")
#     @model_type.findOne id, (err, photo) ->
#       return res.json({ error: err }) if err
#       return res.status(404).json() if not photo
#       res.json(photo.attributes)

#   create: (req, res) =>
#     @model_type.create new @model_type(req.params), (err, photo) ->
#       return res.json({ error: err }) if err
#       return res.status(404).json() if not photo
#       res.json(photo.attributes)

#   update: (req, res) =>
#     @model_type.update new @model_type(req.params), (err, photo) ->
#       return res.json({ error: err }) if err
#       return res.status(404).json() if not photo
#       res.json(photo.attributes)

#   delete: (req, res) =>
#     id = req.params.id
#     @model_type.delete new @model_type(req.params), (err, photo) ->
#       return res.json({ error: err }) if err
#       return res.status(404).json() if not photo
#       res.json(photo.attributes)

#   _enableCors: (app, url) =>
#     app.all url, (req, res, next) ->
#       res.set 'Access-Control-Allow-Origin', cors.origins if cors.origins
#       res.header 'Access-Control-Allow-Headers', 'X-Requested-With,Content-Disposition,Content-Type,Content-Description,Content-Range'
#       res.header 'Access-Control-Allow-Methods', 'HEAD, GET, POST, PUT, DELETE, OPTIONS'
#       res.header('Access-Control-Allow-Credentials', 'true')
#       next()

#   _bindDefaultRoutes: (app) =>
#     app.get "/#{@route}", @index
#     app.get "/#{@route}/:id", @show
#     app.post "/#{@route}", @create
#     app.put "/#{@route}/:id", @update
#     app.delete "/#{@route}/:id", @delete


# _ = require 'underscore'
# Query = require './query'

# HTTP_ERRORS =
#   INTERNAL_SERVER: 404

# bindRoute = (app, url, bind_options={}) ->
#   app.all url, (req, res, next) ->
#     res.set 'Access-Control-Allow-Origin', bind_options.origins if bind_options.origins
#     res.header 'Access-Control-Allow-Headers', 'X-Requested-With,Content-Disposition,Content-Type,Content-Description,Content-Range'
#     res.header 'Access-Control-Allow-Methods', 'HEAD, GET, POST, PUT, DELETE, OPTIONS'
#     res.header('Access-Control-Allow-Credentials', 'true')

#     # TODO: why did options return 404 when switched to express 3.1.0 from 3.0.0rc1
#     return res.send(200) if req.method.toLowerCase() is 'options'

#     next()

module.exports = class RESTController

  constructor: (app, options={}) ->
    @[key] = value for key, value of options
    @white_list or= {}

    app.get "/#{@route}", @index
    app.get "/#{@route}/:id", @show
    app.post "/#{@route}", @create
    app.put "/#{@route}/:id", @update
    app.del "/#{@route}/:id", @destroy

  # TODO: allow for external caller to set CORS
  # TODO: sanitize query - white list
  index: (req, res) =>
    try
      @model_type.cursor req.params, (err, cursor) =>
        return res.status(404).send(error: err.toString()) if err
        cursor = cursor.select(@white_list.index) if @white_list.index
        cursor.toJSON (err, json) ->
          if err then res.send(404) else res.json(json)
    catch err
      res.status(500).send(error: err.toString())

  show: (req, res) =>
    try
      @model_type.cursor req.params, (err, cursor) =>
        return res.status(404).send(error: err.toString()) if err
        cursor = cursor.select(@white_list.show) if @white_list.show
        cursor.toJSON (err, json) ->
          return res.status(404).send(error: err.toString()) if err
          return res.status(404).send("Model not found with id: #{req.params.id}") unless json.length
          res.json(json[0])
    catch err
      res.status(500).send(error: err.toString())

  create: (req, res) =>
    try
      model = new @model_type()
      model.set(model.parse(req.body))
      model.save {}, {
        success: =>
          json = model.toJSON()
          json = _.pick(json, @white_list.create) if @white_list.create
          res.json(json)
        error: -> res.send(404)
      }
    catch err
      res.status(500).send(error: err.toString())

  update: (req, res) =>
    try
      @model_type.find req.params, (err, model) =>
        return res.status(404).send(error: err.toString()) if err
        return res.status(404).send("Model not found with id: #{req.params.id}") unless model
        model.save model.parse(req.body), {
          success: =>
            json = model.toJSON()
            json = _.pick(json, @white_list.update) if @white_list.update
            res.json(json)
          error: -> res.send(404)
        }
    catch err
      res.status(500).send(error: err.toString())

  destroy: (req, res) =>
    try
      @model_type.find req.params, (err, model) =>
        return res.status(404).send(error: err.toString()) if err
        return res.status(404).send("Model not found with id: #{req.params.id}") unless model
        model.destroy {
          success: -> res.send(200)
          error: -> res.send(404)
        }
    catch err
      res.status(500).send(error: err.toString())