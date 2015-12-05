#
#Database Class
#==============

#This class is designed to quickly initialize the in-memory database. The database will be populated by the collections it is preset to have and will smartly save and load the database to ensure all instances of this DB are in sync.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.
#

require 'sugar'
loki = require 'lokijs'

#
#Constructor
#-----------
#On instantiation, create the database connection with a periodic saving and loading interval, and create the collections if they do not exist yet.

#This periodic saving and loading ensures that the created instance is always up to date. We need this because all the routes need to be in sync. Otherwise, changes do not propagate between instances.
#

class DB

	constructor: ->
		@_db = new loki 'db/loki.db',
			autosave: true
			autosaveInterval: @_saveInterval
		@_db.loadDatabase {}, =>
			(=>
				@_db.loadDatabase()
				console.log 'Refreshing database...'
			).every @_loadInterval
			@_init()

	#
	#Static Properties
	#-----------------
	#**_db**: This stores the Loki database

	#**_saveInterval**: This configures the save interval of the database

	#**_loadInterval**: This configures the reload interval of the database
	#

	_db: {}
	_saveInterval: 1000
	_loadInterval: 5000

	#
	#Collection Initializer
	#----------------------
	#Private initialization function that will get or create a named Loki collection.
	#

	_initCollection: (name) =>
		(@_db.getCollection name) or (@_db.addCollection name)

	#
	#Class Initializer
	#-----------------
	#Private initialization function that will populate the Loki database classes.
	#

	_init: =>
		@_initCollection collection for collection in [
			'wsdlFiles'
			'datasets'
		]
		null

	#
	#Get Collection Adapter
	#----------------------
	#Adapter to the Loki getCollection function
	#

	saveDatabase: ->
		@_db.saveDatabase()

	getCollection: (name) =>
		@_db.getCollection name

#
#Public API
#----------
#Expose the class by exporting it
#

module.exports = DB