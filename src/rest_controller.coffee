###
  backbone-rest.js 0.5.3
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-rest
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
###

path = require 'path'
{_, Backbone, Utils, JSONUtils} = require 'backbone-orm'

JoinTableControllerSingleton = require './join_table_controller_singleton'

module.exports = class RESTController

  constructor: (app, options={}) ->
    _.extend(@, options)
    @white_lists or= {}; @templates or= {}
    @logger or= console

    @route = path.join(@route_prefix, @route) if @route_prefix

    app.get "#{@route}/:id", @_call(@show)
    app.get @route, @_call(@index)

    app.post @route, @_call(@create)
    app.put "#{@route}/:id", @_call(@update)

    del = if app.hasOwnProperty('delete') then 'delete' else 'del'
    app[del] "#{@route}/:id", @_call(@destroy)
    app[del] @route, @_call(@destroyByQuery)

    app.head "#{@route}/:id", @_call(@head)
    app.head @route, @_call(@headByQuery)

    JoinTableControllerSingleton.generateByOptions(app, options)

  requestId: (req) -> JSONUtils.parse({id: req.params.id}, @model_type).id
  requestValue: (req, key) -> return if _.isFunction(req[key]) then req[key]() else req[key]

  sendStatus: (res, status) -> res.status(status); res.json({})
  sendError: (res, err) ->
    req = res.req
    @constructor.trigger('error', {req: req, res: res, err: err})
    @logger.error("Error 500 from #{req.method} #{req.url}: #{err?.stack or err}")
    res.header('content-type', 'text/plain'); res.status(500); @sendStatus(res, err.toString())

  index: (req, res) =>
    return @headByQuery.apply(@, arguments) if req.method is 'HEAD' # Express4

    event_data = {req: req, res: res}
    @constructor.trigger('pre:index', event_data)

    cursor = @model_type.cursor(JSONUtils.parse(req.query, @model_type))
    cursor = cursor.whiteList(@white_lists.index) if @white_lists.index
    cursor.toJSON (err, json) =>
      return @sendError(res, err) if err

      @constructor.trigger('post:index', _.extend(event_data, {json: json}))

      return res.json({result: json}) if cursor.hasCursorQuery('$count') or cursor.hasCursorQuery('$exists')
      unless json
        if cursor.hasCursorQuery('$one')
          return @sendStatus(res, 404)
        else
          return res.json(json)

      if cursor.hasCursorQuery('$page')
        @render req, json.rows, (err, rendered_json) =>
          return @sendError(res, err) if err
          json.rows = rendered_json
          res.json(json)
      else if cursor.hasCursorQuery('$values')
        res.json(json)
      else
        @render req, json, (err, rendered_json) =>
          return @sendError(res, err) if err
          res.json(rendered_json)

  show: (req, res) =>
    event_data = {req: req, res: res}
    @constructor.trigger('pre:show', event_data)

    cursor = @model_type.cursor(@requestId(req))
    cursor = cursor.whiteList(@white_lists.show) if @white_lists.show
    cursor.toJSON (err, json) =>
      return @sendError(res, err) if err
      return @sendStatus(res, 404) unless json
      json = _.pick(json, @white_lists.show) if @white_lists.show

      @constructor.trigger('post:show', _.extend(event_data, {json: json}))
      @render req, json, (err, json) =>
        return @sendError(res, err) if err
        res.json(json)

  create: (req, res) =>
    json = JSONUtils.parse(if @white_lists.create then _.pick(req.body, @white_lists.create) else req.body)
    model = new @model_type(@model_type::parse(json))

    event_data = {req: req, res: res, model: model}
    @constructor.trigger('pre:create', event_data)

    model.save (err) =>
      return @sendError(res, err) if err

      event_data.model = model
      json = if @white_lists.create then _.pick(model.toJSON(), @white_lists.create) else model.toJSON()
      @render req, json, (err, json) =>
        return @sendError(res, err) if err
        @constructor.trigger('post:create', _.extend(event_data, {json: json}))
        res.json(json)

  update: (req, res) =>
    json = JSONUtils.parse(if @white_lists.update then _.pick(req.body, @white_lists.update) else req.body)

    @model_type.find @requestId(req), (err, model) =>
      return @sendError(res, err) if err
      return @sendStatus(res, 404) unless model

      event_data = {req: req, res: res, model: model}
      @constructor.trigger('pre:update', event_data)

      model.save model.parse(json), (err) =>
        return @sendError(res, err) if err

        event_data.model = model
        json = if @white_lists.update then _.pick(model.toJSON(), @white_lists.update) else model.toJSON()
        @render req, json, (err, json) =>
          return @sendError(res, err) if err
          @constructor.trigger('post:update', _.extend(event_data, {json: json}))
          res.json(json)

  destroy: (req, res) =>
    event_data = {req: req, res: res}
    @constructor.trigger('pre:destroy', event_data)

    @model_type.exists @requestId(req), (err, exists) =>
      return @sendError(res, err) if err
      return @sendStatus(res, 404) unless exists

      @model_type.destroy {id: @requestId(req)}, (err) =>
        return @sendError(res, err) if err
        @constructor.trigger('post:destroy', event_data)
        @sendStatus(res, 200)

  destroyByQuery: (req, res) =>
    event_data = {req: req, res: res}
    @constructor.trigger('pre:destroyByQuery', event_data)
    @model_type.destroy JSONUtils.parse(req.query, @model_type), (err) =>
      return @sendError(res, err) if err
      @constructor.trigger('post:destroyByQuery', event_data)
      @sendStatus(res, 200)

  head: (req, res) =>
    @model_type.exists @requestId(req), (err, exists) =>
      return @sendError(res, err) if err
      @sendStatus(res, if exists then 200 else 404)

  headByQuery: (req, res) =>
    @model_type.exists JSONUtils.parse(req.query, @model_type), (err, exists) =>
      return @sendError(res, err) if err
      @sendStatus(res, if exists then 200 else 404)

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

  _reqToCRUD: (req) ->
    req_path = @requestValue(req, 'path')
    if req_path is @route
      switch req.method
        when 'GET' then return 'index'
        when 'POST' then return 'create'
        when 'DELETE' then return 'destroyByQuery'
        when 'HEAD' then return 'headByQuery'
    else if @requestId(req) and req_path is "#{@route}/#{@requestId(req)}"
      switch req.method
        when 'GET' then  return 'show'
        when 'PUT' then return 'update'
        when 'DELETE' then return 'destroy'
        when 'HEAD' then return 'head'

  _call: (fn) =>
    auths = if _.isArray(@auth) then @auth.slice() else if @auth then [@auth] else []
    auths.push(@setHeaders)
    auths.push (req, res, next) =>
      (return @sendStatus(res, 405) if @_reqToCRUD(req) in @blocked) if @blocked
      try fn(req, res, next) catch err then @sendError(res, err)
    return auths

_.extend(RESTController, Backbone.Events)
