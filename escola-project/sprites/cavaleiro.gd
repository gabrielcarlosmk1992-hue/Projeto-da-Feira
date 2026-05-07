extends CharacterBody2D

enum PlayerState {
	parado,
	correndo,
	pulando,
	caindo,
	agachado,
	deslizando
}

@onready var anim: AnimatedSprite2D = $Animação_Prota
@onready var colisor_prota: CollisionShape2D = $Colisor_Prota


@export var max_speed = 250.0
@export var acceleration = 200.0
@export var deceleration = 550.0
@export var deslizando_deceleration = 100

const JUMP_VELOCITY = -350.0

var direction = 0
var status: PlayerState


func _ready() -> void:
	go_to_parado_state()

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
