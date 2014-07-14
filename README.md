[![Build Status](https://secure.travis-ci.org/vidigami/backbone-rest.png)](http://travis-ci.org/vidigami/backbone-rest)

![logo](https://github.com/vidigami/backbone-rest/raw/master/media/logo.png)

By using BackboneREST on the server and BackboneORM's JSON rendering DSL, you can save time in defining JSON APIs.

Supported frameworks:

* [Express](http://expressjs.com/)
* [restify](http://mcavage.me/node-restify)


#### Examples (CoffeeScript)

```coffeescript
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

```javascript
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

```
$ npm run
```

Please run tests before submitting a pull request.

```
$ npm test
```

# Test Options

To run specific groups of tests, [use mocha `--grep` option on tags stated in the test descriptions](https://github.com/visionmedia/mocha/wiki/Tagging); for example:

```
mocha --grep @cache test/**/*.tests.coffee
```

To tests on a single application framework backend, use `mocha --require` on the desired framework loader.

```
mocha --require test/lib/frameworks/express3 test/**/*.tests.coffee
```
