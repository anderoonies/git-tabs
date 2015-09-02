var CompositeDisposable = require('atom').CompositeDisposable;

var git = require('./git');

var GitTabs = {
    // var modalPanel;
    // var subscriptions;

    var activate = function(state) {
        this.subscriptions
            .add(atom.commands
                     .add('atom-workspace', 'git-tabs:toggle', this.toggle()));
    };

    var deactivate = function() {
        this.subscriptions.destroy()
    };

    var toggle = function() {
        console.log('GitTabs was toggled!');
        console.log(git.hasGit());
        console.log(git.getMainRepo());
        console.log(git.getBranch());
    };
};
  // activate: (state) ->
  //   @boobahView = new BoobahView(state.boobahViewState)
  //   @modalPanel = atom.workspace.addModalPanel(item: @boobahView.getElement(), visible: false)
  //
  //   # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
  //   @subscriptions = new CompositeDisposable
  //
  //   # Register command that toggles this view
  //   @subscriptions.add atom.commands.add 'atom-workspace', 'boobah:toggle': => @toggle()
  //
  // deactivate: ->
  //   @modalPanel.destroy()
  //   @subscriptions.dispose()
  //   @boobahView.destroy()
  //
  // serialize: ->
  //   boobahViewState: @boobahView.serialize()
  //
  // toggle: ->
  //   console.log 'Boobah was toggled!'
  //
  //   if @modalPanel.isVisible()
  //     @modalPanel.hide()
  //   else
  //     @modalPanel.show()

  module.exports = GitTabs;
