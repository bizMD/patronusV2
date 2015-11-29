# Parse the arguments passed
args = process.argv
node = args.shift()
coffeeTimer = args.shift()

# Function to trigger to stdout
triggerOut = -> console.log 'Trigger'

# Execute the timer
triggerOut()
setInterval triggerOut, args[0]