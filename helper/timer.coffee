args = process.argv
node = args.shift()
coffeeTimer = args.shift()

setInterval ->
	console.log 'Test'
, args[0]