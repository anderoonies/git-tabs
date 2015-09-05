fs = require 'fs-plus'
path = require 'path'
{Emitter, File, Directory} = require 'atom'

# Where git is interfaced
# This is done by watching git files
module.exports =
  emitter: null
  gitFiles: null

  create: ->
    @emitter = new Emitter
    @gitFiles = []

    @getGitFiles()
    @watchBranches()

  destroy: ->
    @emitter.dispose()

  onDidChangeBranch: (callback) ->
    @emitter.on 'did-change-branch', callback

  getGitFiles: ->
    gitPaths = @getRepositories()
    for gitPath in gitPaths
      gitFile = new File gitPath
      @gitFiles.push(gitFile)

  watchBranches: ->
    for gitFile in @gitFiles
      console.log 'wathcing them branches'
      gitFile.onDidChange =>
        @emitter.emit 'did-change-branch', {branch: gitFile.read()}

  getRepositories: ->
    gitPaths = atom.project.getPaths()
    return (projectPath + '/.git/HEAD' for projectPath in gitPaths)

  getRepoForFile: (filePath) ->
    return atom.project
               .repositoryForDirectory(new Directory(path.dirname(filePath)))
