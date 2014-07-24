_ = require 'underscore'
es = require 'event-stream'

Async = require 'async'
gulp = require 'gulp'
gutil = require 'gulp-util'
coffee = require 'gulp-coffee'
install = require 'gulp-install'
mocha = require 'gulp-spawn-mocha'

gulp.task 'build', buildLibraries = ->
  return gulp.src('./src/**/*.coffee')
    .pipe(coffee({header: true})).on('error', gutil.log)
    .pipe(gulp.dest('./lib'))
  # return stream instead of explicit callback https://github.com/gulpjs/gulp/blob/master/docs/API.md

gulp.task 'watch', ['build'], (callback) ->
  return gulp.watch './src/**/*.coffee', -> buildLibraries()

mocha_framework_options =
  express4: {require: ['test/parameters_express4', 'backbone-orm/test/parameters'], env: {NODE_ENV: 'test'}}
  express3: {require: ['test/parameters_express3', 'backbone-orm/test/parameters'], env: {NODE_ENV: 'test'}}
  restify: {require: ['test/parameters_restify', 'backbone-orm/test/parameters'], env: {NODE_ENV: 'test'}}

testFn = (options={}) -> (callback) ->
  gutil.log "Running tests for #{options.framework}"
  gulp.src("test/spec/**/*.tests.coffee")
    .pipe(mocha(mocha_framework_options[options.framework]))
    .pipe es.writeArray callback
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test', ['build', 'install-express3-dependencies'], (callback) ->
  Async.series (testFn({framework: framework_name}) for framework_name of mocha_framework_options), callback
  return
gulp.task 'test-express4', ['build'], testFn({framework: 'express4'})
gulp.task 'install-express3-dependencies', [], ->
  return gulp.src('test/lib/express3/package.json').pipe(install())
gulp.task 'test-express3', ['build', 'install-express3-dependencies'], testFn({framework: 'express3'})
gulp.task 'test-restify', ['build'], testFn({framework: 'restify'})
gulp.task 'test-quick', ['test-express4']

# gulp.task 'benchmark', ['build'], (callback) ->
#   (require './test/lib/run_benchmarks')(callback)
#   return # promises workaround: https://github.com/gulpjs/gulp/issues/455
