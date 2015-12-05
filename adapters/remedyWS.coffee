#
#Adapter Configuration
#=====================

#This route is designed to take all the contents of the wsdlFiles collection.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.
#In addition, this also instantiates the database

# Require the dependencies
require 'sugar'
soap = require 'soap'
globby = require 'globby'
Promise = require 'bluebird'
{resolve, sep} = require 'path'

# This function is supplied to the where
whereFunction = (doc) ->
	true if doc.datasets?

module.exports = (pollInterval, db) ->
	console.log 'Adapter triggered...'

	# Load the collection objects
	wsdlFiles = db.getCollection 'wsdlFiles'
	datasets = db.getCollection 'datasets'

	# Purge the datasets
	datasets.removeDataOnly()

	# Grab all the records with datasets
	for record in wsdlFiles.where whereFunction
		console.log 'Found record with dataset attribute'
		console.log record
		# Grab all the datasets in those records
		for dataset in record.datasets
			
			# Grab the path to the WSDL file
			console.log "Grabbing the path to the #{record.wsdl} WSDL..."
			Promise.resolve globby "wsdl#{sep}#{record.wsdl}*"

			# Create a SOAP client
			.then (path) ->
				console.log 'Creating the client...'
				new Promise (resolve, reject) ->
					soap.createClient path[0], (error, client) ->
						reject error if error?
						resolve client

			# If the client is successful, create a SOAP request
			.then (client) ->
				console.log 'Retrieving data...'
				new Promise (resolve, reject) ->
					client.addSoapHeader JSON.parse record.credentials if record.credentials?
					client[record.action] dataset, (error, results) ->
						reject error if error?
						resolve results

			# If the request is successful, save the data to the database
			.then (results) ->
				console.log 'Saving data...'

				# Inserting data to the DB is harder than I thought...
				# Assumption, I get an array of objects for multiple results
				# Or a single object for one result
				datasets.insert result for result in results if Object.isArray results
				datasets.insert results if Object.isObject results

				db.saveDatabase()
				console.log datasets.data

			# Catch any exceptions and errors
			.catch (error) ->
				console.log 'Catch all error handler'
				console.log "ERROR! #{error}"
				console.log error?.root?.Envelope?.Body?.Fault