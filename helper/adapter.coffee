require 'sugar'
util = require 'util'
soap = require 'soap'
{resolve} = require 'path'

whereFcn = (doc) -> return true if doc.datasets?

errorFcn = (error) ->
	util.log 'Error encounter'
	# console.log error

module.exports = (pollInterval, db, d) ->
	d.once 'error', errorFcn
	setTimeout (-> d.removeListener 'error', errorFcn), pollInterval

	wsdlFiles = db.getCollection 'wsdlFiles'
	datasets = db.getCollection 'datasets'

	# Grab all the records with datasets
	for record in wsdlFiles.where whereFcn
		# Grab all the datasets in those records
		for dataset in record.datasets
			# WSDL File
			file = resolve process.cwd(), 'wsdl', record.wsdl + '.xml'
			soap.createClient file, d.intercept (client) ->
				console.log record.action
				client[record.action] d.intercept (results, a, b, c) ->
					datasets.insert result for result in results
					db.saveDatabase()
					console.log datasets.data