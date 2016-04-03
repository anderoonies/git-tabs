{CompositeDisposable, TextEditor} = require 'atom'
fs = require 'fs-plus'
git = require './git'
{getStorageDir, getItemPath} = require './utils'
path = require 'path'

StorageFolder = require './storage-folder'

module.exports =
  subscriptions: null
  repoSubscriptions: null
  git: null
  activePane: null
  tabs: null
  projectName: null
  activeBranch: null

  activate: ->
    # if there is no git repository we can be of no help
    unless atom.project.getRepositories()[0]
      return

    @subscriptions = new CompositeDisposable

    # Set up project name
    @projectName = path.basename(atom.project.getPaths()?[0])

    # Set up git stuff
    @git = git
    @git.create()
    @activeBranch = @git.getCurrentBranch()

    # Set up storageFolder
    @storageFolder = new StorageFolder
    @branchTabsName = [@projectName, @activeBranch].join('-')

    # Set up local 'cache' for tabs
    @tabs = {}

    # Set up the active pane shortcut
    @activePane = atom.workspace.paneContainer.activePane
    @activeTabIndex = 0

    # Load tabs if the user has already stored them in a previous session
    @storedBranchTabs = @storageFolder.load(@activeBranch)
    if @storedBranchTabsName
      @clearTabs()
      @loadTabs(@activeBranch)

    @setActiveTab()

    # Save the current tabs to cache
    @saveTabs()

    # Set up git subscriptions
    @subscribeToRepositories()

  deactivate: ->
    # If this isn't true there's nothing to do
    unless project.getRepositories()[0]
      return

    # Store tabs before closing
    @storeTabs()
    # Remove all subscriptions
    @subscriptions.dispose()
    @repoSubscriptions.dispose()
    # Stop watching git files
    @git.destroy()

  # Listens for a branch change
  subscribeToRepositories: ->
    @git.onDidChangeBranch (data) =>
      @handleBranchChange(data)
      @setActiveTab()

  handleNewTab: (event) ->
    @saveTab(event.item, event.index)

  handleBranchChange: (data) ->
    data.branch.then((head) =>
      shortHead = path.basename(head.trim())
      @storeTabs()
      @clearTabs()
      @activeBranch = shortHead
      @loadTabs(shortHead)
    )

  handleRemovedTab: (item) ->
    @unsaveTab(item)

  # Kill all the tabs
  clearTabs: ->
    atom.workspace.getActivePane()?.destroyItems()

  # Save all tabs to local 'cache'
  saveTabs: ->
    @tabs[@activeBranch] = {}
    for tab, i in @activePane.items
      @saveTab(tab, i)

  # Save a tab to the local 'cache'
  saveTab: (tab, index) ->
    isActive = atom.workspace.getActivePaneItem() == tab
    # the item path is the most unique way to hash it.
    @tabs[@activeBranch][getItemPath tab] =
      'index': index
      'active': isActive

  # Store tabs as JSON
  storeTabs: ->
    @saveTabs()
    @storageFolder.store(@activeBranch, @tabs[@activeBranch])

  # Load tabs from JSON
  loadTabs: (branch) ->
    @tabs[branch] = @storageFolder.load(branch)
    workspace = atom.workspace

    for id, item of @tabs[branch]
      workspace.open(id)
      if item.active
        @activeTabIndex = item.index

  # Remove a tab from the local 'cache'
  unsaveTab: (tab) ->
    tabFilePath = getItemPath tab
    @git.getRepoForFile(tabFilePath).then (repo) =>
      branch = repo.getShortHead()
      for id, item in @tabs[branch]?
        if item.index < tab.index
          @tabs[branch][id][index]--
      delete @tabs[branch]?[tab.id]

  # Set the correct active tab
  setActiveTab: ->
    # activeTab = atom.workspace.paneContainer.activePane.itemAtIndex(@activeTabIndex)
    # @activePane.setActiveItem(activeTab)
