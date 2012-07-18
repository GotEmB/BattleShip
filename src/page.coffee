easeInOut = (x) -> Math.pow (Math.sin((x - 0.5) * Math.PI) + 1) * 0.5, 2

$(document).ready ->
	window.scrollTo 0, 1	
	$(document).bind "touchmove", (e) -> e.preventDefault()
	
	wdp = window.devicePixelRatio ? 1
	viewport = document.querySelector "meta[name=viewport]"
	viewport.setAttribute 'content', "user-scalable=no, width=#{320 * wdp}, height=#{416 * wdp}, initial-scale=#{1.0 / wdp}, maximum-scale=#{1.0 / wdp}"
	canvas = document.getElementById "canvas"
	canvas.setAttribute 'width', "#{320 * wdp}"
	canvas.setAttribute 'height', "#{416 * wdp}"
	
	paper.install window
	paper.setup document.getElementById "canvas"
	
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
	
	mine = gridl_s.place [160 * wdp, 160 * wdp]
	mine_s = new Symbol mine
	mine_p = mine_s.place [160 * wdp, 160 * wdp]
	
	yours = gridl_s.place [160 * wdp, 260 * wdp]
	yours_s = new Symbol yours
	yours_p = yours_s.place [160 * wdp, 260 * wdp]
	yours_p.scale 0.3, [160 * wdp, 410 * wdp]
	
	view.draw()
	
	tool = new Tool()
	tool.onMouseDown = (e) ->
		view.onFrame = (e) ->
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
				mine_p = yours_s.place [160 * wdp, 160 * wdp]
				mine_p.scale 1.0 - 0.7 * easeInOut(e.time / 0.2), [160 * wdp, 10 * wdp]			
				yours_p.remove()
				yours_p = yours_s.place [160 * wdp, 260 * wdp]
				yours_p.scale 1.0 - 0.7 * easeInOut(1 - e.time / 0.2), [160 * wdp, 410 * wdp]