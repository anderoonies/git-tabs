GitTabsView = require './git-tabs-view'
{CompositeDisposable} = require 'atom'

module.exports = GitTabs =
  gitTabsView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @initRepo()
    @gitTabsView = new GitTabsView(state.gitTabsViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @gitTabsView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'git-tabs:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @gitTabsView.destroy()

  serialize: ->
    gitTabsViewState: @gitTabsView.serialize()

  toggle: ->
    console.log 'GitTabs was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  initRepo: ->
    console.log 'In initRepo!'
    repo = atom.project.getRepo()
    repos = atom.project.getRepositories()
    for repo in repos
      console.log(repo.getShortHead())
    # console.log(repo.getShortHead())
