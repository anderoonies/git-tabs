# reproduction of the atom storage-folder

path = require "path"
fs = require "fs-plus"

module.exports =
class StorageFolder

  store: (name, object) ->
    @projectName = path.basename(atom.project.getPaths()?[0])
    branchedName = [@projectName, name].join('-')

    if object
      delete object["undefined"]
      stringifiedObject = JSON.stringify(object)
      if stringifiedObject == "{}"
        localStorage.removeItem(branchedName)
      else
        localStorage.setItem(branchedName, stringifiedObject)

  load: (name) ->
    @projectName = path.basename(atom.project.getPaths()?[0])
    branchedName = [@projectName, name].join('-')
    retrievedItem = null

    try
      retrievedItem = localStorage.getItem(branchedName)
    catch error
      unless error.code is 'ENOENT'
        console.warn "Local storage could not find an element for: #{branchedName}", error.stack, error
      return undefined

    try
      return JSON.parse(retrievedItem)
    catch error
      console.warn "Error parsing retrieved item: #{retrievedItem}", error.stack, error
