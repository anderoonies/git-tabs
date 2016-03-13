fs = require 'fs-plus'
GitTabs = require '../lib/git-tabs'
StorageFolder = require '../lib/storage-folder'
{getStorageDir, getItemPath} = require '../lib/utils'

describe "GitTabs", ->
  repo = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('git-tabs')

  afterEach ->
    repo?.release()

  describe ".activate()", ->
    it "creates a local cache", ->
      expect(fs.existsSync(getStorageDir() + "/#{@projectName}.json")).toBe true
