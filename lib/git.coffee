fs = require 'fs'
path = require 'path'
{Emitter, File} = require 'atom'

# Where git is interfaced
# This is done by watching git files
module.exports =
  emitter: null

  create: ->
    @emitter = new Emitter
    @watchBranches()

  destroy: ->
    @emitter.dispose()

  onDidChangeBranch: (callback) ->
    @emitter.on 'did-change-branch', callback

  watchBranches: ->
    gitPaths = @getRepositories()
    for gitPath in gitPaths
      gitFile = new File gitPath
      gitFile.onDidChange =>
        @emitter.emit 'did-change-branch', {branch: gitFile.read()}

  getRepositories: ->
      gitPaths = atom.project.getPaths()
      return (projectPath + '/.git/HEAD' for projectPath in gitPaths)
