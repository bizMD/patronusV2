require 'sugar'
del = require 'del'
util = require 'util'
docco = require 'docco'
globby = require 'globby'
Promise = require 'bluebird'
{exec} = require 'child_process'
{watch} = require 'chokidar'
{files} = require 'node-dir'
{resolve, sep, dirname, extname, basename} = require 'path'

option '-t', '--test', 'Does nothing'

task 'docs', 'Create documentation for the source code', ->
	docco_cmd = "node node_modules/docco/bin/docco --layout linear"
	globby ['routes/**/*.coffee', 'helper/*.coffee', 'Cakefile', 'server.coffee']
	.then (paths) ->
		for path in paths
			pathDir = dirname path
			docco_cmd += " -o docs/#{pathDir} #{path}"
		exec docco_cmd, (error, a, b) ->
			reject error if error?
			console.log a
			console.log b
	.catch (error) ->
		console.log 'ERROR! Could not generate documents'
		console.log error