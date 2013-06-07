_ = require 'underscore'
Backbone = require 'backbone-relational'

cross_origin = require './cross_origin'
HTTP_ERRORS =
  INTERNAL_SERVER: 500

module.exports = class RESTController

  @bind: (app, bind_options, collection_info) ->
    cross_origin.allowOrigin(app, [
      route
      "#{route}/:id"
    ], bind_options)

    route = collection_info.route
    collection = collection_info.collection

    app.get route, (req, res) ->
      json = collection.toJSON()
      bind_options.index?(req, collection.models, json) # customization hooks
      res.json(json)

    app.post route, (req, res) ->
      model = new collection.model()
      model.set(_.defaults(model.parse(req.body), {id: _.uniqueId()})) # assign an id
      collection.add(model)

      json = model.toJSON()
      bind_options.create?(req, model, json) # customization hooks
      res.json(json)

    app.get "#{route}/:id", (req, res) ->
      model = collection.get(req.params.id)
      return res.status(HTTP_ERRORS.INTERNAL_SERVER).send() unless model

      json = model.toJSON()
      bind_options.show?(req, model, json) # customization hooks
      res.json(json)

    app.put "#{route}/:id", (req, res) ->
      model = collection.get(req.params.id)
      return res.status(HTTP_ERRORS.INTERNAL_SERVER).send() unless model

      previous_json = model.toJSON()
      model.set(model.parse(req.body))
      json = model.toJSON()
      bind_options.update?(req, model, json, previous_json) # customization hooks
      res.json(json)

    app.del "#{route}/:id", (req, res) ->
      model = collection.get(req.params.id)
      return res.status(HTTP_ERRORS.INTERNAL_SERVER).send() unless model

      previous_json = model.toJSON()
      if model instanceof Backbone.RelationalModel
        Backbone.Relational.store.unregister(model)
      collection.remove(model)
      bind_options.delete?(req, model, previous_json) # customization hooks
      res.json({ok: true})