[![Build Status](https://secure.travis-ci.org/vidigami/backbone-rest.png)](http://travis-ci.org/vidigami/backbone-rest)

![logo](https://github.com/vidigami/backbone-rest/raw/master/media/logo.png)

By using BackboneREST on the server and BackboneORM's JSON rendering DSL, you can save time in defining JSON APIs.

#### Examples (CoffeeScript)

```
Backbone = require 'backbone'
RestController = require 'backbone-rest'

class Task extends Backbone.Model
  urlRoot: 'mongodb://localhost:27017/tasks'
  sync: require('backbone-mongo').sync(Task)

new RestController(app, {model_type: Task, route: '/tasks'})
```

#### Examples (JavaScript)

```
var Backbone = require('backbone');
var RestController = require('backbone-rest');

var Task = Backbone.Model.extend({
  urlRoot: 'mongodb://localhost:27017/tasks'
});
Task.prototype.sync = require('backbone-mongo').sync(Task);

new RestController(app, {model_type: Task, route: '/tasks'});
```


Please [checkout the website](http://vidigami.github.io/backbone-orm/backbone-rest.html) for installation instructions, examples, documentation, and community!


### For Contributors

To build the library for Node.js:

  $ npm run build

Please run tests before submitting a pull request.

  $ npm test
