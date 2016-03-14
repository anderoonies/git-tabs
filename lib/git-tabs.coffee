{CompositeDisposable, Pane} = require 'atom'
fs = require 'fs-plus'
git = require './git'
Path = require 'path'

module.exports =
  subscriptions: null
  repoSubscriptions: null
  git: null
  projectName: null
  currentBranch: null

  activate: ->
    # if there is no git repository we can be of no help
    unless atom.project.getRepositories()[0]
      return

    git.create()
    @currentBranch = git.getCurrentBranch()
    @subscriptions = new CompositeDisposable
    @subscriptions.add git.onDidChangeBranch (data) =>
      @handleBranchChange(data)

    @subscriptions.add atom.commands.add 'atom-workspace',
      'git-tabs:nuke-local-storage': => @nukeLocalStorage()

  deactivate: ->
    # If this isn't true there's nothing to do
    unless project.getRepositories()[0]
      return

    # Store tabs before closing
    @storeState()

    # Remove all subscriptions
    @subscriptions.dispose()
    @repoSubscriptions.dispose()

    # Stop watching git files
    git.destroy()

  # Listens for a branch change
  subscribeToRepositories: ->
    git.onDidChangeBranch (data) =>
      @handleBranchChange(data)

  handleBranchChange: (data) ->
    @storeState()
    data.branch.then((head) =>
      shortHead = Path.basename(head)
      @currentBranch = shortHead
      if state = @getSavedState(shortHead)
        @updateWorkspace(state)
    )

  # Store state as JSON
  storeState: ->
    console.log 'storing state'
    state = []
    for pane, paneIndex in atom.workspace.getPanes()
      isPaneActive = pane.isFocused()
      paneState = []
      for item in pane.getItems?()
        serializedItem = item.serialize()
        paneState.push(serializedItem)
      state.push(paneState)

    global.localStorage.setItem(@localStorageKey(@currentBranch), JSON.stringify(state))

  # Deserialize state
  updateWorkspace: (state) ->
    for pane in atom.workspace.getPanes()
      pane.destroy()

    console.log 'update'
    for paneState, paneIndex in state
      pane = @getLastPane()
      if paneIndex > atom.workspace.getPanes().length
        pane = pane.splitRight()
      for item, itemIndex in paneState
        deserializedItem = atom.deserializers.deserialize(item)
        pane.addItem(deserializedItem, itemIndex)


    # atom.workspace.deserialize(state, atom.deserializers)

  getSavedState: (branch) ->
    return JSON.parse(global.localStorage.getItem(@localStorageKey(branch)))

  getLastPane: ->
    panes = atom.workspace.getPanes()
    return panes[panes.length - 1]

  # Get the name for the localStorage
  localStorageKey: (branch) ->
    "git-tabs:#{branch}"

  nukeLocalStorage: ->
    for key, val of global.localStorage
      if /git-tabs/.test(key)
        delete(global.localStorage[key])
