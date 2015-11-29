require 'sugar'
Promise = require 'bluebird'

module.exports = ([rq, rs, nx], db) ->
	# Set the JSON headers
	rs.writeHead 200, {"Content-Type": "application/json"}

	new Promise (resolve, reject) ->
		{ws} = rq.params
		wsdlFiles = db.getCollection 'wsdlFiles'
		record = wsdlFiles.find wsdl: ws
		reject "WSDL #{ws} does not exist" if record.length is 0
		resolve record
	.then (record) ->
		console.log record
		# Return cleaned data (without meta info)
		rs.write JSON.stringify Object.reject wsdl, 'meta', '$loki' for wsdl in record
	.catch (error) ->
		console.log error
		rs.write "{\"error\": #{error}}"
	.finally ->
		rs.end()
		nx()