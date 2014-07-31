{_} = BackboneORM = require 'backbone-orm'
BackboneREST = require '../core'

# set up defaults
BackboneREST.headers = {'Cache-Control': 'no-cache', 'Content-Type': 'application/json'}

module.exports = (options) ->
  _.extend(BackboneREST.headers, options.headers) if options.headers
  BackboneORM.configure(_.omit(options, 'headers'))
