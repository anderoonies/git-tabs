{CompositeDisposable, TextEditor} = require 'atom'
fs = require 'fs-plus'
git = require './git'
Path = require 'path'

# StorageFolder = require './storage-folder'

module.exports =
  subscriptions: null
  repoSubscriptions: null
  git: null
  projectName: null
  activeBranch: null

  activate: ->
    # if there is no git repository we can be of no help
    unless atom.project.getRepositories()[0]
      return

    @subscriptions = new CompositeDisposable
    @projectName = Path.basename(atom.project.getPaths()?[0])

    git.create()
    @activeBranch = git.getCurrentBranch()

    @subscriptions.add git.onDidChangeBranch (data) =>
      @handleBranchChange(data)

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
    @clearWorkspace()
    data.branch.then((head) =>
      @activeBranch = Path.basename(head.trim())
      if state = @getSavedState(@activeBranch)
        @loadState(state)
    )

  handleRemovedTab: (item) ->
    @uncacheTab(item)

  clearWorkspace: ->
    for pane in atom.workspace.getPaneItems()
      atom.workspace.destroy(pane)

  # Store state as JSON
  storeState: ->
    state = atom.workspace.project.serialize()
    global.localStorage.setItem(@localStorageKey(@activeBranch), JSON.stringify(state))

  # Load state from JSON
  loadState: (state) ->
    console.log 'loading state'
    console.log state
    for path, item of tabs
      deserializedTab = atom.deserializers.deserialize(item.tab)
      console.log 'deserialzed!'
      console.log deserializedTab
      @activePane.addItem(deserializedTab)
      if item.active
        @activePane.setActiveItem(deserializedTab)

  getSavedState: (branch) ->
    return JSON.parse(global.localStorage.getItem(@localStorageKey(branch)))

  # Get the name for the localStorage
  localStorageKey: (branch) ->
    "git-tabs:#{branch}"

  getItemPath: (item) ->
    return item.buffer?.file?.path
