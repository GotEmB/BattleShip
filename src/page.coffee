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
	path = new Path()
	tool = new Tool()
	tool.minDistance = 1
	tool.maxDistance = 5
	
	tool.onMouseDown = (e) ->
		path = new Path()
		path.strokeColor = "white"
		path.strokeWidth = 2 * wdp
		path.strokeCap = "round"
		
	tool.onMouseDrag = (e) -> path.add e.point
	
	tool.onMouseUp = (e) -> path.simplify()