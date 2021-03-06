easeInOut = (x) -> Math.pow (Math.sin((x - 0.5) * Math.PI) + 1) * 0.5, 2
roundTo1 = (x) -> Math.round(x * 10) / 10

async = (a, b) ->
	func = if typeof a is "function" then a else if typeof b is "function" then b else null
	timeOut = if typeof a is "number" then a else if typeof b is "number" then b else null
	console.log func: func ? null, timeOut: timeOut ? null
	return unless func?
	setTimeout func, timeOut ? 0

bindMouseDown = (sel, fn) ->
	$(sel).bind "mousedown", fn
	$(sel).bind "touchstart", fn

pleaseWait =
	counter: 0
	show: ->
		pleaseWait.counter++
		$("#pleaseWait").css "display", "block" if pleaseWait.counter > 0
	hide: ->
		pleaseWait.counter--
		$("#pleaseWait").css "display", "none" if pleaseWait.counter <= 0

wdp = window.devicePixelRatio ? 1

viewport = document.querySelector "meta[name=viewport]"
viewport.setAttribute 'content', "user-scalable=no, width=#{320 * wdp}, height=#{416 * wdp}, initial-scale=#{1.0 / wdp}, maximum-scale=#{1.0 / wdp}"

canvas = null

socket = io.connect()
socket.on "connect", -> pleaseWait.hide()
socket.on "friendJoined", -> setupGame()
socket.on "friendDisconnected", -> gotoGameOverMenu "Your friend has left the game."

class viewController
	@viewStack: ["mainMenu"]
	@push: (viewId, animate) =>
		if animate ? true
			$("#menuView").addClass "enableTransitions"
		else
			$("#menuView").removeClass "enableTransitions"
		$("##{_(@viewStack).last()}").addClass "moveLeft"
		$("##{viewId}").removeClass "moveRight"
		@viewStack.push viewId
	@pop: (animate) =>
		if animate ? true
			$("#menuView").addClass "enableTransitions"
		else
			$("#menuView").removeClass "enableTransitions"
		$("##{_(@viewStack).last()}").addClass "moveRight"
		@viewStack.pop()
		$("##{_(@viewStack).last()}").removeClass "moveLeft"
	@popTo: (viewId, animate) =>
		$("#menuView").removeClass "enableTransitions"
		@pop animate ? true unless _(@viewStack).last() is viewId
		until _(@viewStack).last() is viewId
			@pop false
	@hideViewContainer: (animate) ->
		if animate ? true
			$("#menuViewContainer").addClass "enableTransitions"
		else
			$("#menuViewContainer").removeClass "enableTransitions"
		$("#menuViewContainer").addClass "moveDown"
	@showViewContainer: (animate) ->
		if animate ? true
			$("#menuViewContainer").addClass "enableTransitions"
		else
			$("#menuViewContainer").removeClass "enableTransitions"
		$("#menuViewContainer").removeClass "moveDown"

window.onpopstate = (e) ->
	pleaseWait.show()
	socket.emit "resetAll", -> pleaseWait.hide()
	async 550, -> setupCanvas reset: true
	viewController.popTo "mainMenu"
	viewController.showViewContainer()

setupPage = ->
	window.scrollTo 0, 1
	
	$(document).bind "touchmove", (e) -> e.preventDefault()
	$(document).bind "touchstart", (e) -> e.preventDefault() unless $(e.srcElement).hasClass "selectable"
	$(document).bind "touchend", (e) -> e.preventDefault() unless $(e.srcElement).hasClass "selectable"
	
	pleaseWait.show()

	canvas = document.getElementById "canvas"
	canvas.setAttribute 'width', "#{320 * wdp}"
	canvas.setAttribute 'height', "#{416 * wdp}"
	paper.install window
	paper.setup canvas
	
	$("html, body").css "width", 320 * wdp
	$("html, body").css "height", 416 * wdp

	$("#menuView").css "display", "block"
	
	if wdp isnt 1
		$("#menuView").css "-webkit-transform", "scale(#{wdp})"
		$("#setupShipsOverlay").css "-webkit-transform", "scale(#{wdp})"
	
	$("#pleaseWait div.container div.spinner").css "width", "#{60 * wdp}px"
	$("#pleaseWait div.container div.spinner").css "height", "#{60 * wdp}px"
	$("#pleaseWait div.container").css "padding", "#{1.5 * wdp}em #{1.5 * wdp}em #{1.25 * wdp}em"
	$("#pleaseWait div.container").css "margin", "#{153 * wdp}px #{112 * wdp}px"
	
	$("#gameId_Entry").focusout -> window.scrollTo 0, 1

