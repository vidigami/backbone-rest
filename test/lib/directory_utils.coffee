fs = require 'fs'
path = require 'path'
_ = require 'underscore'

EXCLUDED_FILES = ['.DS_Store']

removeDirectoryAndExtension = (file, directory) ->
  file = file.replace("#{directory}/", '')
  extension = path.extname(file)
  return file.replace(extension, '')

module.exports = class DirectoryUtils
  @files: (directory) ->
    results = []

    processDirectory = (directory) ->
      return if not fs.existsSync(directory)
      for file in fs.readdirSync(directory)
        continue if file in EXCLUDED_FILES

        stat = fs.statSync(pathed_file = path.join(directory, file))
        if stat.isDirectory() # a directory
          processDirectory(pathed_file)
        else # a file
          results.push(pathed_file)

    processDirectory(directory)
    return results

  @modules: (directory) ->
    results = {}
    for file in DirectoryUtils.files(directory)
      try results[removeDirectoryAndExtension(file, directory)] = require(file) catch err then console.log err.stack or err
    return results

  @functionModules: (directory) ->
    results = DirectoryUtils.modules(directory)
    delete results[file] for file, mod of results when not _.isFunction(mod)
    return results
