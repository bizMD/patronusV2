require 'sugar'

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "text/plain"}

	{ws, act} = rq.params
	wsdlFiles = db.getCollection 'wsdlFiles'
	query = [{wsdl: ws}, {action: act}]
	record = (wsdlFiles.find '$and': query)[0]
	return rs.end '{"error": "No record exists"}' if not record?

	data = record # Important to touch only the data to preserve the original
	data = Object.reject record, 'meta', '$loki'

	rs.write JSON.stringify data.io
	rs.end()

	nx()