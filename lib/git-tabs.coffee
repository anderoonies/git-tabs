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
    @subscriptions.add atom.workspace.onDidAddPaneItem (data) =>
      @handleNewTab(data)

    @subscriptions.add atom.workspace.onDidDestroyPaneItem (data) =>
      @handleRemovedTab(data)

  deactivate: ->
    @subscriptions.dispose()
    @repoSubscriptions.dispose()
    @git.destroy()
    @clearTabs()

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
    for id, item of items
      deserializedTab = atom.deserializers.deserialize(item.tab)
      atom.workspace.paneContainer.activePane.addItem(deserializedTab, item.index)
      if item.active
        atom.workspace.paneContainer.activePane.setActiveItem(tab)

  storeTabs: ->
    @git.getBranch().then (branchName) =>
      for tab, i in atom.workspace.paneContainer.activePane.items
        if atom.workspace.paneContainer.activePane.activeItem == tab
          @storeTab(tab, branchName, i, true)
        else
          @storeTab(tab, branchName, i, false)

  handleNewTab: (data) ->
    @git.getBranch().then (branchName) =>
      @storeTab(data.item, branchName, data.index)

  handleRemovedTab: (data) ->
    @git.getBranch().then (branchName) =>
      @unstoreTab(data.item, branchName)

  storeTab: (tab, branchName, index, isActive) ->
    if tabs = @storageFolder.load 'tabs.json'
      if not tabs[branchName]
        tabs[branchName] = {}
      tabs[branchName][tab.id] =
        'index': index
        'active': isActive
        'tab': tab.serialize()

      @storageFolder.store('tabs.json', tabs)

  unstoreTab: (tab, branchName) ->
    if tabs = @storageFolder.load 'tabs.json'
      if tabs[branchName]
        delete tabs[branchName][tab.id]
    @storageFolder.store('tabs.json', tabs)
