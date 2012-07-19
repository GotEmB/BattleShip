easeInOut = (x) -> Math.pow (Math.sin((x - 0.5) * Math.PI) + 1) * 0.5, 2

$(document).ready ->
	window.scrollTo 0, 1
	$(document).bind "touchmove", (e) -> e.preventDefault()
	$(document).bind "touchstart", (e) -> e.preventDefault()
	$(document).bind "touchend", (e) -> e.preventDefault()
	
	
	wdp = window.devicePixelRatio ? 1
	viewport = document.querySelector "meta[name=viewport]"
	viewport.setAttribute 'content', "user-scalable=no, width=#{320 * wdp}, height=#{416 * wdp}, initial-scale=#{1.0 / wdp}, maximum-scale=#{1.0 / wdp}"
	canvas = document.getElementById "canvas"
	canvas.setAttribute 'width', "#{320 * wdp}"
	canvas.setAttribute 'height', "#{416 * wdp}"
	
	paper.install window
	paper.setup document.getElementById "canvas"
	mainLayer = project.activeLayer
	
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