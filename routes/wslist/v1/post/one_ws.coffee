require 'sugar'
mv = require 'mv'
soap = require 'soap'
domain = require 'domain'
{resolve, extname} = require 'path'

# This is the timeout period
timeoutPeriod = 30000

# This function searches for the input child and saves its parent name
parseWSDL = (ws) ->
	parsed = for i of ws # For every child of ws
		if ws[i].input? then i # Check if the child has an input child
		else if typeof ws[i] is 'object' # If not, is it an object?
			parseWSDL ws[i] # If the child is an object, recurse
	parsed.flatten().unique() # At the end, flatten the array

# This function searches an object for a specific child and returns it
searchObj = (child, node) ->
	return node[child] if node[child]? # If the child is a child of the node, stop
	return searchObj child, node[obj] for obj of node when Object.has node, obj # Else, recurse

errorFcn = (error, d, rs, nx) ->
	d.removeListener 'error', errorFcn
	console.log error
	rs.write JSON.stringify {"error": "Encountered error"}
	rs.end()
	nx()

module.exports = ([rq, rs, nx], db, d) ->
	rs.writeHead 200, {"Content-Type": "text/plain"}
	return rs.end '{"error": "No file was given"}' if Object.equal rq.files, {}

	d.once 'error', (error) -> errorFcn error, rs, nx
	# The query has #{timeoutPeriod} seconds to complete
	stop = setTimeout (-> errorFcn 'Timeout triggered', d, rs, nx ), timeoutPeriod

	{ws, credentials} = rq.params
	fromDir = rq.files.wsdl.path
	toDirExt = extname rq.files.wsdl.name
	toDir = resolve process.cwd(), 'wsdl', ws + toDirExt

	soap.createClient fromDir, d.intercept (client) ->
		description = client.describe()
		console.log client.getSoapHeaders()
		mv fromDir, toDir, {mkdirp: true, clobber: false}, d.intercept () ->
			wsdlFiles = db.getCollection 'wsdlFiles'
			for action in parseWSDL description
				wsdlFile =
					wsdl: ws
					action: action
					io: searchObj action, description
				wsdlFiles.insert wsdlFile
				rs.write JSON.stringify wsdlFile
			clearTimeout stop
			rs.end()
			nx()