class_name FestivalGrounds
extends RefCounted
## One continuous, bounded and navigable Festival site.

const GRID_SIZE := 40.0
const NAVIGATION_MARGIN := 18.0

var bounds := Rect2(-1100, -700, 2200, 1400)
var points: Array[FestivalPoint] = []
var obstacles: Array[Rect2] = []

func points_of_kind(kind: FestivalPoint.Kind) -> Array[FestivalPoint]:
	var result: Array[FestivalPoint] = []
	for point in points:
		if point.kind == kind:
			result.append(point)
	return result

func placement_signature() -> String:
	var parts := PackedStringArray()
	for point in points:
		parts.append("%s:%.1f:%.1f" % [point.id, point.position.x, point.position.y])
	return "|".join(parts)

func is_walkable(world_position: Vector2, margin := NAVIGATION_MARGIN) -> bool:
	if not bounds.grow(-margin).has_point(world_position):
		return false
	for obstacle in obstacles:
		if obstacle.grow(margin).has_point(world_position):
			return false
	return true

func path(from: Vector2, requested_destination: Vector2) -> Array[Vector2]:
	var start := _nearest_walkable(from)
	var destination := _nearest_walkable(requested_destination)
	var grid := _navigation_grid()
	var start_cell := _cell_for(start)
	var destination_cell := _cell_for(destination)
	var ids := grid.get_id_path(start_cell, destination_cell)
	var result: Array[Vector2] = []
	for id in ids:
		result.append(_world_for(id))
	if not result.is_empty() and is_walkable(destination):
		result.append(destination)
	return result

func _navigation_grid() -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, int(bounds.size.x / GRID_SIZE), int(bounds.size.y / GRID_SIZE))
	grid.cell_size = Vector2(GRID_SIZE, GRID_SIZE)
	grid.offset = bounds.position + Vector2.ONE * GRID_SIZE * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(grid.region.size.x):
		for y in range(grid.region.size.y):
			var cell := Vector2i(x, y)
			if not is_walkable(_world_for(cell)):
				grid.set_point_solid(cell)
	return grid

func _nearest_walkable(world_position: Vector2) -> Vector2:
	var inner := bounds.grow(-NAVIGATION_MARGIN - 1.0)
	var clamped := Vector2(
		clampf(world_position.x, inner.position.x, inner.end.x),
		clampf(world_position.y, inner.position.y, inner.end.y))
	if is_walkable(clamped):
		return clamped
	var origin := _cell_for(clamped)
	for radius in range(1, 12):
		for x in range(origin.x - radius, origin.x + radius + 1):
			for y in range(origin.y - radius, origin.y + radius + 1):
				var candidate := _world_for(Vector2i(x, y))
				if is_walkable(candidate):
					return candidate
	return Vector2.ZERO

func _cell_for(world_position: Vector2) -> Vector2i:
	var local := world_position - bounds.position
	return Vector2i(
		clampi(int(floor(local.x / GRID_SIZE)), 0, int(bounds.size.x / GRID_SIZE) - 1),
		clampi(int(floor(local.y / GRID_SIZE)), 0, int(bounds.size.y / GRID_SIZE) - 1))

func _world_for(cell: Vector2i) -> Vector2:
	return bounds.position + (Vector2(cell) + Vector2.ONE * 0.5) * GRID_SIZE
