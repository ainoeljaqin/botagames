extends Area2D

@export var target_scene # (String, FILE, "*.tscn")
@export var spawn_id = "default"

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	
func _on_body_entered(body):
	if body.name == "Player":
		# Don't transition if already in progress
		if GameData.transitioning:
			return
			
		# Save player state
		GameData.transitioning = true
		GameData.spawn_id = spawn_id
		GameData.player_health = body.stats.health
		
		# If using knockback vector for direction, save that too
		if body.has_node("HitboxPivot/SwordHitbox"):
			GameData.player_direction = body.get_node("HitboxPivot/SwordHitbox").knockback_vector
			
		# Transition to new scene
		var err = get_tree().change_scene_to_file(target_scene)
		if err != OK:
			print("Error changing scene: ", err)
			GameData.transitioning = false
