/*
 * Main file for interfacing with git.
 */

const hasGit = () => atom.project.getRepositories().length > 0;
const getMainRepo = () => hasGit() ? atom.project.getRepositories()[0] : null;
const getBranch = () => getMainRepo().getShortHead();

module.exports = {
    hasGit,
    getMainRepo,
    getBranch,
};
