/*
 * Main file for interfacing with git.
 */

Git = {};

Git.hasGit = function() {
    return atom.project.getRepositories().length > 0;
}

Git.getMainRepo = function() {
    if (this.hasGit()) {
        return atom.project.getRepositories()[0];
    }
}

Git.getBranch = function() {
    return this.getMainRepo().getShortHead();
}
