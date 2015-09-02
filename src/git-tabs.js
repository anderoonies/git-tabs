var CompositeDisposable = require('atom').CompositeDisposable;

var git = require('./git');

var GitTabs = {

    subscriptions: null,

    toggle: function() {
        console.log('GitTabs was toggled!');
        console.log(git.hasGit());
        console.log(git.getMainRepo());
        console.log(git.getBranch());
    },

    activate: function(state) {
        this.subscriptions = new CompositeDisposable;
        return this.subscriptions.add(atom.commands.add('atom-workspace', {
            'git-tabs:toggle': (function(_this) {
                return function() {
                    return _this.toggle();
                };
            })(this)
        }));
    },

    deactivate: function() {
        this.subscriptions.destroy()
    },
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
