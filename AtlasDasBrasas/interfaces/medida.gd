extends Control

signal selected(quantity:int)
var minimum=0
var maximum=20
var value=0

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var fraction=clampf((event.position.x-8)/(size.x-16),0,1)
		selected.emit(roundi(lerpf(minimum,maximum,fraction)))
		accept_event()

func _draw():
	var span=size.x-16
	var base=Color("#495a63")
	for i in range(minimum,maximum+1):
		var x=8+span*float(i-minimum)/maxi(1,maximum-minimum)
		var major=i%5==0 or i in [minimum,maximum]
		var tint=Color("#eec48a") if i<=value else base
		draw_line(Vector2(x,2),Vector2(x,15 if major else 9),tint,2)
		if major:draw_string(preload("res://interfaces/LiberationSans-Regular.ttf"),Vector2(x-16,31),str(i),HORIZONTAL_ALIGNMENT_CENTER,32,13,Color("#b9c8c8"))
