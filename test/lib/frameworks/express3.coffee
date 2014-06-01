express = require '../../../vendor/express'

module.exports = ->
  app = express()
  app.use(express.bodyParser())
  return app
