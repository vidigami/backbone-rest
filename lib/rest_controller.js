// Generated by CoffeeScript 1.9.2

/*
  backbone-rest.js 0.5.3
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-rest
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
 */

(function() {
  var Backbone, JSONUtils, JoinTableControllerSingleton, RESTController, Utils, _, path, ref,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  path = require('path');

  ref = require('backbone-orm'), _ = ref._, Backbone = ref.Backbone, Utils = ref.Utils, JSONUtils = ref.JSONUtils;

  JoinTableControllerSingleton = require('./lib/join_table_controller_singleton');

  module.exports = RESTController = (function(superClass) {
    extend(RESTController, superClass);

    RESTController.METHODS = ['show', 'index', 'create', 'update', 'destroy', 'destroyByQuery', 'head', 'headByQuery'];

    function RESTController(app, options) {
      var del;
      if (options == null) {
        options = {};
      }
      RESTController.__super__.constructor.call(this, app, _.defaults({
        headers: RESTController.headers
      }, options));
      this.whitelist || (this.whitelist = {});
      this.templates || (this.templates = {});
      if (this.route_prefix) {
        this.route = path.join(this.route_prefix, this.route);
      }
      app.get(this.route, this.wrap(this.index));
      app.get(this.route + "/:id", this.wrap(this.show));
      app.post(this.route, this.wrap(this.create));
      app.put(this.route + "/:id", this.wrap(this.update));
      del = app.hasOwnProperty('delete') ? 'delete' : 'del';
      app[del](this.route + "/:id", this.wrap(this.destroy));
      app[del](this.route, this.wrap(this.destroyByQuery));
      app.head(this.route + "/:id", this.wrap(this.head));
      app.head(this.route, this.wrap(this.headByQuery));
      JoinTableControllerSingleton.generateByOptions(app, options);
    }

    RESTController.prototype.requestId = function(req) {
      return JSONUtils.parseField(req.params.id, this.model_type, 'id');
    };

    RESTController.prototype.index = function(req, res) {
      var cursor, event_data;
      if (req.method === 'HEAD') {
        return this.headByQuery.apply(this, arguments);
      }
      event_data = {
        req: req,
        res: res
      };
      this.constructor.trigger('pre:index', event_data);
      cursor = this.model_type.cursor(JSONUtils.parseQuery(req.query));
      if (this.whitelist.index) {
        cursor = cursor.whiteList(this.whitelist.index);
      }
      return cursor.toJSON((function(_this) {
        return function(err, json) {
          if (err) {
            return _this.sendError(res, err);
          }
          _this.constructor.trigger('post:index', _.extend(event_data, {
            json: json
          }));
          if (cursor.hasCursorQuery('$count') || cursor.hasCursorQuery('$exists')) {
            return res.json({
              result: json
            });
          }
          if (!json) {
            if (cursor.hasCursorQuery('$one')) {
              return _this.sendStatus(res, 404);
            } else {
              return res.json(json);
            }
          }
          if (cursor.hasCursorQuery('$page')) {
            return _this.render(req, json.rows, function(err, rendered_json) {
              if (err) {
                return _this.sendError(res, err);
              }
              json.rows = rendered_json;
              return res.json(json);
            });
          } else if (cursor.hasCursorQuery('$values')) {
            return res.json(json);
          } else {
            return _this.render(req, json, function(err, rendered_json) {
              if (err) {
                return _this.sendError(res, err);
              }
              return res.json(rendered_json);
            });
          }
        };
      })(this));
    };

    RESTController.prototype.show = function(req, res) {
      var cursor, event_data;
      event_data = {
        req: req,
        res: res
      };
      this.constructor.trigger('pre:show', event_data);
      cursor = this.model_type.cursor(this.requestId(req));
      if (this.whitelist.show) {
        cursor = cursor.whiteList(this.whitelist.show);
      }
      return cursor.toJSON((function(_this) {
        return function(err, json) {
          if (err) {
            return _this.sendError(res, err);
          }
          if (!json) {
            return _this.sendStatus(res, 404);
          }
          if (_this.whitelist.show) {
            json = _.pick(json, _this.whitelist.show);
          }
          _this.constructor.trigger('post:show', _.extend(event_data, {
            json: json
          }));
          return _this.render(req, json, function(err, json) {
            if (err) {
              return _this.sendError(res, err);
            }
            return res.json(json);
          });
        };
      })(this));
    };

    RESTController.prototype.create = function(req, res) {
      var event_data, json, model;
      json = JSONUtils.parseDates(this.whitelist.create ? _.pick(req.body, this.whitelist.create) : req.body);
      model = new this.model_type(this.model_type.prototype.parse(json));
      event_data = {
        req: req,
        res: res,
        model: model
      };
      this.constructor.trigger('pre:create', event_data);
      return model.save((function(_this) {
        return function(err) {
          if (err) {
            return _this.sendError(res, err);
          }
          event_data.model = model;
          json = _this.whitelist.create ? _.pick(model.toJSON(), _this.whitelist.create) : model.toJSON();
          return _this.render(req, json, function(err, json) {
            if (err) {
              return _this.sendError(res, err);
            }
            _this.constructor.trigger('post:create', _.extend(event_data, {
              json: json
            }));
            return res.json(json);
          });
        };
      })(this));
    };

    RESTController.prototype.update = function(req, res) {
      var json;
      json = JSONUtils.parseDates(this.whitelist.update ? _.pick(req.body, this.whitelist.update) : req.body);
      return this.model_type.find(this.requestId(req), (function(_this) {
        return function(err, model) {
          var event_data;
          if (err) {
            return _this.sendError(res, err);
          }
          if (!model) {
            return _this.sendStatus(res, 404);
          }
          event_data = {
            req: req,
            res: res,
            model: model
          };
          _this.constructor.trigger('pre:update', event_data);
          return model.save(model.parse(json), function(err) {
            if (err) {
              return _this.sendError(res, err);
            }
            event_data.model = model;
            json = _this.whitelist.update ? _.pick(model.toJSON(), _this.whitelist.update) : model.toJSON();
            return _this.render(req, json, function(err, json) {
              if (err) {
                return _this.sendError(res, err);
              }
              _this.constructor.trigger('post:update', _.extend(event_data, {
                json: json
              }));
              return res.json(json);
            });
          });
        };
      })(this));
    };

    RESTController.prototype.destroy = function(req, res) {
      var event_data, id;
      event_data = {
        req: req,
        res: res
      };
      this.constructor.trigger('pre:destroy', event_data);
      return this.model_type.exists(id = this.requestId(req), (function(_this) {
        return function(err, exists) {
          if (err) {
            return _this.sendError(res, err);
          }
          if (!exists) {
            return _this.sendStatus(res, 404);
          }
          return _this.model_type.destroy(id, function(err) {
            if (err) {
              return _this.sendError(res, err);
            }
            _this.constructor.trigger('post:destroy', event_data);
            return res.json({});
          });
        };
      })(this));
    };

    RESTController.prototype.destroyByQuery = function(req, res) {
      var event_data;
      event_data = {
        req: req,
        res: res
      };
      this.constructor.trigger('pre:destroyByQuery', event_data);
      return this.model_type.destroy(JSONUtils.parseQuery(req.query), (function(_this) {
        return function(err) {
          if (err) {
            return _this.sendError(res, err);
          }
          _this.constructor.trigger('post:destroyByQuery', event_data);
          return res.json({});
        };
      })(this));
    };

    RESTController.prototype.head = function(req, res) {
      return this.model_type.exists(this.requestId(req), (function(_this) {
        return function(err, exists) {
          if (err) {
            return _this.sendError(res, err);
          }
          return _this.sendStatus(res, exists ? 200 : 404);
        };
      })(this));
    };

    RESTController.prototype.headByQuery = function(req, res) {
      return this.model_type.exists(JSONUtils.parseQuery(req.query), (function(_this) {
        return function(err, exists) {
          if (err) {
            return _this.sendError(res, err);
          }
          return _this.sendStatus(res, exists ? 200 : 404);
        };
      })(this));
    };

    RESTController.prototype.render = function(req, json, callback) {
      var models, options, template, template_name;
      template_name = req.query.$render || req.query.$template || this.default_template;
      if (!template_name) {
        return callback(null, json);
      }
      try {
        template_name = JSON.parse(template_name);
      } catch (_error) {}
      if (!(template = this.templates[template_name])) {
        return callback(new Error("Unrecognized template: " + template_name));
      }
      options = (this.renderOptions ? this.renderOptions(req, template_name) : {});
      models = _.isArray(json) ? _.map(json, (function(_this) {
        return function(model_json) {
          return new _this.model_type(_this.model_type.prototype.parse(model_json));
        };
      })(this)) : new this.model_type(this.model_type.prototype.parse(json));
      return JSONUtils.renderTemplate(models, template, options, callback);
    };

    return RESTController;

  })(require('./lib/json_controller'));

}).call(this);
