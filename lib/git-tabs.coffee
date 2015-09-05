{CompositeDisposable} = require 'atom'
StorageFolder = require './storage-folder'
git = require './git'

module.exports =
  subscriptions: null
  repoSubscriptions: null
  git: null
  branch: null
  activeSpace: null

  activate: (state) ->
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

    # subscribe to adding panels
    @subscriptions.add atom.workspace.onDidAddPaneItem (tab) ->
      @handleNewTab(tab)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem (tab) ->
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
    data.branch.then((branchName) ->
      @branch = contents
      @clearTabs()
      @loadTabs(branchName)
    )

  clearTabs: ->
    # kill all the tabs
    atom.workspace.paneContainer.activePane.destroyItems()

  loadTabs: (branchName) ->
    items = @storageFolder.load('tabs.json')[branchName]
    atom.workspace.paneContainer.activePane.addItems(items)

  storeTabs: ->
    @git.getBranch().then (branchName) =>
      console.log 'branch name [promise resolved]'
      console.log branchName

      for tab in atom.workspace.paneContainer.activePane.items
        @storeTab(tab, branchName)

  handleNewTab: (tab) ->
    @storeTab(tab)

  handleDestroyedTab: (data) ->
    @unstoreTab(tab)

  storeTab: (tab, branchName) ->
    console.log 'store tab called'
    if (tabs = @storageFolder.load('tabs.json'))
      if not tabs[branchName]
        tabs[branchName] = {}
      tabs[branchName][tab.id] = tab.serialize()
      @storageFolder.store('tabs.json', tabs)

  unstoreTab: (tab) ->
    if (tabs = @storageFolder.load('tabs.json'))?.length > 0
      if tabs[@branch]
        delete tabs[@branch][tab.id]

  destroyPaneItem: (data) ->
    console.log 'destroying pane item'

  toggle: ->
    console.log 'toggled'
