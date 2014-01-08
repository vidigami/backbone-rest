express = require 'express'

module.exports = -> app = express(); app.use(express.bodyParser()); app
