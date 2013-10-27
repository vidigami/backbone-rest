Queue = require 'backbone-orm/lib/queue'

option_sets = require 'backbone-orm/test/option_sets'
option_sets = option_sets.slice(0, 5)

test_queue = new Queue(1)
for options in option_sets
  do (options) -> test_queue.defer (callback) ->
    console.log "\nBackbone REST: Running tests with options: ", options
    require('./unit/all_generators')(options, callback)
test_queue.await (err) -> console.log "Backbone REST: Completed tests"
