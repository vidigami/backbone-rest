test_parameters =
  database_url: '/test'
  schema:
    name: ['String', indexed: true]
    created_at: 'Date'
    updated_at: 'Date'
  sync: require('backbone-orm/memory_sync')
  embed: true

require('../generators/all')(test_parameters)
