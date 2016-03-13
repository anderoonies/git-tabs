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
    state = {}
    for pane, paneIndex in atom.workspace.getPanes()
      isPaneActive = pane.isFocused()
      state[paneIndex] = {}
      for item, itemIndex in pane.getItems?()
        isTabActive = (item is pane.getActiveItem())
        state[paneIndex][itemIndex] = {
          'isPaneActive': isPaneActive,
          'isTabActive': isTabActive,
          '': paneIndex,
          'item': item.serialize()
        }

    global.localStorage.setItem(@localStorageKey(@currentBranch), JSON.stringify(state))

  # Deserialize state
  updateWorkspace: (state) ->
    console.log 'state!'
    console.log state
    # atom.workspace.deserialize(state, atom.deserializers)

  getSavedState: (branch) ->
    return JSON.parse(global.localStorage.getItem(@localStorageKey(branch)))

  # Get the name for the localStorage
  localStorageKey: (branch) ->
    "git-tabs:#{branch}"

  nukeLocalStorage: ->
    for key, val of global.localStorage
      if /git-tabs/.test(key)
        delete(global.localStorage[key])
