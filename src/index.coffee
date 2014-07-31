###
  backbone-rest.js 0.5.3
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-rest
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
###

{_} = BackboneORM = require 'backbone-orm'

module.exports = BackboneREST = require './core' # avoid circular dependencies
publish =
  configure: require './lib/configure'
_.extend(BackboneREST, publish)

# re-expose modules
BackboneREST.modules = {'backbone-orm': BackboneORM}
