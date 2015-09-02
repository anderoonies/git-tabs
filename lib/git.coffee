# Where git is interfaced
module.exports =
  hasGit: ->
    return atom.project.getRepositories().length > 0

  getMainRepo: ->
    return if hasGit() atom.project.getRepositories()[0] else null

  getBranch: ->
    return if hasGit() getMainRepo.getShortHead() else null
