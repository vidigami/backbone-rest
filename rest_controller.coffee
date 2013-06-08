_ = require 'underscore'

module.exports = class RESTController

  # TODO: add raw_json vs going through parse and toJSON on the models
  constructor: (app, options={}) ->
    @[key] = value for key, value of options
    @white_lists or= {}

    app.get "/#{@route}", @index
    app.get "/#{@route}/:id", @show
    app.post "/#{@route}", @create
    app.put "/#{@route}/:id", @update
    app.del "/#{@route}/:id", @destroy

  index: (req, res) =>
    try
      cursor = @model_type.cursor(req.query)
      cursor = cursor.whiteList(@white_lists.index) if @white_lists.index
      cursor.toJSON (err, json) ->
        if err then res.send(404) else res.json(json)
    catch err
      res.status(500).send(error: err.toString())

  show: (req, res) =>
    try
      cursor = @model_type.cursor(req.params.id)
      cursor = cursor.whiteList(@white_lists.show) if @white_lists.show
      cursor.toJSON (err, json) ->
        return res.status(404).send(error: err.toString()) if err
        return res.status(404).send("Model not found with id: #{req.params.id}") unless json.length
        res.json(json[0])
    catch err
      res.status(500).send(error: err.toString())

  create: (req, res) =>
    try
      model = new @model_type(@model_type::parse(req.body))
      model.save {}, {
        success: =>
          json = model.toJSON()
          json = _.pick(json, @white_lists.create) if @white_lists.create
          res.json(json)
        error: -> res.send(404)
      }
    catch err
      res.status(500).send(error: err.toString())

  update: (req, res) =>
    try
      @model_type.find req.params.id, (err, model) =>
        return res.status(404).send(error: err.toString()) if err
        return res.status(404).send("Model not found with id: #{req.params.id}") unless model
        model.save model.parse(req.body), {
          success: =>
            json = model.toJSON()
            json = _.pick(json, @white_lists.update) if @white_lists.update
            res.json(json)
          error: -> res.send(404)
        }
    catch err
      res.status(500).send(error: err.toString())

  destroy: (req, res) =>
    try
      @model_type.find req.params.id, (err, model) =>
        return res.status(404).send(error: err.toString()) if err
        return res.status(404).send("Model not found with id: #{req.params.id}") unless model
        model.destroy {
          success: -> res.send(200)
          error: -> res.send(404)
        }
    catch err
      res.status(500).send(error: err.toString())


# TODO: allow for external caller to set CORS
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
#   _enableCors: (app, url) =>
#     app.all url, (req, res, next) ->
#       res.set 'Access-Control-Allow-Origin', cors.origins if cors.origins
#       res.header 'Access-Control-Allow-Headers', 'X-Requested-With,Content-Disposition,Content-Type,Content-Description,Content-Range'
#       res.header 'Access-Control-Allow-Methods', 'HEAD, GET, POST, PUT, DELETE, OPTIONS'
#       res.header('Access-Control-Allow-Credentials', 'true')
#       next()
