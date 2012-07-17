express = require "express"
io = require "socket.io"

server = express.createServer()

server.configure ->
	server.use express.bodyParser()
	
	server.use (req, res, next) ->
		req.url = "/page.html" if req.url is "/"
		console.log "Request: #{req.path}"
		next()
	
	server.use express.static "#{__dirname}/lib", maxAge: 31557600000, (err) -> console.log "Static: #{err}"

server.listen (port = process.env.PORT || 5000), -> console.log "Listening on port #{port}"