setupEvents = ->
	bindMouseDown document, (e) ->
		window.scrollTo 0, 1
	
	bindMouseDown "#newGame_btn", (e) ->
		pleaseWait.show()
		socket.emit "newGame", (data) ->
			if data? and data.status is "Game created"
				$("#gameId").text data.id
				viewController.push "newMenu"
				history.pushState state: "newMenu", "", ""
			else
				alert "Could not create game."
				socket = io.connect()
			pleaseWait.hide()
	
	bindMouseDown "#joinGame_btn", (e) ->
		$("#gameId_entry").text ""
		viewController.push "joinMenu"
		history.pushState state: "joinMenu", "", ""
	
	bindMouseDown "#enterGameId_btn", (e) ->
		pleaseWait.show()
		socket.emit "joinGame", $("#gameId_entry").text(), (data) ->
			if data? and data.status is "Game joined"
				setupGame()
			else
				alert if data? and data.status? then data.status else "Could not join game."
			pleaseWait.hide()
	
	bindMouseDown "#gameOverOkay_btn", (e) ->
		history.back()
	
	bindMouseDown "#dialogOkay_btn", (e) ->
		viewController.hideViewContainer()

setupGame = ->
	async 550, -> viewController.popTo "mainMenu"
	viewController.hideViewContainer()
	setupCanvas setupShips: null
	history.replaceState state: "inGame", "", ""

gotoGameOverMenu = (msg, align) ->
	$("#gameOver_msg").text msg ? "Something's happened."
	$("#gameOver_msg").css "text-align", align ? "left"
	async 550, -> setupCanvas reset: true
	viewController.popTo "mainMenu"
	viewController.push "gameOverMenu", false
	viewController.showViewContainer()
	history.replaceState null, "", ""

showFriendPlacingMenu = ->
	viewController.popTo "mainMenu"
	viewController.push "friendPlacingMenu", false
	viewController.showViewContainer()

hideFriendPlacingMenu = ->	
	viewController.hideViewContainer()

showDialog = (msg) ->
	$("#dialog_desc").text msg ? "I'm supposed to say somthing to you."
	viewController.popTo "mainMenu"
	viewController.push "dialogMenu", false
	viewController.showViewContainer()

