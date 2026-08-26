class_name PixelArt
extends RefCounted
## Shared integer-grid drawing primitives for the original placeholder art.

const INK := Color("172038")
const SKIN := Color("f2b99b")
const PLAYER := Color("45a7ff")
const FRIENDS := [Color("f06fae"), Color("ffd166"), Color("73d2de"), Color("b693ef")]

static func person(canvas: CanvasItem, color: Color, effect := Color.TRANSPARENT) -> void:
	canvas.draw_rect(Rect2(-8, -15, 16, 4), INK)
	canvas.draw_rect(Rect2(-6, -13, 12, 9), SKIN)
	canvas.draw_rect(Rect2(-8, -4, 16, 13), color)
	canvas.draw_rect(Rect2(-8, 9, 6, 7), INK)
	canvas.draw_rect(Rect2(2, 9, 6, 7), INK)
	canvas.draw_rect(Rect2(-12, -2, 4, 9), SKIN)
	canvas.draw_rect(Rect2(8, -2, 4, 9), SKIN)
	if effect.a > 0.0:
		canvas.draw_rect(Rect2(-15, -18, 30, 36), effect, false, 2.0)

static func facility(canvas: CanvasItem, kind: FestivalPoint.Kind, color: Color) -> void:
	canvas.draw_rect(Rect2(-16, -16, 32, 32), INK)
	canvas.draw_rect(Rect2(-13, -13, 26, 26), color)
	match kind:
		FestivalPoint.Kind.WATER:
			canvas.draw_rect(Rect2(-4, -9, 8, 18), Color.WHITE)
			canvas.draw_rect(Rect2(4, -7, 7, 5), Color.WHITE)
		FestivalPoint.Kind.TOILET:
			canvas.draw_rect(Rect2(-7, -9, 14, 5), Color.WHITE)
			canvas.draw_rect(Rect2(-5, -4, 10, 13), Color.WHITE)
		FestivalPoint.Kind.FIRST_AID:
			canvas.draw_rect(Rect2(-4, -10, 8, 20), Color.WHITE)
			canvas.draw_rect(Rect2(-10, -4, 20, 8), Color.WHITE)
		FestivalPoint.Kind.VENDOR, FestivalPoint.Kind.LATE_VENDOR:
			canvas.draw_rect(Rect2(-11, -9, 22, 6), Color("fff3c4"))
			canvas.draw_rect(Rect2(-8, 1, 16, 9), Color("713f2a"))
		FestivalPoint.Kind.CAMP, FestivalPoint.Kind.CAMPSITE_AREA:
			canvas.draw_colored_polygon(PackedVector2Array([-12, 10, 0, -11, 12, 10]), Color("fff3c4"))
			canvas.draw_rect(Rect2(-2, 2, 4, 8), INK)
