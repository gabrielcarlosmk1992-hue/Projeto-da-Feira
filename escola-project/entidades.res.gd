extends CharacterBody2D

enum  GoblinState {
		walk,
		death
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var colisor: RayCast2D = $colisor
@onready var colisor_2: RayCast2D = $"colisor 2"


const SPEED = 10.0
const JUMP_VELOCITY = -400.0

var status: GoblinState

var direction = 1

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	match status:
		GoblinState.walk:
			walk_state(delta)
		GoblinState.death:
			death_state(delta)

	move_and_slide()

func go_to_walk_state():
	status = GoblinState.walk
	anim.play("walk")
	
func go_to_death_state():
	status = GoblinState.death
	anim.play("death")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	
func walk_state(_delta):
	velocity.x = SPEED * direction
	
	if colisor.is_colliding():
		scale.x *= -1
		direction *= -1
	
	if  not colisor_2.is_colliding():
		scale.x *= -1
		direction *= -1
	
func death_state(_delta):
	pass
	
func tack_damage():
	go_to_death_state()
	
