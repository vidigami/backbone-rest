###
  backbone-rest.js 0.5.3
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-rest
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
###

_ = require 'underscore'

module.exports = class JSONController
  constructor: (app, options={}) ->
    @configure(options)
    @headers or= {'Cache-Control': 'no-cache', 'Content-Type': 'application/json'}

  configure: (options={}) -> _.extend(@, options)
  sendStatus: (res, status, message) -> res.status(status); if message then res.json({message}) else res.json({})
  sendError: (res, err) ->
    req = res.req
    @constructor.trigger('error', {req: req, res: res, err: err})
    @logger.error("Error 500 from #{req.method} #{req.url}: #{err?.stack or err}")
    res.status(500); res.json({error: err.toString()})

  wrap: (fn) =>
    auths = []
    if _.isArray(@auth) then auths = @auth.slice(0) # copy so middleware can attach to an instance
    else if _.isFunction(@auth) then auths.push(@auth)
    else if _.isObject(@auth) then auths.push(@_dynamicAuth)
    auths.push(@_setHeaders)
    auths.push (req, res, next) =>
      (return @sendStatus(res, 405) if @_reqToCRUD(req) in @blocked) if @blocked
      try fn.wrap(@, req, res, next) catch err then @sendError(res, err)
    return auths
  _wrap: @::wrap # TODO: add deprecation warning

  ################################
  # Private
  ################################
  _setHeaders: (req, res, next) =>
    res.setHeader(key, value) for key, value of @headers
    next()

  _reqToCRUD: (req) =>
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

  _dynamicAuth: (req, res, next) =>
    if @auth.hasOwnProperty(crud = @_reqToCRUD(req)) then auth = @auth[crud]
    else auth = @auth.default
    return next() unless auth
    return auth(req, res, next) unless _.isArray(auth)

    index = -1
    exec = -> if (++index >= auth.length) then next() else auth[index](req, res, exec)
    exec()
