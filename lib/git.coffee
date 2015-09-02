# Where git is interfaced
module.exports =
  hasGit: ->
    return atom.project.getRepositories().length > 0

  getMainRepo: ->
    if hasGit()
      return atom.project.getRepositories()[0]
    else
      return null

  getBranch: ->
    if hasGit()
      return getMainRepo.getShortHead()
    else
      return null
