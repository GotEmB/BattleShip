{spawn} = require "child_process"

task "build", "build src/ to lib/", ->
	# CoffeeScript -> JavaScript
	cp = spawn "iced", ["-c", "-o", "lib", "src"]
	cp.stderr.on "data", (data) ->
		process.stderr.write data.toString()
	cp.on "exit", ->
		# Stylus -> CSS
		cp = spawn "stylus", ["src", "--out", "lib"]
		cp.stderr.on "data", (data) ->
			process.stderr.write data.toString()