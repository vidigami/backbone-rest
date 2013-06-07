util = require 'util'
_ = require 'underscore'

module.exports = class MockCursor
  constructor: (@json, options={}) ->
    @[key] = value for key, value of options

  whiteList: (keys) ->
    keys = [keys] unless _.isArray(keys)
    @$white_list = if @$white_list then _.intersection(@$white_list, keys) else keys
    return @

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
      $values = if @$white_list then _.intersection(@$values, @$white_list) else @$values
      json = (((item[key] for key in $values when item.hasOwnProperty(key))) for item in @json)
    else if @$select
      $select = if @$white_list then _.intersection(@$select, @$white_list) else @$select
      json = _.map(@json, (item) => _.pick(item, $select))
    else if @$white_list
      json = _.map(@json, (item) => _.pick(item, @$white_list))
    else
      json = @json
    callback(null, json)
    return @
