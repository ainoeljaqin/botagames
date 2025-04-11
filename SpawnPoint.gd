extends Marker2D

@export var spawn_id = "default"
@export var facing_direction = Vector2.DOWN

# Visual indicator for editor
@export var editor_color = Color(0, 1, 0, 0.5)

func _ready():
	# Check if this is the spawn point we need to use
	if GameData.transitioning and GameData.spawn_id == spawn_id:
		call_deferred("_position_player")

func _position_player():
	# Wait a frame to ensure scene is fully loaded
	await get_tree().idle_frame
	
	# Find the player node
	var player = null
	
	# Try to find player in YSort
	var ysort = get_node_or_null("/root/World/Node2D")
	if ysort and ysort.has_node("Player"):
		player = ysort.get_node("Player")
	else:
		# Fallback: try to find player anywhere in the scene
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			player = get_node_or_null("/root/World/Node2D/Player")
	
	if player:
		# Position player at spawn point
		player.global_position = global_position
		
		# Set player direction
		if player.has_node("HitboxPivot/SwordHitbox"):
			player.get_node("HitboxPivot/SwordHitbox").knockback_vector = GameData.player_direction
			
		# Update animation based on direction
		player.update_animation(GameData.player_direction, true)
		
		# Restore player health
		player.stats.health = GameData.player_health
		
		# Reset transition flag
		GameData.transitioning = false

# Draw visual helper in editor
func _draw():
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 8, editor_color)
		# Draw direction indicator
		var line_end = facing_direction * 16
		draw_line(Vector2.ZERO, line_end, Color.WHITE, 2)
