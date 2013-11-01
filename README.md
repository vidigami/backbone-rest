[![Build Status](https://secure.travis-ci.org/vidigami/backbone-rest.png)](http://travis-ci.org/vidigami/backbone-rest)

![logo](https://github.com/vidigami/backbone-rest/raw/master/media/logo.png)

By using BackboneREST on the server and BackboneORM's JSON rendering DSL, you can save time in defining JSON APIs.

#### Examples (CoffeeScript)

```
Backbone = require 'backbone'
RestController = require 'backbone-rest'
ensureLoggedIn = require 'connect-ensure-login'

customAuthorization = (req, res, next) ->
  unless req.user.canAccessTask(req)
    return res.status(401).send('you cannot access this task')
  next()

new RestController(app, {
  auth: [ensureLoggedIn('/login'), customAuthorization]
  model_type: Task
  route: '/tasks'
})
```

#### Examples (JavaScript)

```
var Backbone = require('backbone');
var RestController = require('backbone-rest');
var ensureLoggedIn = require('connect-ensure-login');

var customAuthorization = function(req, res, next) {
  if (!req.user.canAccessTask(req)) {
    return res.status(401).send('you cannot access this task');
  }
  return next();
};

new RestController(app, {
  auth: [ensureLoggedIn('/login'), customAuthorization],
  model_type: Task,
  route: '/tasks'
});
```


Please [checkout the website](http://vidigami.github.io/backbone-orm/backbone-rest.html) for installation instructions, examples, documentation, and community!


### For Contributors

To build the library for Node.js:

  $ npm run build

Please run tests before submitting a pull request.

  $ npm test
