# Main file for interfacing with git.

module.exports =
  hasGit: -> atom.project.getRepositories().length > 0
  getMainRepo: -> if @hasGit() then atom.project.getRepositories()[0] else null
  getBranch: -> @getMainRepo().getShortHead()
