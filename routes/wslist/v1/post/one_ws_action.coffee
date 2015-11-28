require 'sugar'
vow = require 'vow'
soap = require 'soap'
globby = require 'globby'
domain = require 'domain'
{resolve, sep} = require 'path'

# The timeout period
timeoutPeriod = 30000
d = domain.create()

errorFcn = (error, rs, nx) ->
	console.log 'I got here'
	rs.end '{"error": "Error occurred"}'
	nx()

d.on 'error', (err) -> errorFcn

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "text/plain"}

	# On error, end the response
	d.once 'error', (error) -> return errorFcn error, rs, nx
	# The query has #{timeoutPeriod} seconds to complete
	stop = setTimeout (-> errorFcn 'Timeout triggered', d, rs, nx ), timeoutPeriod

	{ws, act} = rq.params
	dataset = Object.reject rq.params, 'ws', 'act'

	wsdlFiles = db.getCollection 'wsdlFiles'
	record = (wsdlFiles.find '$and': [{wsdl: ws}, {action: act}])[0]
	return rs.end '{"error": "No record exists"}' if not record?
	return rs.end '{"error": "Duplicate exists"}' if (record.datasets?.find dataset)?
	
	register = {}
	for item of record.io.input
		blacklist = ['targetnamespace', 'targetnsalias']
		i = item.replace /\[\]$/, ''
		register[i] = record.io.input[item] if item.toLowerCase() not in blacklist
	
	keys = Object.keys register
	input = Object.keys dataset
	return rs.end '{"error": "Inputs do not match"}' if not Object.equal input, keys

	globby "wsdl#{sep}#{ws}*"
	.then (paths) ->
		new vow.Promise (resolve) ->
			soap.createClient paths[0], d.intercept (client) ->
				client.describe()
				client.addSoapHeader record.credentials if record.credentials?
				client[act] dataset, d.intercept (results) ->
					rs.write JSON.stringify result for result in results
					clearInterval stop
					resolve()
	.then ->
		console.log 'I still got here'
		record.datasets ?= []
		record.datasets.push dataset
		wsdlFiles.update record
		console.log wsdlFiles.data
		
		rs.end()
		nx()