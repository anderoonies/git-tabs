{CompositeDisposable} = require 'atom'

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
    @branch = @git.getBranch()

    # Set up storageFolder
    @storageFolder = new StorageFolder(@getStorageDir)

    @storeTabs()

    # Set up git subscriptions
    @subscribeToRepositories()

    # subscribe to adding panels
    @subscriptions.add atom.workspace.onDidAddPaneItem (data) ->
      @handleNewTab(data)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem (data) ->
      @handleDestroyedTab(data)

  deactivate: ->
    @subscriptions.dispose()
    @repoSubscriptions.dispose()
    @git.destroy()

  getStorageDir: ->
    return path.join(process.env.ATOM_HOME + '/git-tabs')

  subscribeToRepositories: ->
    @git.onDidChangeBranch (data) =>
      @handleBranchChange(data)

  handleBranchChange: (data) ->
    data.branch.then((contents) ->
      @branch = contents
      @clearTabs()
      @loadTabs(contents)
    ))

  clearTabs: ->
    # kill all the tabs
    atom.workspace.paneContainer.activePane.destroyItems()

  loadTabs: (branchName) ->
    items = @storageFolder.load('tabs.json')[branchName]
    atom.workspace.activePane.addItems(items)

  storeTabs: ->
    for tab in atom.workspace.activePane.items when tab?
      @storePaneItem(tab)

  handleNewTab: (data) ->
    @storePaneItem(tab)

  storePaneItem: (tab) ->
    tabsJson = @storageFolder.load('tabs.json')
    if not tab.id of tabsJson[@branch]
      tabsJson[@branch][tab.id] = tab.serialize()
    @storageFolder.store(tabsJson)

  destroyPaneItem: (data) ->
    console.log 'destroying pane item'
