#
#Upload One WSDL File
#=================

#This route is designed to receive a wsdl file upload and its credentials.

#Requiring Dependencies
#----------------------

#Require the modules we need for this class.
#In addition, this also instantiates the database

require 'sugar'
mv = require 'mv'
del = require 'del'
soap = require 'soap'
Promise = require 'bluebird'
{resolve, extname} = require 'path'

#Parse WSDL
#----------

#This function searches for the child with key "input" and saves the key name of its parent. This is a recursive function.

#It will scan every child of the object.
#+ If the child is named "input" then push the name of that parent to an array.
#+ If the child is an object, call this function with the child as an input and push the result to the array.
#+ If the child fits neither of the two above, do nothing.

#Before the function ends, return the array. The array is flattened and unique, using SugarJS.

#**Input**: a JS object

#**Output**: an array with the names of all the objects that has a child named "input"

parseWSDL = (ws) ->
	parsed = for i of ws
		if ws[i].input? then i
		else if typeof ws[i] is 'object' then parseWSDL ws[i]
	parsed.flatten().unique()

#Search Object
#-------------

#This function searches an object for a specific child key name and returns it. This is a recursive function.

#It has the following logic:
#+ If the current object has a child with the specified name, return that child
#+ Else, recurse. For all children of the object, call this function with that child passed in as the new haystack
#+ If the child is not an object, it will not pass the first two conditions. In that case, do nothing.

#**Input**: the name of the child being looked for, and the object to look in

#**Output**: the child of the passed in object references with the given key name.

searchObj = (child, node) ->
	return node[child] if node[child]?
	return searchObj child, node[obj] for obj of node when Object.has node, obj

#Promised Checks
#---------------

#Do preliminary checks and reject immediately on failure

#**Input**: a RESTify request object

#**Output**:
#1. On success, return nothing. But, it **must** find uploaded files *and* the data must match exactly the expected format to succeed. The expected format is, the passed in data must *not* contain anything other than "file" or "credentials"
#2. On failure, the error message appropriate to the error. If it throws an error, the promise chain is broken.

promisedChecks = (rq) ->
	console.log 'Performing initial checks...'
	new Promise (resolve, reject) ->
		reject 'No file was given' if Object.equal {}, rq.files
		reject 'Bad data submitted' if not Object.equal {}, Object.reject rq.params, 'ws', 'credentials'
		resolve()

#Promised Move File
#------------------

#Move the file from the specified location (in the temporary files folder) to the specified location (in the webserver folder)

#**Input**: the temporary file path (source), the direction folder

#**Output**:
#1. On success, return nothing. It must not encounter the same file already existing in the folder to have it pass.
#2. On failure, the error message appropriate to the error. If it throws an error, the promise chain is broken.
promisedMoveFile = (fromDir, toDir) ->
	console.log 'Moving the file to storage...'
	new Promise (resolve, reject) ->
		mv fromDir, toDir, {mkdirp: true, clobber: false}, (error) ->
			reject 'A file with that name already exists' if error?
			resolve()

#Promised SOAP
#------------------

#Check if the file is a proper WSDL by loading it with the SOAP library, and describing the resulting file.

#**Input**: the WSDL file location

#**Output**:
#1. On success, return the client object and WS description. To pass, it should not generate an error while loading the WSDL file and when describing the services from that file.
#2. On failure, the error message appropriate to the error. If it throws an error, the promise chain is broken.

promisedSOAP = (wsdlPath) ->
	console.log 'Parsing the WSDL file...'
	new Promise (resolve, reject) ->
		soap.createClient wsdlPath, (error, client) ->
			reject error if error?
			try description = client.describe()
			catch error then reject error
			resolve [client, description]

#Insert To Database
#------------------

#Insert into the database an object that describes which WSDL file it belongs to, which SOAP method it stands for, and the input/output format that method expects. If the user passed in credentials, it will insert that in as well.

#**Input**: a RESTify request and response object, the name of the wsdl, the database link, and an array containing the SOAP client and web service description in that order

#**Output**:
#1. On success, insert the object into the database, as well as return the JSON through a stream to the requestor.
#2. On failure, throw an error. This only fails due to an unexpected error.

insertToDatabase = (rq, rs, db, ws, [client, description]) ->
	console.log 'Inserting to the database...'
	credentials = rq.params.credentials
	wsdlFiles = db.getCollection 'wsdlFiles'
	wsdlFiles.on 'insert', (record) -> console.log record
	for action in parseWSDL description
		wsdlFile =
			wsdl: ws
			action: action
			io: searchObj action, description
		wsdlFile.credentials = credentials if credentials?
		rs.write JSON.stringify wsdlFile
		wsdlFiles.insert wsdlFile

#Error Catcher
#-------------

#This function logs an error and sends back the error message.

#**Input**: a RESTify response object, an error message

#**Output**: returns nothing. It will log and send the error to the requestor.

errorCatcher = (rs, error) ->
	console.log error
	rs.write "{\"error\": #{error}}"

#Final Function
#--------------

#This function ends the response and moves on to the next middleware if defined

finalFunction = (rs, nx) ->
	rs.end()
	nx()

#Route Definition
#----------------

#This will return the headers with HTTP 200 Status Code, and a JSON content type. It will define some variables before taking action. It will then execute a promise chain that will end with inserting WSDL actions to the database if successful.

#Due to the order of the promises in the chain, it first moves the WSDL file from the temporary location before putting it in the webserver folder, unverified. As an effect, this produces a promise chain inside the third link of the parent promise chain.

#The idea is if it failed on the file move, that's because the file already existed in the first place. But if it failed on the SOAP tests, then the file must have already been moved, but that file didn't exist before. So, it must be deleted.

module.exports = ([rq, rs, nx], db) ->
	rs.writeHead 200, {"Content-Type": "application/json"}

	{ws} = rq.params
	fromDir = rq.files.wsdl?.path
	toDirExt = extname rq.files.wsdl?.name
	toDir = resolve process.cwd(), 'wsdl', ws + toDirExt

	promisedChecks rq
	.then -> promisedMoveFile fromDir, toDir
	.then ->
		promisedSOAP toDir
		.then (clientObj) -> insertToDatabase rq, rs, db, ws, clientObj
		.catch (error) ->
			console.log 'SOAP-specific error handler'
			errorCatcher rs, error
			del toDir
	.catch (error) -> errorCatcher rs, error
	.finally -> finalFunction rs, nx