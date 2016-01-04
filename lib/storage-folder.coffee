# reproduction of the atom storage-folder

path = require "path"
fs = require "fs-plus"

module.exports =
class StorageFolder
  constructor: (containingPath) ->
    @path = path.join(containingPath, "storage")

  store: (name, object) ->
    fs.writeFileSync(@pathForKey(name + '.json'), JSON.stringify(object), 'utf8')

  load: (name) ->
    statePath = @pathForKey(name + '.json')
    try
      stateString = fs.readFileSync(statePath, 'utf8')
    catch error
      unless error.code is 'ENOENT'
        console.warn "Error reading state file: #{statePath}", error.stack, error
      return undefined

    try
      JSON.parse(stateString)
    catch error
      console.warn "Error parsing state file: #{statePath}", error.stack, error

  exists: (name) ->
    return fs.exists(@pathForKey(name + '.json'))

  pathForKey: (name) -> path.join(@getPath(), name)
  getPath: -> @path
