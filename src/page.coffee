easeInOut = (x) -> Math.pow (Math.sin((x - 0.5) * Math.PI) + 1) * 0.5, 2

async = (a, b) ->
	if b?
		setTimeout b, a
	else
		setTimeout a, 0

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

socket = io.connect()

socket.on "connect", -> pleaseWait.hide()
socket.on "friendJoined", -> setupGame()
socket.on "friendDisconnected", -> gotoGameOverMenu "Your friend has left the game."

window.onpopstate = (e) ->
	if !e.state?
		pleaseWait.show()
		socket.emit "resetAll", -> pleaseWait.hide()
		async 550, -> setupCanvas reset: true
		$("#menuView").addClass "enableTransitions"
		$("#mainMenu").removeClass "moveLeft"
		$("#mainMenu").removeClass "moveRight"
		$("#newMenu").addClass "moveRight"
		$("#joinMenu").addClass "moveRight"
		$("#gameOverMenu").addClass "moveLeft"
		$("#menuViewContainer").addClass "enableTransitions"
		$("#menuViewContainer").removeClass "moveDown"
	else if e.state.state is "newMenu"
		$("#menuView").removeClass "enableTransitions"
		$("#mainMenu").addClass "moveLeft"
		$("#newMenu").removeClass "moveRight"
		$("#joinMenu").addClass "moveRight"
	else if e.state.state is "joinMenu"
		$("#menuView").removeClass "enableTransitions"
		$("#mainMenu").addClass "moveLeft"
		$("#newMenu").addClass "moveRight"
		$("#joinMenu").removeClass "moveRight"
	else if e.state.state is "setupShips"
		$("#menuView").removeClass "enableTransitions"
		$("#menuView").addClass "moveDown"
		setupCanvas setupShips: e.state.board

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
	paper.setup document.getElementById "canvas"
	
	$("html, body").css "width", 320 * wdp
	$("html, body").css "height", 416 * wdp

	$("#menuView").css "-webkit-transform", "scale(#{wdp})"
	$("#menuView").css "display", "block"
	
	$("#pleaseWait div.container div.spinner").css "width", "#{60 * wdp}px"
	$("#pleaseWait div.container div.spinner").css "height", "#{60 * wdp}px"
	$("#pleaseWait div.container").css "padding", "#{1.5 * wdp}em #{1.5 * wdp}em #{1.25 * wdp}em"
	$("#pleaseWait div.container").css "margin", "#{153 * wdp}px #{112 * wdp}px"
	
	$("#gameId_Entry").focusout -> window.scrollTo 0, 1

setupEvents = ->
	bindMouseDown "#newGame_btn", (e) ->
		pleaseWait.show()
		socket.emit "newGame", (data) ->
			if data? and data.status is "Game created"
				$("#gameId").text data.id
				$("#menuView").addClass "enableTransitions"
				$("#mainMenu").addClass "moveLeft"
				$("#newMenu").removeClass "moveRight"
				history.pushState state: "newMenu", "", ""
			else
				alert "Could not create game."
				socket = io.connect()
			pleaseWait.hide()
	
	bindMouseDown "#joinGame_btn", (e) ->
		$("#gameId_entry").text ""
		$("#menuView").addClass "enableTransitions"
		$("#mainMenu").addClass "moveLeft"
		$("#joinMenu").removeClass "moveRight"
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

setupGame = ->
	async 550, ->
		$("#menuView").removeClass "enableTransitions"
		$("#newMenu").addClass "moveRight"
		$("#joinMenu").addClass "moveRight"
		$("#mainMenu").removeClass "moveLeft"
	$("#menuViewContainer").addClass "enableTransitions"
	$("#menuViewContainer").addClass "moveDown"
	setupCanvas setupShips: null
	history.replaceState state: "setupShips", "", ""

gotoGameOverMenu = (msg) ->
	$("#gameOver_msg").text msg ? "Something's happened."
	async 550, -> setupCanvas reset: true
	$("#menuView").removeClass "enableTransitions"
	$("#mainMenu").removeClass "moveLeft"
	$("#mainMenu").addClass "moveRight"
	$("#newMenu").addClass "moveRight"
	$("#joinMenu").addClass "moveRight"
	$("#gameOverMenu").removeClass "moveLeft"
	$("#menuViewContainer").addClass "enableTransitions"
	$("#menuViewContainer").removeClass "moveDown"
	history.replaceState null, "", ""

