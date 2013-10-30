###
  backbone-rest.js 0.5.0
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-rest
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
###

path = require 'path'
_ = require 'underscore'
RestController = null

class JoinTableControllerSingleton
  constructor: ->
    @join_tables = {}

  reset: ->
    @join_tables = {}

  generateByOptions: (app, options) ->
    RestController = require './rest_controller' unless RestController # dependency cycle

    route_parts = options.route.split('/')
    route_parts.pop()
    route_root = route_parts.join('/')

    schema = options.model_type.schema()
    for key, relation of schema.relations
      continue unless (relation and relation.join_table)
      try
        join_table_url = _.result(relation.join_table.prototype, 'url')
        join_table_parts = join_table_url.split('/')
        join_table_endpoint = join_table_parts.pop()
      catch err
        console.log "JoinTableControllerSingleton.generateControllers: failed to parse url. Error: #{err}"
        continue

      join_table_options = _.clone(options)
      join_table_options.route = path.join(route_root, join_table_endpoint)
      continue if @join_tables[join_table_options.route] # already exists
      delete join_table_options[key] for key in ['white_lists', 'templates', 'default_template']
      join_table_options.model_type = relation.join_table
      # console.log "Generating join table controller at #{join_table_options.route}"
      @join_tables[join_table_options.route] = new RestController(app, join_table_options)

module.exports = new JoinTableControllerSingleton()
