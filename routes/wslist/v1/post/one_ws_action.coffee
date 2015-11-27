require 'sugar'

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "text/plain"}

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

	record.datasets ?= []
	record.datasets.push dataset
	wsdlFiles.update record
	console.log wsdlFiles.data
	
	rs.end()
	nx()