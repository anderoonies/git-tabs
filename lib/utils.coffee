module.exports =
  getStorageDir: ->
    return process.env.ATOM_HOME + '/git-tabs'

  getItemPath: (item) ->
    # path = if item.buffer.file then item.buffer.file.path else ''
    return item.buffer?.file?.path

  getActiveItemPath: ->
    editor = atom.workspace.getActivePane()
    return editor?.buffer.file
