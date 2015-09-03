{CompositeDisposable} = require 'atom'

git = require './git'

module.exports =
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'git-tabs:toggle': => @toggle()

    # subscribe to adding panels
    @subscriptions.add atom.workspace.onDidAddPaneItem ->
      console.log('handling new tab')
      branch = git.getBranch()
      console.log(branch)

  deactivate: ->
    @subscriptions.dispose()

  toggle: ->
    console.log('GitTabs was toggled!')
    console.log(git.hasGit())
    console.log(git.getMainRepo())
    console.log(git.getBranch())
