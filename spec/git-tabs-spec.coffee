fs = require 'fs-plus'
GitTabs = require '../lib/git-tabs'
StorageFolder = require '../lib/storage-folder'

describe "GitTabs", ->
  repo = null

  afterEach ->
    repo?.release()

  describe ".activate()", ->
    it "creates a local cache"
      expect(fs.existsSync(@storageFolder.getPath() + "/#{@projectName}.json")).toBe true
