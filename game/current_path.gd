@tool
class_name CurrentPath
extends Path2D
## A water current. Draw its curve in the editor (select the node, then use the curve tools
## in the toolbar to add / move points and drag the handles). Water flows from the first
## point to the last. Put it under the level root. Chain several to make a highway.

@export var width := 160.0:  # half-width of the stream
	set(v):
		width = v
		queue_redraw()
@export var strength := 900.0  # flow speed at the centre of the stream (px/s)
## Food pellets riding this current. New ones keep entering at its start (0 = none).
@export var food_count := 25


func _draw() -> void:
	if not Engine.is_editor_hint() or curve == null or curve.point_count < 2:
		return
	var pts := curve.tessellate_even_length(5, 60.0)
	draw_polyline(pts, Color(0.4, 0.9, 1.0, 0.12), width * 2.0, true)
	draw_polyline(pts, Color(0.5, 1.0, 1.0, 0.6), 4.0, true)
	# Arrowheads show the flow direction.
	for i in range(8, pts.size(), 12):
		var d := (pts[i] - pts[i - 1]).normalized()
		var p := pts[i]
		draw_line(p, p - d.rotated(0.5) * 50.0, Color(0.6, 1.0, 1.0, 0.8), 4.0)
		draw_line(p, p - d.rotated(-0.5) * 50.0, Color(0.6, 1.0, 1.0, 0.8), 4.0)
