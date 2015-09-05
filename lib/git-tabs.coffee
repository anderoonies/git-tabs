{CompositeDisposable, TextEditor} = require 'atom'
fs = require 'fs-plus'
git = require './git'

StorageFolder = require './storage-folder'

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
    if not fs.existsSync(@storageFolder.getPath() + '/tabs.json')
      @storageFolder.store('tabs.json', {})

    @storeTabs()

    # Set up git subscriptions
    @subscribeToRepositories()

    # subscribe to tab events
    @subscriptions.add
    atom.workspace.paneContainer.activePane.onDidAddItem (event) =>
      @git.getBranchForFile(@getItemPath(event.item)).then (branch) =>
        @handleNewTab(item, index, branch)

    @subscriptions.add
    atom.workspace.paneContainer.activePane.onDidChangeActiveItem (tab) =>
      @git.getBranchForFile(@getItemPath(tab)).then (branch) =>
        @handleChangedActiveTab(tab, branch)

    @subscriptions.add
    atom.workspace.paneContainer.activePane.onDidMoveItem (event) =>
      @git.getBranchForFile(@getItemPath(event.item)).then (branch) =>
        @handleMovedTab(event, branch)

    @subscriptions.add
    atom.workspace.paneContainer.activePane.onDidRemoveItem (event) =>
      @handleRemovedTab(event)

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
    console.log 'subscribed to my repos!'

  handleNewTab: (item, index, branch) ->
    @storeTab(item, index, branch)

  handleBranchChange: (data) ->
    data.branch.then((branchName) =>
      console.log "Handling switch to #{branchName}"
      @clearTabs()
      @loadTabs(branchName)
    )

  handleRemovedTab: (event) ->
    @unstoreTab(event.item)

  handleMovedTab: (event, branch) ->
    items = @storageFolder.load('tabs.json').branch
    # the user moved the tab to the left
    if event.newIndex < event.oldIndex
      for id, item in items
        # update the tab with its new index
        if item.tab == event.item
          item.index = event.newIndex
        # all tabs to the right have new indices
        else if item.index > event.newIndex
          items.item.index++
    # the user moved the tab to the right
    else
      for id, item in items
        #update the tab with its new index
        if item.tab == event.item
          item.index = event.newIndex
        # all tabs to the right have new index
        else if item.index > event.newIndex
          items.item.index--

  handleChangedActiveTab: (tab, branch) ->
    console.log 'Handling changed active tab'
    console.log tab

    items = @storageFolder.load('tabs.json').branch
    for id, item in items
      if item.tab == tab
        items.item.active = true
      else
        items.item.active = false
    @storageFolder.store 'tabs.json'

  clearTabs: ->
    # kill all the tabs
    atom.workspace.paneContainer.activePane.destroyItems()

  storeTabs: ->
    console.log 'in store tabs'
    for tab, i in atom.workspace.paneContainer.activePane.items
      @git.getBranchForFile(@getItemPath tab).then (branch) =>
        @storeTab(tab, i, branch)

  loadTabs: (branchName) ->
    items = @storageFolder.load('tabs.json').branchName
    for id, item of items
      deserializedTab = atom.deserializers.deserialize item.tab
      atom.workspace.paneContainer.activePane.addItem deserializedTab, item.index
      if item.active
        atom.workspace.paneContainer.activePane.setActiveItem tab

  storeTab: (tab, index, branch) ->
    console.log 'in storeTab'
    isActive = atom.workspace.getActivePaneItem() ? false
    if tabs = @storageFolder.load 'tabs.json'
      if not tabs[branchName]
        tabs[branchName] = {}
      tabs[branchName][tab.id] =
        'index': index
        'active': isActive
        'tab': tab.serialize()
        
    @storageFolder.store('tabs.json', tabs)

  unstoreTab: (tab) ->
    @git.getBranchForFile(@getItemPath tab).then (branch) =>
      if tabs = @storageFolder.load 'tabs.json'
        if tabs[branch]
          delete tabs[branch][tab.id]
      @storageFolder.store('tabs.json', tabs)

  getItemPath: (item) ->
    return item.buffer.file.path ? null

  toggle: -> console.log 'togle :)'
