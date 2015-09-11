{CompositeDisposable, TextEditor} = require 'atom'
fs = require 'fs-plus'
git = require './git'
path = require 'path'

StorageFolder = require './storage-folder'

module.exports =
  subscriptions: null
  repoSubscriptions: null
  git: null
  activePane: null
  tabs: null
  projectName: null

  activate: ->
    @subscriptions = new CompositeDisposable

    # Set up project name
    @projectName = path.basename(atom.project.getPaths()?[0])

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'git-tabs:toggle': => @toggle()

    # Set up git stuff
    @git = git
    @git.create()

    # Set up storageFolder
    @storageFolder = new StorageFolder @getStorageDir()
    if not fs.existsSync(@storageFolder.getPath() + "/#{@projectName}.json")
      @storageFolder.store(@projectName, {})

    # Set up local 'cache' for tabs
    @tabs = {}

    # Set up the active pane shortcut
    @activePane = atom.workspace.paneContainer.activePane

    # Save the current tabs
    @saveTabs()

    # Set up git subscriptions
    @subscribeToRepositories()

    # subscribe to tab events
    @subscriptions.add @activePane.onDidAddItem (event) =>
      @handleNewTab(event)

    @subscriptions.add @activePane.onDidMoveItem (event) =>
      @handleMovedTab(event)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem (event) =>
      @handleRemovedTab(event.item)

  deactivate: ->
    @subscriptions.dispose()
    @repoSubscriptions.dispose()
    @git.destroy()
    @storeTabs
    @clearTabs()

  getStorageDir: ->
    return process.env.ATOM_HOME + '/git-tabs'

  subscribeToRepositories: ->
    @git.onDidChangeBranch (data) =>
      @handleBranchChange(data)

  handleNewTab: (event) ->
    @saveTab(event.item, event.index)

  handleBranchChange: (data) ->
    data.branch.then((head) =>
      shortHead = path.basename(head.trim())
      @saveTabs()
      @storeTabs()
      @clearTabs()
      @loadTabs(shortHead)
    )

  handleRemovedTab: (item) ->
    @unsaveTab(item)

  handleMovedTab: (event) ->
    tabFilePath = @getItemPath tab
    @git.getRepoForFile(tabFilePath).then (repo) =>
      branch = repo.getShortHead()
      # the user moved the tab to the left
      if event.newIndex < event.oldIndex
        for id, item in @tabs[branch]
          # update the tab with its new index
          if item.tab == event.item
            @tabs[branch][id][index] = event.newIndex
          # all tabs to the right have new indices
          else if item.index > event.newIndex
            @tabs[branch][id][index]++
      # the user moved the tab to the right
      else
        for id, item in @tabs.branch
          #update the tab with its new index
          if item.tab == event.item
            @tabs[branch][id][index] = event.newIndex
          # all tabs to the right have new index
          else if item.index > event.newIndex
            @tabs[branch][id][index]--

  handleChangedActiveTab: (tab) ->
    tabFilePath = @getItemPath tab
    @git.getRepoForFile(tabFilePath).then (repo) =>
      branch = repo.getShortHead()
      for id, item of @tabs[branch]
        if +id == tab.id
          @tabs[branch][id]['active'] = true
          console.log 'new active tab'
        else
          @tabs[branch][id]['active'] = false

  clearTabs: ->
    # kill all the tabs
    console.log 'killing'
    atom.workspace.getActivePane()?.destroyItems()

  saveTabs: ->
    for tab, i in @activePane.items
      @saveTab(tab, i)

  storeTabs: ->
    @storageFolder.store(@projectName, @tabs)

  loadTabs: (branch) ->
    console.log('loading. brk here');
    @tabs = @storageFolder.load(@projectName)
    for id, item of @tabs[branch]
      deserializedTab = atom.deserializers.deserialize item.tab
      atom.workspace.paneContainer.activePane.addItem deserializedTab, item.index
      if item.active
        atom.workspace.paneContainer.activePane.setActiveItem(tab)

  saveTab: (tab, index) ->
    tabFilePath = @getItemPath tab
    @git.getRepoForFile(tabFilePath).then (repo) =>
      branch = repo.getShortHead()
      isActive = atom.workspace.getActivePaneItem() == tab ? false
      if not @tabs[branch]
        @tabs[branch] = {}
      @tabs[branch][tab.id] =
        'index': index
        'active': isActive
        'tab': tab.serialize()

  unsaveTab: (tab) ->
    tabFilePath = @getItemPath tab
    @git.getRepoForFile(tabFilePath).then (repo) =>
      branch = repo.getShortHead()
      for id, item in @tabs[branch]?
        if item.index < tab.index
          @tabs[branch][id][index]--
      delete @tabs[branch]?[tab.id]

  getItemPath: (item) ->
    return item.buffer?.file.path

  getActiveItemPath: ->
    editor = atom.workspace.getActivePane()
    return editor?.buffer.file

  toggle: ->
