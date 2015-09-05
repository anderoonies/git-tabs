{CompositeDisposable, TextEditor} = require 'atom'
fs = require 'fs-plus'
git = require './git'

StorageFolder = require './storage-folder'

module.exports =
  subscriptions: null
  repoSubscriptions: null
  git: null
  activePane: null
  tabs: null

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


    # Set up local cache for tabs
    @tabs = {}

    # Set up the active pane
    @activePane = atom.workspace.paneContainer.activePane

    # Save the current tabs
    @saveTabs()


    # Set up git subscriptions
    @subscribeToRepositories()

    # subscribe to tab events
    @subscriptions.add @activePane.onDidAddItem (event) =>
      @git.getRepoForFile(@getItemPath(event.item)).then (repo) =>
        @handleNewTab(event, repo.getShortHead())

    @subscriptions.add @activePane.onDidChangeActiveItem (tab) =>
      @git.getRepoForFile(@getItemPath(tab)).then (repo) =>
        @handleChangedActiveTab(tab, repo.getShortHead())

    @subscriptions.add @activePane.onDidMoveItem (event) =>
      @git.getRepoForFile(@getItemPath(event.item)).then (repo) =>
        @handleMovedTab(event, repo.getShortHead())

    @subscriptions.add atom.workspace.onWillDestroyPaneItem (event) =>
      # gotta copy this one so it's not destroyed
      @git.getRepoForFile(@getItemPath(event.item)).then (repo) =>
        @handleRemovedTab(event, repo.getShortHead())

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

  handleNewTab: (event, branch) ->
    tab.active = false for tab in @tabs[branch] if tab != event.item
    @saveTab(event.item, event.index, branch)

  handleBranchChange: (data) ->
    data.branch.then((branchName) =>
      console.log "switching to #{branchName}"
      @storeTabs()
      @clearTabs()
      @loadTabs(branchName)
    )

  handleRemovedTab: (event, branch) ->
    @unsaveTab(event.item)

  handleMovedTab: (event, branch) ->
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

  handleChangedActiveTab: (tab, branch) ->
    for id, item of @tabs[branch]
      if +id == tab.id
        @tabs[branch][id]['active'] = true
        console.log 'new active tab'
      else
        @tabs[branch][id]['active'] = false

  clearTabs: ->
    # kill all the tabs
    atom.workspace.paneContainer.activePane.destroyItems()

  saveTabs: ->
    for tab, i in @activePane.items
      @saveTab(tab, i)

  storeTabs: ->
    @storeageFolder.store('tabs.json', @tabs)

  loadTabs: (branchName) ->
    items = @storageFolder.load('tabs.json').branchName
    for id, item of items
      deserializedTab = atom.deserializers.deserialize item.tab
      atom.workspace.paneContainer.activePane.addItem deserializedTab, item.index
      if item.active
        atom.workspace.paneContainer.activePane.setActiveItem tab

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

  unsaveTab: (tab, branch) ->
    for id, item in @tabs[branch]
      if item.index < tab.index
        @tabs[branch][id][index]--
    delete @tabs[branch][tab.id]

  getItemPath: (item) ->
    return item.buffer?.file.path

  getActiveItemPath: ->
    editor = atom.workspace.getActivePane()
    return editor?.buffer.file

  toggle: ->
