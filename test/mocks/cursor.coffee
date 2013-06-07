util = require 'util'
_ = require 'underscore'

module.exports = class MockCursor
  constructor: (@json, options={}) ->
    @[key] = value for key, value of options

  select: (keys) ->
    keys = [keys] unless _.isArray(keys)
    @$select = if @$select then _.intersection(@$select, keys) else keys
    return @

  values: (keys) ->
    keys = [keys] unless _.isArray(keys)
    @$values = if @$values then _.intersection(@$values, keys) else keys
    return @

  toJSON: (callback) ->
    if @$values
      json = []
      for item in @json
        result = []
        result.push(item[key]) for key in @$values when item.hasOwnProperty(key)
        json.push(result)
    else if @$select
      json = _.map(@json, (item) => _.pick(item, @$select))
    else
      json = @json
    callback(null, json)
