# Require the dependencies
require 'sugar'
mv = require 'mv'
del = require 'del'
soap = require 'soap'
Promise = require 'bluebird'
{resolve, extname} = require 'path'

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

module.exports = ([rq, rs, nx], db) ->
	# Set the JSON headers
	rs.writeHead 200, {"Content-Type": "application/json"}
	
	# Create the variables
	{ws, credentials} = rq.params
	fromDir = rq.files.wsdl?.path
	toDirExt = extname rq.files.wsdl?.name
	toDir = resolve process.cwd(), 'wsdl', ws + toDirExt

	# Do preliminary checks and reject immediately on failure
	new Promise (resolve, reject) ->
		console.log 'Performing initial checks...'
		reject 'No file was given' if Object.equal {}, rq.files
		reject 'Bad data submitted' if not Object.equal {}, Object.reject rq.params, 'ws', 'credentials'
		resolve()

	# Then, if the checks passed, move the file
	.then ->
		console.log 'Moving the file to storage...'
		new Promise (resolve, reject) ->
			mv fromDir, toDir, {mkdirp: true, clobber: false}, (error) ->
				reject error if error?
				resolve()

	# Then, if the file move succeeded, check if the file is a proper WSDL
	.then ->
		console.log 'Parsing the WSDL file...'
		soapPromise = new Promise (resolve, reject) ->
			soap.createClient toDir, (error, client) ->
				reject error if error?
				try description = client.describe()
				catch error then reject error
				resolve [client, description]

		# Or, if the WSDL check failed, delete the moved file, and stop
		.catch (error) ->
			console.log 'SOAP-specific error handler'
			console.log error
			# Delete moved file if it exists, but not if it was already there
			del toDir

		new Promise (resolve, reject) ->
			soapPromise
			.then (args...) -> resolve args
			, (error) -> reject error

	# Then, if the WSDL check passed, insert to the database
	.then (args) ->
		[client, description] = args
		console.log args
		console.log 'Inserting to the database...'
		wsdlFiles = db.getCollection 'wsdlFiles'
		for action in parseWSDL description
			wsdlFile =
				wsdl: ws
				action: action
				io: searchObj action, description
			wsdlFile.credentials = credentials if credentials?
			rs.write JSON.stringify wsdlFile
			wsdlFiles.insert wsdlFile

	# Catch any other uncaught errors and log them
	.catch (error) ->
		# Any uncaught errors go here
		console.log 'Catch all error handler'
		console.log error
		rs.write "{\"error\": \"An error occurred during the upload\"}"

	# Finally, end the response
	.finally ->
		console.log 'Ending response...'
		rs.end()
		nx()