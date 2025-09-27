extends Node
class_name PlacementValidator

# Tracks which tiles are occupied
var occupancy := {}  # Dictionary: Vector2i -> bool

func is_placement_valid(anchor: Vector2i, size: int, tilemap_layer: TileMapLayer) -> bool:
	for x in range(size):
		for y in range(size):
			var pos = anchor + Vector2i(x, y)
			
			# Check if the cell exists in the TileMapLayer
			if tilemap_layer.get_cell_source_id(pos) == -1:
				return false
			
			# Get the tile data for custom properties
			var tile_data = tilemap_layer.get_cell_tile_data(pos)
			if tile_data == null or not tile_data.get_custom_data("isBuildable"):
				return false
			
			# Check if position is already occupied
			if occupancy.has(pos):
				return false
	
	return true

func mark_occupied(anchor: Vector2i, size: int) -> void:
	for x in range(size):
		for y in range(size):
			occupancy[anchor + Vector2i(x, y)] = true

func mark_unoccupied(anchor: Vector2i, size: int) -> void:
	for x in range(size):
		for y in range(size):
			occupancy.erase(anchor + Vector2i(x, y))

func is_occupied(pos: Vector2i) -> bool:
	return occupancy.has(pos)

func clear_occupancy() -> void:
	occupancy.clear()
