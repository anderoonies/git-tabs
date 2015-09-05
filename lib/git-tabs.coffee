{CompositeDisposable, TextEditor} = require 'atom'
StorageFolder = require './storage-folder'
git = require './git'

module.exports =
  subscriptions: null
  repoSubscriptions: null
  git: null
  activeSpace: null

  activate: ->
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'git-tabs:toggle': => @toggle()

    # Set up git stuff
    @git = git
    @git.create()

    # Set up storageFolder
    @storageFolder = new StorageFolder @getStorageDir()
    if not @storageFolder.load('tabs.json')
      @storageFolder.store('tabs.json', {})

    @storeTabs()

    # Set up git subscriptions
    @subscribeToRepositories()

    # subscribe to adding tabs
    @subscriptions.add atom.workspace.onDidAddPaneItem (tab) =>
      @handleNewTab(tab)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem (tab) =>
      @handleDestroyedTab(tab)

  deactivate: ->
    @subscriptions.dispose()
    @repoSubscriptions.dispose()
    @git.destroy()

  getStorageDir: ->
    return process.env.ATOM_HOME + '/git-tabs'

  subscribeToRepositories: ->
    @git.onDidChangeBranch (data) =>
      @handleBranchChange(data)

  handleBranchChange: (data) ->
    data.branch.then((branchName) =>
      @clearTabs()
      @loadTabs(branchName)
    )

  clearTabs: ->
    # kill all the tabs
    atom.workspace.paneContainer.activePane.destroyItems()

  loadTabs: (branchName) ->
    items = @storageFolder.load('tabs.json')[branchName]
    for id, tab of items
      deserializedTab = atom.deserializers.deserialize(tab)
      atom.workspace.paneContainer.activePane.addItem(deserializedTab)

  storeTabs: ->
    @git.getBranch().then (branchName) =>
      for tab in atom.workspace.paneContainer.activePane.items
        @storeTab(tab, branchName)

  handleNewTab: (tab) ->
    @git.getBranch().then (branchName) =>
      @storeTab(tab, branchName)

  handleDestroyedTab: (data) ->
    @git.getBranch().then (branchName) =>
      @unstoreTab(tab, branchName)

  storeTab: (tab, branchName) ->
    if (tabs = @storageFolder.load('tabs.json'))
      if not tabs[branchName]
        tabs[branchName] = {}
      tabs[branchName][tab.id] = tab.serialize()
      @storageFolder.store('tabs.json', tabs)

  unstoreTab: (tab, branchName) ->
    if (tabs = @storageFolder.load('tabs.json'))?.length > 0
      if tabs[branchName]
        delete tabs[branchName][tab.id]

  destroyPaneItem: (data) ->
    console.log 'destroying pane item'

  toggle: ->
    console.log 'toggled'
