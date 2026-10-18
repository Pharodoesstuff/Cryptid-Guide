class_name LevelTileMap extends TileMapLayer #Using tilemaplaayer cuz tilemap is deprciated


func _ready() -> void:
	LevelManager.ChangeTilemapBounds( GetTilemapBounds() )
	pass # 

#honestly I have no idea
func GetTilemapBounds() -> Array[ Vector2 ]:
	var bounds : Array[ Vector2 ] = []
	bounds.append(
		Vector2( get_used_rect().position * rendering_quadrant_size )
	)
	bounds.append(
		Vector2( get_used_rect().end * rendering_quadrant_size)
	)
	return bounds
