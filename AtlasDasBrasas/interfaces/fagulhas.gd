extends Control
var elapsed=0.0
func _process(dt):
	elapsed+=dt
	queue_redraw()
func _draw():
	for i in 18:
		var y=fposmod(43*i-elapsed*(3+i%3),size.y)
		var x=fposmod(67*i+sin(elapsed*.35+i)*6,size.x)
		var c=Color("#ffd795")
		c.a=.22+.20*sin(elapsed+i)
		draw_rect(Rect2(Vector2(x,y).floor(),Vector2(2,1)),c)
