util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

MockCursor = require './cursor'

module.exports = class MockServerModel extends Backbone.Model
  @ACTIVE_MODELS_JSON = []

  @find: (query, callback) ->
    @queries = MockServerModel._parseQueries(query)
    json = _.find(MockServerModel.ACTIVE_MODELS_JSON, (test) => test.id is @queries.find.id)
    callback(null, if json then new MockServerModel(json) else null)

  @cursor: (query, callback) ->
    @queries = MockServerModel._parseQueries(query)
    callback(null, new MockCursor(MockServerModel.ACTIVE_MODELS_JSON, @queries.cursor))

  save: (attributes={}, options={}) ->
    @set(_.extend({id: _.uniqueId()}, attributes))
    MockServerModel.ACTIVE_MODELS_JSON.push(@toJSON())
    options.success?(@)

  destroy: (options={}) ->
    id = @get('id')
    for index, json of MockServerModel.ACTIVE_MODELS_JSON
      if json.id is id
        delete MockServerModel.ACTIVE_MODELS_JSON[index]
        return options.success?(@)
     options.error?(@)

  @_parseQueries: (query) ->
    unless _.isObject(query)
      single_item = true
      query = {id: query}

    queries = {find: {}, cursor: {}}
    for key, value of query
      if key[0] is '$'
        if key is '$select' or key is '$values'
          queries.cursor[key] = if _.isArray(value) then value else [value]
        else
          queries.cursor[key] = value
      else
        queries.find[key] = value
    return queries