setupCanvas = (data) ->
	mainLayer = project.activeLayer
	mainLayer.children[0].remove() while mainLayer.children.length > 0
	return $("#canvas").css "display", "none" if data.reset? and data.reset
	
	$("#canvas").css "display", "block"
	view.draw()
	
	class Game
		class @Board
			symbol: null
			placed: null
			back: null
			front: null
		class @Ships
			aircraftCarrier: null
			battleShip: null
			submarine: null
			cruiser: null
			destroyer: null
		class @Player
			board: new Game.Board()
			ships: new Game.Ships()
		@mine: new Game.Player()
		@yours: new Game.Player()
	
	# Basic Grid Layer
	do =>
		lstyle =
			strokeColor: "white"
			strokeWidth: 2 * wdp
			strokeCap: "round"
		vline = new Path()
		vline.style = lstyle
		vline.add [0, 0]
		vline.add [0, 300 * wdp]
		vline_s = new Symbol vline
		vlines = for i in [0..10]
			vline_s.place [i * 30 * wdp, 150 * wdp]
		hline = new Path()
		hline.style = lstyle
		hline.add [0, 0]
		hline.add [300 * wdp, 0]
		hline_s = new Symbol hline
		hlines = for i in [0..10]
			hline_s.place [150 * wdp, i * 30 * wdp]
		gridl = new Group vlines
		gridl.addChildren hlines
		@gridl_s = new Symbol gridl
	
	# Mine — Group
	do =>
		Game.mine.board.back = new Layer()
		mainLayer.activate()
		mineGrid = gridl_s.place()
		Game.mine.board.front = new Layer()
		mainLayer.activate()
		mine = new Group [Game.mine.board.back, mineGrid, Game.mine.board.front]
		Game.mine.board.symbol = new Symbol mine
	
	# Yours — Group
	do =>
		Game.yours.board.back = new Layer()
		mainLayer.activate()
		yoursGrid = gridl_s.place()
		Game.yours.board.front = new Layer()
		mainLayer.activate()
		yours = new Group [Game.yours.board.back, yoursGrid, Game.yours.board.front]
		Game.yours.board.symbol = new Symbol yours
		# yours_p = yours_s.place [160 * wdp, 260 * wdp]
		# yours_p.scale 0.3, [160 * wdp, 410 * wdp]
	
	# Rotate Button
	do =>
		box = new Path.Rectangle [-14 * wdp, -14 * wdp], [28 * wdp, 28 * wdp]
		box.style =
			fillColor: "white"
			strokeWidth: 2 * wdp
			strokeColor: "white"
			strokeCap: "square"
		arc = new Path.Circle [0, 0], 6 * wdp
		arc.style =
			strokeColor: "black"
			strokeWidth: 3 * wdp
			strokeCap: "round"
		arc.closed = false
		arc.rotate -90
		arrow = new Path [[1 * wdp, 0], [11 * wdp, 0], [6 * wdp, 5 * wdp]]
		arrow.style = fillColor: "black"
		arrow.closePath()
		rotate = new Group [box, arc, arrow]
		@rotate_s = new Symbol rotate
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
		box = new Path.Rectangle [-14 * wdp, -14 * wdp], [28 * wdp, 28 * wdp]
		box.style =
			fillColor: "white"
			strokeWidth: 2 * wdp
			strokeColor: "white"
			strokeCap: "square"
		arrow = new Path [[-3 * wdp, -8 * wdp], [7 * wdp, 0], [-3 * wdp, 8 * wdp]]
		arrow.style = fillColor: "black"
		arrow.closePath()
		next = new Group [box, arrow]
		@next_s = new Symbol next
		@next_s.mouseDown = ->
			box.fillColor = "black"
			arc.strokeColor = "white"
			arrow.fillColor = "white"
		@next_s.mouseUp = ->
			box.fillColor = "white"
			arc.strokeColor = "black"
			arrow.fillColor = "black"
	
	# Generic Ship
	makeShip = (n) ->
		line = new Path [[0, 0], [150 * wdp, 0]]
		line.style =
			strokeColor: "white"
			strokeWidth: 10 * wdp
			strokeCap: "round"
		select = new Path [[0, 0], [150 * wdp, 0]]
		select.style =
			strokeColor: "cyan"
			strokeWidth: 10 * wdp
			strokeCap: "round"
		select.strokeColor.alpha = 0
		ship = new Group [line, select]
		ship.select = ->
			select.visible = true
		ship.deselect = ->
			select.visible = false
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
	
	# Setup Ships
	do =>
		Game.mine.board.placed = Game.mine.board.symbol.place [160 * wdp, 160 * wdp]
		@rotate_p = @rotate_s.place [260 * wdp, 335 * wdp]
		@next_p = @next_s.place [295 * wdp, 335 * wdp]
	
	activateYours = (e) =>
		if e.time > 0.2
			view.onFrame = null
			@mine_p.remove()
			@mine_p = mine_s.place [160 * wdp, 160 * wdp]
			@mine_p.scale 0.3, [160 * wdp, 10 * wdp]
			@yours_p.remove()
			@yours_p = yours_s.place [160 * wdp, 260 * wdp]
			@yours_p.scale 1, [160 * wdp, 410 * wdp]
		else
			@mine_p.remove()
			@mine_p = mine_s.place [160 * wdp, 160 * wdp]
			@mine_p.scale 1.0 - 0.7 * easeInOut(e.time / 0.2), [160 * wdp, 10 * wdp]
			@yours_p.remove()
			@yours_p = yours_s.place [160 * wdp, 260 * wdp]
			@yours_p.scale 1.0 - 0.7 * easeInOut(1 - e.time / 0.2), [160 * wdp, 410 * wdp]

	activateMine = (e) =>
		if e.time > 0.2
			view.onFrame = null
			@yours_p.remove()
			@yours_p = yours_s.place [160 * wdp, 260 * wdp]
			@yours_p.scale 0.3, [160 * wdp, 410 * wdp]
			@mine_p.remove()
			@mine_p = mine_s.place [160 * wdp, 160 * wdp]
			@mine_p.scale 1, [160 * wdp, 10 * wdp]
		else
			@yours_p.remove()
			@yours_p = yours_s.place [160 * wdp, 260 * wdp]
			@yours_p.scale 1.0 - 0.7 * easeInOut(e.time / 0.2), [160 * wdp, 410 * wdp]
			@mine_p.remove()
			@mine_p = mine_s.place [160 * wdp, 160 * wdp]
			@mine_p.scale 1.0 - 0.7 * easeInOut(1 - e.time / 0.2), [160 * wdp, 10 * wdp]

	###
	tool1 = new Tool()
	tool1.onMouseDown = (e) ->
		view.onFrame = activateYours
		tool2.activate()

	tool2 = new Tool()
	tool2.onMouseDown = (e) ->
		view.onFrame = activateMine
		tool1.activate()
	tool1.activate()
	###
	
	view.draw()

$(document).ready ->
	setupPage()
	setupEvents()