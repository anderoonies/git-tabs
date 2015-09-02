const git = require('./git');

// PRIVATE METHODS //
const toggle = () => {
    console.log('GitTabs was toggled!');
    console.log(git.hasGit());
    console.log(git.getMainRepo());
    console.log(git.getBranch());
};

module.exports = {
    activate: () => {
        atom.commands.add('atom-workspace', {
            'git-tabs:toggle': () => toggle(),
        });
    },
};
