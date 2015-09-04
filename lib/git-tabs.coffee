{CompositeDisposable} = require 'atom'

git = require './git'

module.exports =
  subscriptions: null
  repoSubscriptions: null
  git: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'git-tabs:toggle': => @toggle()

    # Set up git stuff
    @git = git
    @git.create()

    # Set up git subscriptions
    @subscribeToRepositories()

    # subscribe to adding panels
    @subscriptions.add atom.workspace.onDidAddPaneItem ->
      console.log('handling new tab')

  deactivate: ->
    @subscriptions.dispose()
    @repoSubscriptions.dispose()
    @git.destroy()

  subscribeToRepositories: ->
    @git.onDidChangeBranch (data) =>
        @handleBranchChange(data)

  toggle: ->
    console.log 'GitTabs was toggled!'

  handleBranchChange: (data) ->
    data.branch.then((contents) ->
      console.log contents)
