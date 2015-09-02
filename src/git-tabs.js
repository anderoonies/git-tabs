const {CompositeDisposable} = require('atom');

const git = require('./git');

// PRIVATE METHODS //
const toggle = () => {
    console.log('GitTabs was toggled!');
    console.log(git.hasGit());
    console.log(git.getMainRepo());
    console.log(git.getBranch());
};

const handleNewTab = () => {
    console.log('handling new tab');
    const branch = git.getBranch();
    console.log(branch);
};

module.exports = {
    subscriptions: null,

    activate: function activate() {
        this.subscriptions = new CompositeDisposable;
        this.subscriptions.add(
            atom.commands.add('atom-workspace', {
                'git-tabs:toggle': () => toggle(),
            })
        );

        // subscribe to adding panels
        this.subscriptions.add(
            atom.workspace.onDidAddPaneItem(() => {
                handleNewTab();
            })
        );
    },

    deactivate: function deactivate() {
        this.subscriptions.dispose();
    },
};
