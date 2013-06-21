test_parameters =
  database_url: '/test'
  sync: require('backbone-orm/memory_backbone_sync')
  embed: true

require('../generators/all')(test_parameters)
