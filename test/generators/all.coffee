# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  require('./backbone_rest')(options)
  require('./backbone_rest_sorted')(options)
  require('./page')(options)
