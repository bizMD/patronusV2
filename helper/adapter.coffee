require 'sugar'
util = require 'util'
soap = require 'soap'
{resolve} = require 'path'

whereFcn = (doc) -> return true if doc.datasets?

module.exports = (db, d) ->
	util.log 'yes'
	console.log d
	d.on 'error', (error) -> console.log 'Error entered'

	wsdlFiles = db.getCollection 'wsdlFiles'
	datasets = db.getCollection 'datasets'

	# Grab all the records with datasets
	for record in wsdlFiles.where whereFcn
		# Grab all the datasets in those records
		for dataset in record.datasets
			# WSDL File
			file = resolve process.cwd(), 'wsdl', record.wsdl + '.xml'
			soap.createClient file, d.intercept (client) ->
				client[record.action] d.intercept (results, a, b, c) ->
					datasets.insert result for result in results
					db.saveDatabase()
					console.log datasets.data