require 'sugar'
Promise = require 'bluebird'

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}

	new Promise (resolve, reject) ->
		{ws, act} = rq.params
		wsdlFiles = db.getCollection 'wsdlFiles'
		query = [{wsdl: ws}, {action: act}]
		record = (wsdlFiles.find '$and': query)[0]
		reject "Either #{ws} or #{act} does not exist" if not record?
		resolve record
	.then (record) ->
		console.log record
		# Important to touch only the data to preserve the original
		data = Object.reject record, 'meta', '$loki'
		rs.write JSON.stringify data.io
		rs.end()
	.catch (error) ->
		console.log error
		rs.end "{\"error\": #{error}}"
	.finally () ->
		nx()