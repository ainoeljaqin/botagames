extends CharacterBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

@export var ACCELERATION: float = 300.0
@export var MAX_SPEED: float = 50.0
@export var FRICTION: float = 200.0
@export var WANDER_TARGET_RANGE: float = 4.0

enum {
	IDLE,
	WANDER,
	CHASE,
	ATTACK
}

# Jangan mendeklarasikan properti velocity karena sudah ada pada CharacterBody2D.
var knockback: Vector2 = Vector2.ZERO
var state: int = IDLE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2
@onready var stats = $Stats
@onready var playerDetectionZone = $PlayerDetectionZone
@onready var hurtbox = $Hurtbox
@onready var softCollision = $SoftCollision
@onready var wanderController = $WanderController

func _ready() -> void:
	state = pick_random_state([IDLE, WANDER])

func _physics_process(delta: float) -> void:
	# Mengurangi efek knockback secara bertahap
	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	velocity = knockback
	move_and_slide()
	knockback = velocity
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
			play_animation("idle")
		
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()
			accelerate_towards_point(wanderController.target_position, delta)
			update_walk_animation()  # Update animasi berjalan sesuai arah
			
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				update_wander()
		
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
				update_walk_animation()  # Update animasi berjalan saat mengejar
				if should_attack(player):
					state = ATTACK
			else:
				state = IDLE

		ATTACK:
			play_animation("attack_side")  # Mainkan animasi serangan
			# Tambahkan logika serangan di sini (misal: pengurangan nyawa)
			await get_tree().create_timer(1.0).timeout
			state = CHASE

	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400
		
	# Perbarui pergerakan berdasarkan velocity yang dihitung
	velocity = velocity
	move_and_slide()
	velocity = velocity

func accelerate_towards_point(point: Vector2, delta: float) -> void:
	var direction: Vector2 = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)

func update_walk_animation() -> void:
	# Tentukan animasi berdasarkan arah pergerakan
	if abs(velocity.x) > abs(velocity.y):
		if velocity.x > 0:
			play_animation("goblin-walk-right")
		else:
			play_animation("goblin-walk-left")
	else:
		if velocity.y > 0:
			play_animation("goblin-walk-front")
		else:
			play_animation("goblin-walk-back")

func update_wander() -> void:
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(randf_range(1, 3))

func seek_player() -> void:
	if playerDetectionZone.can_see_player():
		state = CHASE

func should_attack(player) -> bool:
	return global_position.distance_to(player.global_position) <= 50  # Contoh jarak serang

func play_animation(animation_name: String) -> void:
	if not sprite.is_playing() or sprite.animation != animation_name:
		sprite.play(animation_name)

func pick_random_state(state_list: Array) -> int:
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area) -> void:
	stats.health -= area.damage
	knockback = area.knockback_vector * 120
	hurtbox.create_hit_effect()

func _on_Stats_no_health() -> void:
	queue_free()
	var effect_instance = EnemyDeathEffect.instantiate()
	get_parent().add_child(effect_instance)
	effect_instance.global_position = global_position
