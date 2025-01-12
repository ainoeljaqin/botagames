extends KinematicBody2D

const deathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 500
export var MAX_SPEED = 70
export var FRICTION = 500

enum {
	MOVE,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var stats = PlayerStats

onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var animatedSprite = $AnimatedSprite

func _ready():
	randomize()
	stats.connect("no_health", self, "queue_free")
	animatedSprite.play("kyle-idle-front")  # Set animasi default
	animatedSprite.connect("animation_finished", self, "_on_animation_finished")

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		ATTACK:
			attack_state(delta)

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		swordHitbox.knockback_vector = input_vector
		update_animation(input_vector, false)
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		update_animation(swordHitbox.knockback_vector, true)
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move()

	if Input.is_action_just_pressed("attack"):
		if state == MOVE:  # Hanya bisa menyerang saat di MOVE
			state = ATTACK
			start_attack_animation()

func attack_state(delta):
	velocity = Vector2.ZERO
	# Menunggu animasi selesai sebelum transisi ke MOVE

func move():
	velocity = move_and_slide(velocity)

func start_attack_animation():
	var direction = get_direction(swordHitbox.knockback_vector)
	animatedSprite.play("kyle-basic-attack-" + direction)

	# Set durasi serangan dengan timer
	var attack_duration = 0.5  # Sesuaikan dengan durasi animasi serangan
	yield(get_tree().create_timer(attack_duration), "timeout")
	state = MOVE

func _on_animation_finished():
	if state == ATTACK:
		state = MOVE

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invincibility(0.5)
	hurtbox.create_hit_effect()

func update_animation(input_vector, is_idle):
	if is_idle:
		# Animasi idle berdasarkan arah terakhir
		animatedSprite.play("kyle-idle-" + get_direction(input_vector))
	else:
		# Animasi berjalan berdasarkan arah input
		if input_vector.x > 0:
			animatedSprite.play("kyle-run-right")
		elif input_vector.x < 0:
			animatedSprite.play("kyle-run-left")
		elif input_vector.y > 0:
			animatedSprite.play("kyle-run-front")
		elif input_vector.y < 0:
			animatedSprite.play("kyle-run-back")

func get_direction(vector):
	if vector.x > 0:
		return "right"
	elif vector.x < 0:
		return "left"
	elif vector.y > 0:
		return "front"
	elif vector.y < 0:
		return "back"
	return "front"

func _on_Stats_no_health():
	queue_free()
	var deathEffect = deathEffect.instance()
	get_parent().add_child(deathEffect)
	deathEffect.global_position = global_position
