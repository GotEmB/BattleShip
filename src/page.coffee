easeInOut = (x) -> Math.pow (Math.sin((x - 0.5) * Math.PI) + 1) * 0.5, 2

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
	if e.state is null
		pleaseWait.show()
		socket.emit "resetAll", ->
			pleaseWait.hide()
		$("#menuView").addClass "enableTransitions"
		$("#mainMenu").removeClass "moveLeft"
		$("#mainMenu").removeClass "moveRight"
		$("#newMenu").addClass "moveRight"
		$("#joinMenu").addClass "moveRight"
		$("#gameOverMenu").addClass "moveLeft"
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
		setupCanvas state: e.state.board

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
	$("#menuViewContainer").addClass "enableTransitions"
	$("#menuViewContainer").addClass "moveDown"
	setupCanvas()
	history.replaceState state: "setupShips", "", ""

gotoGameOverMenu = (msg) ->
	$("#gameOver_msg").text msg ? "Something's happened."
	setTimeout (-> setupCanvas reset: true), 350
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
	
	if data? and data.reset
		mainLayer.children[0].remove() while mainLayer.children.length > 0
		$("#canvas").css "display", "none"
		return
	
	$("#canvas").css "display", "block"
	
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
	gridl_s = new Symbol gridl

	mineBack = new Layer()
	mainLayer.activate()
	mineGrid = gridl_s.place()
	mineFront = new Layer()
	mainLayer.activate()
	mine = new Group [mineBack, mineGrid, mineFront]
	mine_s = new Symbol mine
	mine_p = mine_s.place [160 * wdp, 160 * wdp]

	yoursBack = new Layer()
	mainLayer.activate()
	yoursGrid = gridl_s.place()
	yoursFront = new Layer()
	mainLayer.activate()
	yours = new Group [yoursBack, yoursGrid, yoursFront]
	yours_s = new Symbol yours
	yours_p = yours_s.place [160 * wdp, 260 * wdp]
	yours_p.scale 0.3, [160 * wdp, 410 * wdp]

	view.draw()

	activateYours = (e) ->
		if e.time > 0.2
			view.onFrame = null
			mine_p.remove()
			mine_p = mine_s.place [160 * wdp, 160 * wdp]
			mine_p.scale 0.3, [160 * wdp, 10 * wdp]
			yours_p.remove()
			yours_p = yours_s.place [160 * wdp, 260 * wdp]
			yours_p.scale 1, [160 * wdp, 410 * wdp]
		else
			mine_p.remove()
			mine_p = mine_s.place [160 * wdp, 160 * wdp]
			mine_p.scale 1.0 - 0.7 * easeInOut(e.time / 0.2), [160 * wdp, 10 * wdp]
			yours_p.remove()
			yours_p = yours_s.place [160 * wdp, 260 * wdp]
			yours_p.scale 1.0 - 0.7 * easeInOut(1 - e.time / 0.2), [160 * wdp, 410 * wdp]

	activateMine = (e) ->
		if e.time > 0.2
			view.onFrame = null
			yours_p.remove()
			yours_p = yours_s.place [160 * wdp, 260 * wdp]
			yours_p.scale 0.3, [160 * wdp, 410 * wdp]
			mine_p.remove()
			mine_p = mine_s.place [160 * wdp, 160 * wdp]
			mine_p.scale 1, [160 * wdp, 10 * wdp]
		else
			yours_p.remove()
			yours_p = yours_s.place [160 * wdp, 260 * wdp]
			yours_p.scale 1.0 - 0.7 * easeInOut(e.time / 0.2), [160 * wdp, 410 * wdp]
			mine_p.remove()
			mine_p = mine_s.place [160 * wdp, 160 * wdp]
			mine_p.scale 1.0 - 0.7 * easeInOut(1 - e.time / 0.2), [160 * wdp, 10 * wdp]

	tool1 = new Tool()
	tool1.onMouseDown = (e) ->
		view.onFrame = activateYours
		tool2.activate()

	tool2 = new Tool()
	tool2.onMouseDown = (e) ->
		view.onFrame = activateMine
		tool1.activate()

$(document).ready ->
	setupPage()
	setupEvents()