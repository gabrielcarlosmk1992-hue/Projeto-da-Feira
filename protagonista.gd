extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var animation := $"Animação_Prota" as AnimatedSprite2D
var is_jump := false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		animation.play("Pulando")


	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jump = true
	elif is_on_floor():
		is_jump = false 

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		animation.scale.x = direction 
		if !is_jump:
			animation.play("Correndo")
	elif is_jump:
		animation.play("Pulando")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animation.play("Parado")

	move_and_slide()
