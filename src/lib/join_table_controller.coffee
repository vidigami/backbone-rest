{_, JSONUtils} = require 'backbone-orm'

RestController = require '../rest_controller'

module.exports = class JoinTableController extends RestController

  create: (req, res) ->
    try
      json = JSONUtils.parseDates(if @whitelist.create then _.pick(req.body, @whitelist.create) else req.body)

      @model_type.exists json, (err, exists) =>
        return @sendError(res, err) if err
        @sendStatus(res, 409, 'Entry already exists') if exists

        model = new @model_type(@model_type::parse(json))

        event_data = {req: res, res: res, model: model}
        @constructor.trigger('pre:create', event_data)

        model.save (err) =>
          return @sendError(res, err) if err

          event_data.model = model
          json = if @whitelist.create then _.pick(model.toJSON(), @whitelist.create) else model.toJSON()
          @render req, json, (err, json) =>
            return @sendError(res, err) if err
            @constructor.trigger('post:create', _.extend(event_data, {json: json}))
            res.json(json)

    catch err
      @sendError(res, err)
