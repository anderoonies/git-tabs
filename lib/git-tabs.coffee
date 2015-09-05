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
    for tab, i in atom.workspace.paneContainer.activePane.items
      if atom.workspace.paneContainer.activePane.activeItem == tab
        @storeTab(tab, i, true)
      else
        @storeTab(tab, i, false)

  handleNewTab: (data) ->
    @storeTab(data.item, data.index)

  handleRemovedTab: (data) ->
    @unstoreTab(data.item)

  storeTab: (tab, index, isActive) ->
    @git.getBranchForFile(tab.buffer.file.path).then (branch) =>
      if tabs = @storageFolder.load 'tabs.json'
        if not tabs[branch]
          tabs[branch] = {}
        tabs[branch][tab.id] =
          'index': index
          'active': isActive
          'tab': tab.serialize()

        @storageFolder.store('tabs.json', tabs)

  unstoreTab: (tab) ->
    @git.getBranchForFile(tab.buffer.file.path).then (branch) =>
      if tabs = @storageFolder.load 'tabs.json'
        if tabs[branch]
          delete tabs[branch][tab.id]
      @storageFolder.store('tabs.json', tabs)
