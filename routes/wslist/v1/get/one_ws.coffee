require 'sugar'
Promise = require 'bluebird'

module.exports = ([rq, rs, nx], db) ->
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
		rs.end()
	.catch (error) ->
		console.log error
		rs.end "{\"error\": #{error}}"
	.finally ->
		nx()