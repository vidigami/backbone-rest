###
  backbone-rest.js 0.5.3
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-rest
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
###

path = require 'path'
{_} = require 'backbone-orm'

JoinTableController = null

class JoinTableControllerSingleton
  constructor: ->
    @join_tables = {}

  reset: ->
    @join_tables = {}

  generateByOptions: (app, options) ->
    JoinTableController = require './join_table_controller' unless JoinTableController # dependency cycle

    route_parts = options.route.split('/')
    route_parts.pop()
    route_root = route_parts.join('/')

    schema = options.model_type.schema()
    for key, relation of schema.relations
      continue unless (relation and relation.join_table)
      try
        join_table_url = _.result(new relation.join_table, 'url')
        join_table_parts = join_table_url.split('/')
        join_table_endpoint = join_table_parts.pop()
      catch err
        console.log "JoinTableControllerSingleton.generateControllers: failed to parse url. Error: #{err}"
        continue

      join_table_options = _.clone(options)
      join_table_options.route = path.join(route_root, join_table_endpoint)
      join_table_options.route = "/#{join_table_options.route}" unless join_table_options.route[0] is '/'
      continue if @join_tables[join_table_options.route] # already exists
      delete join_table_options[_key] for _key in ['whitelists', 'templates', 'default_template']
      join_table_options.model_type = relation.join_table
      join_table_options.auth = join_table_auth if join_table_auth = options.auth?.relations?[key]
      # console.log "Generating join table controller at #{join_table_options.route}"
      @join_tables[join_table_options.route] = new JoinTableController(app, join_table_options)

module.exports = new JoinTableControllerSingleton()
