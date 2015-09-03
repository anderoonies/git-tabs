{CompositeDisposable} = require 'atom'

git = require './git'

module.exports =
  subscriptions: null
  repoSubscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'git-tabs:toggle': => @toggle()
    # Set up git subscriptions
    @subscribeToRepositories()

    # subscribe to adding panels
    @subscriptions.add atom.workspace.onDidAddPaneItem ->
      console.log('handling new tab')
      branch = git.getBranch()
      console.log(branch)

  deactivate: ->
    @subscriptions.dispose()

  subscribeToRepositories: ->
    @repoSubscriptions?.dispose()
    @repoSubscriptions = new CompositeDisposable

    console.log 'called'
    for repo in git.getRepositories() when repo?
      console.log repo
      @repoSubscriptions.add repo.onDidChangeStatuses =>
        console.log 'i was called down here'
        @handleStatusChange()

  handleStatusChange: () ->
    console.log 'Status changed'
    console.log git.getBranch()

  toggle: ->
    console.log('GitTabs was toggled!')
