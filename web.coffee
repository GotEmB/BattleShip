express = require "express"
socket_io = require "socket.io"
fluent = require "./fluent"
md5 = require "MD5"
http = require "http"
{spawn} = require "child_process"

cp = spawn "icake", ["build"]
await cp.on "exit", defer code
return console.log "Build failed! Run 'icake build' to display build errors." if code isnt 0

class BattleShip
	@currentGames:
		length: 0
	class @Coordinates
		constructor: (coordinates) ->
			@x = coordinates.x
			@y = coordinates.y
	class @Ship
		constructor: (ship) ->
			@coordinates = new BattleShip.Coordinates ship.coordinates
			@orientation = ship.orientation
		sunk: false
	class @Ships
		constructor: (ships) ->
			@aircraftCarrier = new BattleShip.Ship ships.aircraftCarrier
			@battleShip = new BattleShip.Ship ships.battleShip
			@submarine = new BattleShip.Ship ships.submarine
			@cruiser = new BattleShip.Ship ships.cruiser
			@destroyer = new BattleShip.Ship ships.destroyer
	class @Player
		constructor: (socket) ->
			@socket = socket
			@shotAt = []
		ships: null
		kaboom: (coordinates) =>
			@shotAt.push new BattleShip.Coordinates coordinates
			for ship, i in [@ships.aircraftCarrier, @ships.battleShip, @ships.submarine, @ships.cruiser, @ships.destroyer]
				continue if ship.sunk
				len = if i is 0 then 5 else if i is 1 then 4 else if i is 4 then 2 else 3
				op = 
					if ship.orientation is "horizontal"
						for j in [0...len]
							if coordinates.x is ship.coordinates.x + j and coordinates.y is ship.coordinates.y
								"kaboom"
							else if @shotAt.any((coord) -> coord.x is ship.coordinates.x + j and coord.y is ship.coordinates.y)
								"hit"
							else
								"safe"
					else
						for j in [0...len]
							if coordinates.x is ship.coordinates.x and coordinates.y is ship.coordinates.y + j
								"kaboom"
							else if @shotAt.any((coord) -> coord.x is ship.coordinates.x and coord.y is ship.coordinates.y + j)
								"hit"
							else
								"safe"
				if op.contains "kaboom"
					return if op.contains "safe" then result: "hit"
					else
						ship.sunk = true
						if fluent.Dictify(@ships).all((x) -> x.value.sunk) then result: "gameOver"
						else
							result: "sunk"
							ship:
								type:
									switch i
										when 0 then "aircraftCarrier"
										when 1 then "battleShip"
										when 2 then "submarine"
										when 3 then "cruiser"
										when 4 then "destroyer"
								coordinates: ship.coordinates
								orientation: ship.orientation
			result: "miss"
	class @Game
		constructor: ->
			@id = @constructor.generateNewGameId()
			BattleShip.currentGames[@id] = @
			BattleShip.currentGames.length++
			console.log "New Game: #{@id}, Total Games: #{BattleShip.currentGames.length}"
		player1: null
		player2: null
		@generateNewGameId = ->
			id = md5("#{Date.now()}").substr(0, 6).toUpperCase() until id? and !BattleShip.currentGames[id]?
			id

expressServer = express.createServer()
expressServer.configure ->
	
	expressServer.use express.bodyParser()
	expressServer.use (req, res, next) ->
		req.url = "/page.html" if req.url is "/"
		next()
	expressServer.use express.static "#{__dirname}/lib", maxAge: 31557600000, (err) -> console.log "Static: #{err}"
	expressServer.use expressServer.router

server = http.createServer expressServer

io = socket_io.listen server
io.configure ->
	io.set "log level", 0
io.sockets.on "connection", (socket) ->
	
	socket.on "resetAll", (callback) ->
		if socket.game?
			console.log "End Game: #{socket.game.id}, Total Games: #{BattleShip.currentGames.length - 1}"
			game = socket.game
			socket.game = null
			BattleShip.currentGames[game.id] = null
			BattleShip.currentGames.length--
			if game.player1.socket is socket
				if game.player2?
					game.player2.socket.emit "friendDisconnected"
					game.player2.socket.game = null
			else if game.player2.socket is socket
				if game.player1?
					game.player1.socket.emit "friendDisconnected"
					game.player1.socket.game = null
		callback()
	
	socket.on "newGame", (callback) ->
		if BattleShip.currentGames.length >= 1000
			callback status: "Server full"
		else
			socket.game = new BattleShip.Game()
			socket.game.player1 = new BattleShip.Player socket
			callback status: "Game created", id: socket.game.id
			
	socket.on "joinGame", (id, callback) ->
		id = id.toUpperCase()
		if !BattleShip.currentGames[id]?
			callback status: "Invalid game"
		else if BattleShip.currentGames[id].player2?
			callback status: "Game full"
		else
			socket.game = BattleShip.currentGames[id]
			socket.game.player2 = new BattleShip.Player socket
			callback status: "Game joined"
			socket.game.player1.socket.emit "friendJoined"
			
	socket.on "setShips", (ships) ->
		if !socket.game?
			return socket.emit "friendDisconnected"
		if socket.game.player1.socket is socket
			socket.game.player1.ships = new BattleShip.Ships ships
		else
			socket.game.player2.ships = new BattleShip.Ships ships
		if socket.game.player1.ships? and socket.game.player2.ships?
			socket.game.player1.socket.emit "yourTurn"
			socket.game.player2.socket.emit "theirTurn"
	
	socket.on "kaboom", (coordinates, callback) ->
		if !socket.game?
			callback()
			return socket.emit "friendDisconnected"
		targetPlayer = null
		if socket.game.player1.socket is socket
			targetPlayer = socket.game.player2
		else
			targetPlayer = socket.game.player1
		result = targetPlayer.kaboom coordinates
		targetPlayer.socket.emit "shotAt", shotAt: coordinates, result: result
		callback result
		
	socket.on "disconnect", ->
		if socket.game?
			console.log "End Game: #{socket.game.id}, Total Games: #{BattleShip.currentGames.length - 1}"
			game = socket.game
			socket.game = null
			BattleShip.currentGames[game.id] = null
			BattleShip.currentGames.length--
			if game.player1.socket is socket
				if game.player2?
					game.player2.socket.emit "friendDisconnected"
					game.player2.socket.game = null
			else if game.player2.socket is socket
				if game.player1?
					game.player1.socket.emit "friendDisconnected"
					game.player1.socket.game = null

server.listen (port = process.env.PORT ? 5000), -> console.log "Listening on port #{port}"