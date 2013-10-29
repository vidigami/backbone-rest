###
  backbone-rest.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-rest
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
###

_ = require 'underscore'
Backbone = require 'backbone'
ORMUtils = require 'backbone-orm/lib/utils'
bbCallback = ORMUtils.bbCallback
JSONUtils = require 'backbone-orm/lib/json_utils'
JoinTableControllerSingleton = require './join_table_controller_singleton'

module.exports = class RESTController

  # TODO: add raw_json vs going through parse and toJSON on the models
  constructor: (app, options={}) ->
    @[key] = value for key, value of options
    @white_lists or= {}
    @templates or= {}
    @logger or= console

    @route = "#{@route_prefix}#{@route}" if @route_prefix

    app.get "#{@route}/:id", @_call(@show)
    app.get @route, @_call(@index)

    app.post @route, @_call(@create)
    app.put "#{@route}/:id", @_call(@update)

    app.del "#{@route}/:id", @_call(@destroy)
    app.del @route, @_call(@destroyByQuery)

    app.head "#{@route}/:id", @_call(@head)
    app.head @route, @_call(@headByQuery)

    JoinTableControllerSingleton.generateByOptions(app, options)

  sendError: (res, err) ->
    req = res.req
    @constructor.trigger('error', {req: req, res: res, err: err})
    @logger.error("Error 500 from #{req.method} #{req.url}: #{err}")
    res.header('content-type', 'text/plain').status(500).send(err.toString())

  index: (req, res) =>
    try
      event_data = {req: res, res: res}
      @constructor.trigger('pre:index', event_data)
      cursor = @model_type.cursor(JSONUtils.parse(req.query))
      cursor = cursor.whiteList(@white_lists.index) if @white_lists.index
      cursor.toJSON (err, json) =>
        return @sendError(res, err) if err

        @constructor.trigger('post:show', _.extend(event_data, {json: json}))

        return res.json({result: json}) if cursor.hasCursorQuery('$count') or cursor.hasCursorQuery('$exists')
        unless json
          if cursor.hasCursorQuery('$one')
            return res.status(404).send()
          else
            return res.json(json)

        if cursor.hasCursorQuery('$page')
          @render req, json.rows, (err, rendered_json) =>
            return @sendError(res, err) if err
            json.rows = rendered_json
            res.json(json)
        else
          @render req, json, (err, rendered_json) =>
            return @sendError(res, err) if err
            res.json(rendered_json)

    catch err
      @sendError(res, err)

  show: (req, res) =>
    try
      event_data = {req: res, res: res}
      @constructor.trigger('pre:show', event_data)

      cursor = @model_type.cursor(req.params.id)
      cursor = cursor.whiteList(@white_lists.show) if @white_lists.show
      cursor.toJSON (err, json) =>
        return @sendError(res, err) if err
        return res.status(404).send() unless json
        json = _.pick(json, @white_lists.show) if @white_lists.show

        @constructor.trigger('post:show', _.extend(event_data, {json: json}))
        @render req, json, (err, json) =>
          return @sendError(res, err) if err
          res.json(json)

    catch err
      @sendError(res, err)

  create: (req, res) =>
    try
      event_data = {req: res, res: res}
      @constructor.trigger('pre:create', event_data)

      json = JSONUtils.parse(if @white_lists.create then _.pick(req.body, @white_lists.create) else req.body)
      model = new @model_type(@model_type::parse(json))
      model.save {}, bbCallback (err) =>
        return @sendError(res, err) if err

        event_data.model = model
        json = if @white_lists.create then _.pick(model.toJSON(), @white_lists.create) else model.toJSON()
        @render req, json, (err, json) =>
          return @sendError(res, err) if err
          @constructor.trigger('post:create', _.extend(event_data, {json: json}))
          res.json(json)

    catch err
      @sendError(res, err)

  update: (req, res) =>
    try
      event_data = {req: res, res: res}
      @constructor.trigger('pre:update', event_data)

      json = JSONUtils.parse(if @white_lists.update then _.pick(req.body, @white_lists.update) else req.body)
      @model_type.find req.params.id, (err, model) =>
        return @sendError(res, err) if err
        return res.status(404).send() unless model
        model.save model.parse(json), bbCallback (err) =>
          return @sendError(res, err) if err

          event_data.model = model
          json = if @white_lists.update then _.pick(model.toJSON(), @white_lists.update) else model.toJSON()
          @render req, json, (err, json) =>
            return @sendError(res, err) if err
            @constructor.trigger('post:update', _.extend(event_data, {json: json}))
            res.json(json)

    catch err
      @sendError(res, err)

  destroy: (req, res) =>
    try
      event_data = {req: res, res: res}
      @constructor.trigger('pre:destroy', event_data)

      @model_type.exists req.params.id, (err, exists) =>
        return @sendError(res, err) if err
        return res.status(404).send() unless exists

        @model_type.destroy {id: req.params.id}, (err) =>
          return @sendError(res, err) if err
          @constructor.trigger('post:destroy', event_data)
          res.status(200).send()

    catch err
      @sendError(res, err)

  destroyByQuery: (req, res) =>
    try
      event_data = {req: res, res: res}
      @constructor.trigger('pre:destroyByQuery', event_data)
      @model_type.destroy JSONUtils.parse(req.query), (err) =>
        return @sendError(res, err) if err
        @constructor.trigger('post:destroyByQuery', event_data)
        res.send(200)
    catch err
      @sendError(res, err)

  head: (req, res) =>
    try
      event_data = {req: res, res: res}
      @constructor.trigger('pre:head', event_data)
      @model_type.exists req.params.id, (err, exists) =>
        return @sendError(res, err) if err
        @constructor.trigger('post:head', event_data)
        res.send(if exists then 200 else 404)
    catch err
      @sendError(res, err)

  headByQuery: (req, res) =>
    try
      @model_type.exists JSONUtils.parse(req.query), (err, exists) =>
        return @sendError(res, err) if err
        res.send(if exists then 200 else 404)
    catch err
      @sendError(res, err)

  render: (req, json, callback) ->
    template_name = req.query.$render or req.query.$template or @default_template
    return callback(null, json) unless template_name
    return callback(new Error "Unrecognized template: #{template_name}") unless template = @templates[template_name]

    options = (if @renderOptions then @renderOptions(req, template_name) else {})
    models = if _.isArray(json) then _.map(json, (model_json) => new @model_type(@model_type::parse(model_json))) else new @model_type(@model_type::parse(json))
    JSONUtils.renderTemplate models, template, options, callback

  setHeaders: (req, res, next) ->
    res.header('cache-control', 'no-cache')
    next()

  _call: (fn) =>
    auths = if _.isArray(@auth) then @auth.slice() else if @auth then [@auth] else []
    auths.push(@setHeaders)
    auths.push(fn)
    return auths

_.extend(RESTController, Backbone.Events)
