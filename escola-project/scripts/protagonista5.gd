extends CharacterBody2D

enum PlayerState {
	parado,
	correndo,
	pulando,
	caindo,
	agachado,
	deslizando,
	ataque,
	dano,
	morte
}

@onready var anim: AnimatedSprite2D = $Animação_Prota
@onready var colisor_prota: CollisionShape2D = $Colisor_Prota
@onready var attack_area: Area2D = $attackArea
@onready var attack_collision: CollisionShape2D = $attackArea/attack_collision



@export var max_speed = 250.0
@export var acceleration = 200.0
@export var deceleration = 550.0
@export var deslizando_deceleration = 100

const JUMP_VELOCITY = -350.0

var direction = 0
var status: PlayerState
var hp = 50
var taking_damage = false


func _ready() -> void:
	go_to_parado_state()
	attack_collision.disabled = true

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		PlayerState.parado:
			parado_state(delta)
		PlayerState.correndo:
			correndo_state(delta)
		PlayerState.pulando:
			pulando_state(delta)
		PlayerState.caindo:
			caindo_state(delta)
		PlayerState.agachado:
			agachado_state(delta)
		PlayerState.deslizando:
			deslizando_state(delta)
		PlayerState.ataque:
			ataque_state(delta)
		PlayerState.dano:
			dano_state(delta)
		PlayerState.morte:
			morte_state(delta)
			
	move_and_slide()

func go_to_parado_state():
	status = PlayerState.parado
	anim.play("parado")
	
func go_to_correndo_state():
	status = PlayerState.correndo
	anim.play("correndo")

func go_to_pulando_state():
	status = PlayerState.pulando
	anim.play("pulando")
	velocity.y = JUMP_VELOCITY
	
func go_to_caindo_state():
	status = PlayerState.caindo
	anim.play("caindo")
	
func go_to_agachado_state():
	status = PlayerState.agachado
	anim.play("agachado")
	set_small_collider()
	
func exit_from_agachado_state():
	set_large_collider()
	
	
func go_to_deslizando_state():
	status = PlayerState.deslizando
	anim.play("deslizando")
	set_small_collider()
	
func exit_from_deslizando_state():
	set_large_collider()
	
func go_to_ataque_state():

	status = PlayerState.ataque
	anim.play("ataque")

	velocity.x = 0

	attack_collision.disabled = false

	if anim.flip_h:

		attack_area.position.x = 5
		attack_area.scale.x = -1

	else:

		attack_area.position.x = -5
		attack_area.scale.x = 1
		
func go_to_dano_state():

	status = PlayerState.dano

	velocity = Vector2.ZERO

	anim.play("dano")
	
func go_to_morte_state():

	status = PlayerState.morte
	anim.play("morte")

	velocity = Vector2.ZERO

	velocity.x = 0

func parado_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_correndo_state()
		return
		
	if Input.is_action_just_pressed("pulando"):
		go_to_pulando_state()
		return
		
	if Input.is_action_pressed("agachado"):
		go_to_agachado_state()
		return
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		go_to_ataque_state()
		return
	
func correndo_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_parado_state()
		return
		
	if Input.is_action_just_pressed("pulando"):
		go_to_pulando_state()
		return
		
	
	if Input.is_action_just_pressed("agachado"):
		go_to_deslizando_state()
		return
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		go_to_ataque_state()
		return
		
		
	if !is_on_floor():
		go_to_caindo_state()
		return
		
	
func pulando_state(delta):
	move(delta)
	
		
	if velocity.y > 0:
		go_to_caindo_state()
		return
		
func caindo_state(delta):
	move(delta)
	
	if is_on_floor():
		if velocity.x ==-20:
			go_to_parado_state()
		else:
			go_to_correndo_state()
		return
		
func agachado_state(_delta):
	update_direction()
	if Input.is_action_just_released("agachado"):
		exit_from_agachado_state()
		go_to_parado_state()
		return
		
func deslizando_state(delta):
	velocity.x = move_toward(velocity.x, 0, deslizando_deceleration * delta)
	
	if Input.is_action_just_released("agachado"):
		exit_from_deslizando_state()
		go_to_correndo_state()
		return
		
	if velocity.x == 0:
		exit_from_deslizando_state()
		go_to_agachado_state()
		return
		
func ataque_state(_delta):
	
	if anim.frame == anim.sprite_frames.get_frame_count("ataque") - 1:
		
		attack_collision.disabled = true
		go_to_parado_state()
		
func dano_state(_delta):

	velocity = Vector2.ZERO

	if anim.frame == anim.sprite_frames.get_frame_count("dano") - 1:

		taking_damage = false
		go_to_parado_state()
		
func morte_state(_delta):

	velocity = Vector2.ZERO

	if anim.frame == anim.sprite_frames.get_frame_count("morte") - 1:
		queue_free()

func move(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
func update_direction():
	direction = Input.get_axis("left", "right")
	
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false

func set_small_collider():
	colisor_prota.shape.radius = 10
	colisor_prota.shape.height = 30
	colisor_prota.position.y = 5
	colisor_prota.position.x = -2
	
func set_large_collider():
	colisor_prota.shape.radius = 10
	colisor_prota.shape.height = 36
	colisor_prota.position.y = 0
	colisor_prota.position.x = 0

func _on_attack_area_body_entered(body):

	if body.has_method("take_damage"):
		body.take_damage(10)

func take_damage(damage):

	if taking_damage:
		return

	if status == PlayerState.morte:
		return

	taking_damage = true

	hp -= damage

	print("HP Player:", hp)

	if hp <= 0:
		go_to_morte_state()
	else:
		go_to_dano_state()