setupCanvas = (data) ->
	canvasThis = this
	mainLayer = project.layers[0]
	mainLayer.activate()
	mainLayer.children[0].remove() while mainLayer.children.length > 0
	view.draw()
	
	socket.removeAllListeners "yourTurn"
	socket.removeAllListeners "theirTurn"
	socket.removeAllListeners "shotAt"
	
	return $("#canvas").css "display", "none" if data.reset? and data.reset
	
	$("#canvas").css "display", "block"
	inactiveTool = new paper.Tool()
	inactiveTool.activate()
	
	class Game
		class @Board
			symbol: null
			placed: null
			back: null
			front: null
			position: => ((mtx) => new paper.Point [mtx._tx, mtx._ty])(@placed._matrix)
		class @Ships
			aircraftCarrier: null
			battleShip: null
			submarine: null
			cruiser: null
			destroyer: null
		class @Player
			constructor: ->
				@board = new Game.Board()
				@ships = new Game.Ships()
		@mine: new Game.Player()
		@yours: new Game.Player()
	
	# Basic Grid Layer
	do =>
		lstyle =
			strokeColor: "white"
			strokeWidth: 2 * wdp
			strokeCap: "round"
		vline = new paper.Path()
		vline.style = lstyle
		vline.add [0, 0]
		vline.add [0, 300 * wdp]
		vline_s = new paper.Symbol vline
		vlines = for i in [0..10]
			vline_s.place [i * 30 * wdp, 150 * wdp]
		hline = new paper.Path()
		hline.style = lstyle
		hline.add [0, 0]
		hline.add [300 * wdp, 0]
		hline_s = new paper.Symbol hline
		hlines = for i in [0..10]
			hline_s.place [150 * wdp, i * 30 * wdp]
		gridl = new paper.Group vlines
		gridl.addChildren hlines
		@gridl_s = new paper.Symbol gridl
	
	# Mine — Group
	do =>
		Game.mine.board.back = new paper.Layer()
		mainLayer.activate()
		mineGrid = gridl_s.place()
		Game.mine.board.front = new paper.Layer()
		mainLayer.activate()
		mine = new paper.Group [Game.mine.board.back, mineGrid, Game.mine.board.front]
		Game.mine.board.symbol = new paper.Symbol mine
	
	# Yours — Group
	do =>
		Game.yours.board.back = new paper.Layer()
		mainLayer.activate()
		yoursGrid = gridl_s.place()
		Game.yours.board.front = new paper.Layer()
		mainLayer.activate()
		yours = new paper.Group [Game.yours.board.back, yoursGrid, Game.yours.board.front]
		Game.yours.board.symbol = new paper.Symbol yours
	
	# Rotate Button
	do =>
		box = new paper.Path.Rectangle [-14 * wdp, -14 * wdp], [28 * wdp, 28 * wdp]
		box.style =
			fillColor: "white"
			strokeWidth: 2 * wdp
			strokeColor: "white"
			strokeCap: "square"
		arc = new paper.Path.Circle [0, 0], 6 * wdp
		arc.style =
			strokeColor: "black"
			strokeWidth: 3 * wdp
			strokeCap: "round"
		arc.closed = false
		arc.rotate -90
		arrow = new paper.Path [[1 * wdp, 0], [11 * wdp, 0], [6 * wdp, 5 * wdp]]
		arrow.style = fillColor: "black"
		arrow.closePath()
		rotate = new paper.Group [box, arc, arrow]
		@rotate_s = new paper.Symbol rotate
		@rotate_s.mouseDown = ->
			box.fillColor = "black"
			arc.strokeColor = "white"
			arrow.fillColor = "white"
		@rotate_s.mouseUp = ->
			box.fillColor = "white"
			arc.strokeColor = "black"
			arrow.fillColor = "black"
	
	# Next Button
	do =>
		box = new paper.Path.Rectangle [-14 * wdp, -14 * wdp], [28 * wdp, 28 * wdp]
		box.style =
			fillColor: "white"
			strokeWidth: 2 * wdp
			strokeColor: "white"
			strokeCap: "square"
		arrow = new paper.Path [[-4 * wdp, -8 * wdp], [6 * wdp, 0], [-4 * wdp, 8 * wdp]]
		arrow.style = fillColor: "black"
		arrow.closePath()
		next = new paper.Group [box, arrow]
		@next_s = new paper.Symbol next
		@next_s.mouseDown = ->
			box.fillColor = "black"
			arrow.fillColor = "white"
		@next_s.mouseUp = ->
			box.fillColor = "white"
			arrow.fillColor = "black"
	
	# Generic Ship
	makeShip = (n) ->
		line = new paper.Path [[0, 0], [30 * (n - 1) * wdp, 0]]
		line.style =
			strokeColor: "white"
			strokeWidth: 10 * wdp
			strokeCap: "round"
		select = new paper.Path [[0, 0], [30 * (n - 1) * wdp, 0]]
		select.style =
			strokeColor: "cyan"
			strokeWidth: 10 * wdp
			strokeCap: "round"
		select.strokeColor.alpha = 0.25
		select.visible = false
		red = new paper.Path [[0, 0], [30 * (n - 1) * wdp, 0]]
		red.style =
			strokeColor: "red"
			strokeWidth: 10 * wdp
			strokeCap: "round"
		red.strokeColor.alpha = 0.5
		red.visible = false
		ship = new paper.Group [line, select, red]
		ship.select = ->
			select.visible = true
		ship.deselect = ->
			select.visible = false
		ship.sunk = ->
			red.visible = true
		ship.unsunk = ->
			red.visible = false
		ship.boundary =
			horizontal: new paper.Rectangle
				x: -(150 - 15 * n) * wdp
				y: -135 * wdp
				width: 2 * (150 - 15 * n) * wdp
				height: 2 * 135 * wdp
			vertical: new paper.Rectangle
				x: -135 * wdp
				y: -(150 - 15 * n) * wdp
				width: 2 * 135 * wdp
				height: 2 * (150 - 15 * n) * wdp
		ship.orientation = "horizontal"
		ship.size = n
		ship.gridBounds = -> new paper.Rectangle
			x: roundTo1 ship.bounds.x - 15 * wdp
			y: roundTo1 ship.bounds.y - 15 * wdp
			width: roundTo1 ship.bounds.width + 30 * wdp
			height: roundTo1 ship.bounds.height + 30 * wdp
		ship
	
	# All Ships
	do =>
		for player in ["mine", "yours"]
			for ship of Game.Ships.prototype
				Game[player].ships[ship] = makeShip switch ship
					when "aircraftCarrier"then 5
					when "battleShip" then 4
					when "submarine" then 3
					when "cruiser" then 3
					when "destroyer" then 2
				Game[player].board.front.addChild Game[player].ships[ship]
				Game[player].ships[ship].visible = false
				Game[player].ships[ship].select() if player is "mine"
	
	# Red Backs
	do =>
		redBack = new paper.Path.Rectangle [0, 0], [30 * wdp, 30 * wdp]
		redBack.style = fillColor: "red"
		redBack.fillColor.alpha = 0.5
		@redBack_s = new paper.Symbol redBack
	
	# Red Cursor
	do =>
		@redCursor = new paper.Path.Rectangle [0, 0], [30 * wdp, 30 * wdp]
		@redCursor.style = fillColor: "red"
		@redCursor.fillColor.alpha = 0.8
		@redCursor.opacity = 0
		@redCursor.remove()
		@redCursor.show = ->
			view.onFrame = (e) =>
				if e.time > 0.5
					view.onFrame = null
					@opacity = 0
				else
					@opacity = 1 - easeInOut e.time / 0.5
	
	# Cursor
	do =>
		@cursor = new paper.Path.Rectangle [0, 0], [30 * wdp, 30 * wdp]
		@cursor.style = fillColor: "yellow"
		@cursor.fillColor.alpha = 0.5
		@cursor.remove()
	
	# Shot
	do =>
		shot = new paper.Path.Circle [0, 0], 5 * wdp
		shot.style = fillColor: "white"
		@shot_s = new paper.Symbol shot
	
	# Flag
	do =>
		flag = new paper.Path.Circle [0, 0], 2 * wdp
		flag.style = fillColor: "white"
		@flag_s = new paper.Symbol flag
	
	# Red Shot
	do =>
		shot = new paper.Path.Circle [0, 0], 3 * wdp
		shot.style = fillColor: "white"
		red = new paper.Path.Circle [0, 0], 3 * wdp
		red.style = fillColor: "red"
		red.fillColor.alpha = 0.5
		redShot = new paper.Group [shot, red]
		@redShot_s = new paper.Symbol redShot
	
	# Setup Ships
	do =>
		$("#setupShipsOverlay").css "display", "block"
		Game.mine.board.placed = Game.mine.board.symbol.place [160 * wdp, 160 * wdp]
		@rotate_p = @rotate_s.place [261 * wdp, 335 * wdp]
		@next_p = @next_s.place [296 * wdp, 335 * wdp]
		selectedShip = Game.mine.ships.aircraftCarrier
		selectedShip.visible = true
		selectedShip.position = selectedShip.boundary[selectedShip.orientation].topLeft
		prevPos = null
		class shipMover
			@moveto: (endPos) =>
				startPos = @currentPos
				@currentPos = endPos
				delta = endPos.subtract startPos
				view.onFrame = (e) ->
					if e.time > 0.2
						view.onFrame = null
						selectedShip.position = endPos
					else
						selectedShip.position = startPos.add delta.multiply easeInOut e.time / 0.2
			@moveBy: (delta) =>
				return unless @currentPos.add(delta).isInside selectedShip.boundary[selectedShip.orientation]
				@moveto @currentPos.add delta
				prevPos = prevPos.add delta
			@rotate: =>
				return if view.onFrame?
				validator.removeInvalidRedBacks()
				startPos = new paper.Point @currentPos
				endPos =  new paper.Point @currentPos
				if selectedShip.size % 2 is 0
					endPos = endPos.add if selectedShip.orientation is "horizontal" then [15 * wdp, 15 * wdp] else [-15 * wdp, -15 * wdp]
				newBoundary = if selectedShip.orientation is "horizontal" then selectedShip.boundary.vertical else selectedShip.boundary.horizontal
				endPos.x = newBoundary.left if endPos.x < newBoundary.left
				endPos.x = newBoundary.right if endPos.x > newBoundary.right
				endPos.y = newBoundary.top if endPos.y < newBoundary.top
				endPos.y = newBoundary.bottom if endPos.y > newBoundary.bottom
				@currentPos = endPos
				delta = endPos.subtract startPos
				transformMatrix = new paper.Matrix()
				selectedShip.orientation = if selectedShip.orientation is "horizontal" then "vertical" else "horizontal"
				view.onFrame = (e) ->
					selectedShip.rotate -transformMatrix.rotation
					transformMatrix = new paper.Matrix()
					if e.time > 0.2
						transformMatrix.rotate 90
						selectedShip.rotate transformMatrix.rotation
						selectedShip.position = endPos
						validator.addInvalidRedBacks()
					else
						transformMatrix.rotate 90 * easeInOut e.time / 0.2
						selectedShip.rotate transformMatrix.rotation
						selectedShip.position = startPos.add delta.multiply easeInOut e.time / 0.2
						startPos.add delta.multiply easeInOut e.time / 0.2
		class validator
			@shipsAt: (coordinates, ships) ->
				ret = []
				testPos = coordinates.multiply(30).subtract([135, 135]).multiply wdp
				for ship in ships ? (_.filter (for str, ship of Game.mine.ships then ship), (ship) -> ship.visible)
					ret.push ship if testPos.isInside ship.gridBounds()
				ret
			@shipsOverlapping: (ship) ->
				ret = []
				for ship1 in (_.filter (for str, ship1 of Game.mine.ships then ship1), (ship1) -> ship1.visible)
					continue if ship is ship1
					ret.push ship1 if ship.gridBounds().intersects ship1.gridBounds()
				ret
			@shipsTouching: (ship) ->
				ret = []
				for ship1 in (_.filter (for str, ship1 of Game.mine.ships then ship1), (ship1) -> ship1.visible)
					continue if ship is ship1
					intsec = ship.gridBounds().intersect ship1.gridBounds()
					ret.push ship1 if (intsec.width is 0 and intsec.height > 0) or (intsec.height is 0 and intsec.width > 0)
				ret
			@invalidCoordinates: =>
				allShips = _.filter (for str, ship of Game.mine.ships then ship), (ship) -> ship.visible
				overlappingShips = _.union _.map(allShips, @shipsOverlapping)...
				touchingShips = _.union _.map(allShips, @shipsTouching)...
				invalidShips = _.union overlappingShips, touchingShips
				allCoordinates = _.flatten(for i in [0...10] then for j in [0...10] then new paper.Point [i, j])
				_.filter allCoordinates, (coordinates) => @shipsAt(coordinates, invalidShips).length > 0
			@removeInvalidRedBacks: ->
				redBack.remove() for redBack in _.clone Game.mine.board.back.children
			@addInvalidRedBacks: =>
				Game.mine.board.back.activate()
				canvasThis.redBack_s.place coordinates.multiply(30).subtract([135, 135]).multiply wdp for coordinates in @invalidCoordinates()
				redBack.opacity = 0 for redBack in Game.mine.board.back.children
				view.onFrame = (e) ->
					if e.time > 0.2
						redBack.opacity = 1 for redBack in Game.mine.board.back.children
						view.onFrame = null
					else
						redBack.opacity = easeInOut e.time / 0.2 for redBack in Game.mine.board.back.children
		roundCoordinates = (point) -> new paper.Point
			x: Math.round point.x
			y: Math.round point.y
		placeTool = new paper.Tool()
		placeTool.maxDistance = 30 * wdp
		shipMover.currentPos = selectedShip.position
		placeTool.onMouseDown = (e) =>
			prevPos = null
			if e.point.isInside @rotate_p.bounds
				shipMover.rotate()
				@rotate_s.mouseDown()
			else if e.point.isInside @next_p.bounds
				if !Game.mine.ships.destroyer.visible
					selectedShip.deselect()
					validator.removeInvalidRedBacks()
					if !Game.mine.ships.battleShip.visible
						selectedShip = Game.mine.ships.battleShip
					else if !Game.mine.ships.submarine.visible
						selectedShip = Game.mine.ships.submarine
					else if !Game.mine.ships.cruiser.visible
						selectedShip = Game.mine.ships.cruiser
					else if !Game.mine.ships.destroyer.visible
						selectedShip = Game.mine.ships.destroyer
					selectedShip.visible = true
					selectedShip.position = selectedShip.boundary[selectedShip.orientation].topLeft
					shipMover.currentPos = selectedShip.position
					validator.addInvalidRedBacks()
				else
					return showDialog "Ships cannot touch or overlap each other." if Game.mine.board.back.children.length > 0
					# Done setting ships
					$("#setupShipsOverlay").css "display", "none"
					selectedShip.deselect()
					inactiveTool.activate()
					layout = {}
					for str, ship of Game.mine.ships then layout[str] =
						coordinates: roundCoordinates ship.bounds.topLeft.divide(wdp).add([135, 135]).divide 30
						orientation: ship.orientation
					socket.emit "setShips", layout
					showFriendPlacingMenu()
					@next_p.remove()
					@rotate_p.remove()
					mainLayer.activate()
					Game.yours.board.placed = Game.yours.board.symbol.place [160 * wdp, 260 * wdp]
					Game.yours.board.placed.scale 0.3, [160 * wdp, 410 * wdp]
					Game.mine.board.back.addChild @redCursor
				@next_s.mouseDown()
			else
				for str, ship of Game.mine.ships
					continue if selectedShip is ship
					if ship.visible and e.point.subtract(Game.mine.board.position()).isInside ship.gridBounds()
						selectedShip.deselect()
						selectedShip = ship
						selectedShip.select()
						shipMover.currentPos = selectedShip.position
						return placeTool.onMouseDown e
				validator.removeInvalidRedBacks()
				prevPos = e.downPoint
		placeTool.onMouseDrag = (e) ->
			return if prevPos is null
			delta = e.point.subtract prevPos
			shipMover.moveBy [30 * wdp, 0] if delta.x >= 30 * wdp
			shipMover.moveBy [-30 * wdp, 0] if delta.x <= -30 * wdp
			shipMover.moveBy [0, 30 * wdp] if delta.y >= 30 * wdp
			shipMover.moveBy [0, -30 * wdp] if delta.y <= -30 * wdp
		placeTool.onMouseUp = (e) =>
			@rotate_s.mouseUp()
			@next_s.mouseUp()
			if prevPos?
				clearTimeout @va
				@va = async 200, validator.addInvalidRedBacks
		placeTool.activate()
	
	# The Game
	do =>
		activateYours = (e) =>
			mainLayer.activate()
			if e.time > 0.2
				view.onFrame = null
				Game.mine.board.placed.remove()
				Game.mine.board.placed = Game.mine.board.symbol.place [160 * wdp, 160 * wdp]
				Game.mine.board.placed.scale 0.3, [160 * wdp, 10 * wdp]
				Game.yours.board.placed.remove()
				Game.yours.board.placed = Game.yours.board.symbol.place [160 * wdp, 260 * wdp]
				Game.yours.board.placed.scale 1, [160 * wdp, 410 * wdp]
			else
				Game.mine.board.placed.remove()
				Game.mine.board.placed = Game.mine.board.symbol.place [160 * wdp, 160 * wdp]
				Game.mine.board.placed.scale 1.0 - 0.7 * easeInOut(e.time / 0.2), [160 * wdp, 10 * wdp]
				Game.yours.board.placed.remove()
				Game.yours.board.placed = Game.yours.board.symbol.place [160 * wdp, 260 * wdp]
				Game.yours.board.placed.scale 1.0 - 0.7 * easeInOut(1 - e.time / 0.2), [160 * wdp, 410 * wdp]

		activateMine = (e) =>
			mainLayer.activate()
			if e.time > 0.2
				view.onFrame = null
				Game.yours.board.placed.remove()
				Game.yours.board.placed = Game.yours.board.symbol.place [160 * wdp, 260 * wdp]
				Game.yours.board.placed.scale 0.3, [160 * wdp, 410 * wdp]
				Game.mine.board.placed.remove()
				Game.mine.board.placed = Game.mine.board.symbol.place [160 * wdp, 160 * wdp]
				Game.mine.board.placed.scale 1, [160 * wdp, 10 * wdp]
			else
				Game.yours.board.placed.remove()
				Game.yours.board.placed = Game.yours.board.symbol.place [160 * wdp, 260 * wdp]
				Game.yours.board.placed.scale 1.0 - 0.7 * easeInOut(e.time / 0.2), [160 * wdp, 410 * wdp]
				Game.mine.board.placed.remove()
				Game.mine.board.placed = Game.mine.board.symbol.place [160 * wdp, 160 * wdp]
				Game.mine.board.placed.scale 1.0 - 0.7 * easeInOut(1 - e.time / 0.2), [160 * wdp, 10 * wdp]
	
		class gridHelper
			@coordinatesFromMouse: (player, point) ->
				coord = point.subtract(Game[player].board.position()).divide(wdp).add([135, 135]).divide(30)
				coord.x = Math.round coord.x
				coord.y = Math.round coord.y
				coord
			@gridPositionFromCoordinates: (coordinates) ->
				coordinates.multiply(30).subtract([135, 135]).multiply wdp
			@gridBoundsFromCoordinates: (coordinates) ->
				point = @gridPositionFromCoordinates coordinates
				new paper.Rectangle
					x: point.x - 15 * wdp
					y: point.y - 15 * wdp
					width: 30 * wdp
					height: 30 * wdp
	
		activeTool = new paper.Tool()
		cursorOn = false
		activeTool.onMouseDown = (e) =>
			coordinates = gridHelper.coordinatesFromMouse "yours", e.point
			gridPosition = gridHelper.gridPositionFromCoordinates coordinates
			if _(Game.yours.board.back.children).any((x) =>
				x.symbol? and x.symbol is @redBack_s and e.point.subtract(Game.yours.board.position()).isInside x.bounds)
				cursorOn = false
				view.onFrame = null
				@cursor.remove()
			else if cursorOn and e.point.subtract(Game.yours.board.position()).isInside @cursor.bounds
				cursorOn = false
				view.onFrame = null
				@cursor.remove()
				inactiveTool.activate()
				_.chain(Game.yours.board.front.children)
					.filter((x) -> x.symbol? and x.symbol is @flag_s and gridPosition.isInside x.bounds)
					.each (x) -> x.remove()
				Game.yours.board.back.activate()
				@redBack_s.place gridPosition
				socket.emit "kaboom", coordinates, (result) =>
					return if !result?
					switch result.result
						when "hit"
							Game.yours.board.front.activate()
							@shot_s.place gridPosition
						when "sunk"
							ship = Game.yours.ships[result.ship.type]
							ship.rotate 90 if result.ship.orientation is "vertical"
							ship.orientation = result.ship.orientation
							shipCoords = new paper.Point(result.ship.coordinates)
							if result.ship.orientation is "horizontal"
								shipCoords.x += (ship.size - 1) / 2
							else
								shipCoords.y += (ship.size - 1) / 2
							ship.position = gridHelper.gridPositionFromCoordinates shipCoords
							ship.visible = true
						when "gameOver"
							gotoGameOverMenu "You Won! :D", "center"
					async 1000, if result.result is "miss" then yourTurn else if result.result isnt "gameOver" then do => activeTool.activate()
					view.draw()
			else
				cursorOn = true
				Game.yours.board.back.addChild @cursor
				@cursor.position = gridPosition
				flags = _(Game.yours.board.front.children).filter((x) => x.symbol? and x.symbol is @flag_s and gridPosition.isInside x.bounds)
				if flags.length is 0
					Game.yours.board.front.activate()
					@flag_s.place gridPosition
				else
					_(flags).each (x) -> x.remove()
				view.onFrame = (e) =>
					if e.time > 0.5
						view.onFrame = null
						cursorOn = false
						@cursor.remove()
					else
						@cursor.opacity = 1 - easeInOut e.time / 0.5
		
		myTurn = ->
			hideFriendPlacingMenu()
			view.onFrame = activateYours
			activeTool.activate()
		
		yourTurn = ->
			hideFriendPlacingMenu()
			view.onFrame = activateMine
			inactiveTool.activate()
		
		socket.on "yourTurn", myTurn
		socket.on "theirTurn", yourTurn
		
		socket.on "shotAt", (data) =>
			gridPosition = gridHelper.gridPositionFromCoordinates new paper.Point data.shotAt
			Game.mine.board.back.activate()
			@redBack_s.place gridPosition
			@redCursor.position = gridPosition
			@redCursor.show()
			switch data.result.result
				when "hit"
					Game.mine.board.front.activate()
					@redShot_s.place gridPosition
				when "sunk"
					Game.mine.ships[data.result.ship.type].sunk()
				when "gameOver"
					gotoGameOverMenu "You Lost! :(", "center"
			async 1000, if data.result.result is "miss" then myTurn
			view.draw()
	
	view.draw()

$(document).ready ->
	setupPage()
	setupEvents()
