extends CharacterBody2D

enum EsqueletoState {
	idle,
	walk,
	attack,
	hit,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Area2D
@onready var detector: RayCast2D = $Detector
@onready var detector_2: RayCast2D = $"Detector 2"
@onready var detector_de_player: RayCast2D = $"Detector de Player"
@onready var detector_player_front: RayCast2D = $Detector_Player_Front
@onready var detector_player_back: RayCast2D = $Detector_Player_Back


const SPEED = 30.0
const JUMP_VELOCITY = -400.0
const ATTACK_DISTANCE = 25

var status: EsqueletoState

var direction = 1

var walk_time = 0.0
var wait_time = 0.0
var waiting = false

var attack_active = false
var attack_hit_done = false
var hit_lock = false

var chasing_player = false


var hp = 30

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		EsqueletoState.walk:
			walk_state(delta)
		EsqueletoState.attack:
			attack_state(delta)
		EsqueletoState.dead:
			dead_state(delta)
		EsqueletoState.hit:
			hit_state(delta)
		EsqueletoState.idle:
			idle_state(delta)

	move_and_slide()

func go_to_walk_state():
	status = EsqueletoState.walk
	anim.play("walk")
	
func go_to_attack_state():
	status = EsqueletoState.attack
	anim.play("attack")
	anim.speed_scale =1.5
	velocity = Vector2.ZERO
	
func go_to_hit_state():

	status = EsqueletoState.hit
	anim.play("hit")

	velocity = Vector2.ZERO
	
func go_to_dead_state():
	status = EsqueletoState.dead
	anim.play("dead")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	
var idle_time = 0.0

func go_to_idle_state():

	status = EsqueletoState.idle
	anim.play("idle")

	velocity.x = 0

	idle_time = 0.0
	
func walk_state(delta):

	chasing_player = false

	# PLAYER NA FRENTE
	if detector_player_front.is_colliding():

		var alvo = detector_player_front.get_collider()

		if alvo.is_in_group("player"):

			chasing_player = true

			# Anda até o player
			velocity.x = SPEED * direction

			if alvo is Node2D:

				var distancia = global_position.distance_to(alvo.global_position)

				# Ataca quando perto
				if distancia <= ATTACK_DISTANCE:
					go_to_attack_state()
					return

	# PLAYER ATRÁS
	if detector_player_back.is_colliding():

		var alvo_back = detector_player_back.get_collider()

		if alvo_back.is_in_group("player"):

			chasing_player = true

			# Vira pro player
			direction *= -1
			scale.x *= -1

			velocity.x = SPEED * direction

			if alvo_back is Node2D:

				var distancia_back = global_position.distance_to(alvo_back.global_position)

				if distancia_back <= ATTACK_DISTANCE:
					go_to_attack_state()
					return

	# SE NÃO ESTIVER PERSEGUINDO
	if !chasing_player:

		# Animação walk
		if anim.animation != "walk":
			anim.play("walk")

		velocity.x = SPEED * direction

		walk_time += delta

		# Para depois de 3 segundos
		if walk_time >= 3.0:

			walk_time = 0.0
			go_to_idle_state()
			return

	# Parede
	if detector.is_colliding():

		direction *= -1
		scale.x *= -1

	# Sem chão
	if !detector_2.is_colliding():

		direction *= -1
		scale.x *= -1
		
func attack_state(_delta):

	velocity.x = 0

	if !detector_de_player.is_colliding():
		attack_active = false
		go_to_walk_state()
		return

	# HIT GARANTIDO UMA VEZ
	if anim.frame > 6 and !attack_hit_done:
		attack_hit_done = true

		var alvo = detector_de_player.get_collider()

		if alvo != null and alvo.has_method("take_damage"):
			alvo.take_damage(2)

	# reset quando animação reinicia ou volta
	if anim.frame == 0:
		attack_hit_done = false

	if anim.frame == anim.sprite_frames.get_frame_count("attack") - 1:
		go_to_walk_state()
	
func dead_state(_delta):

	velocity.x = 0

	# Espera animação acabar
	if anim.frame == anim.sprite_frames.get_frame_count("dead") - 1:
		queue_free()

func take_damage(damage):

	if status == EsqueletoState.dead:
		return

	hp -= damage
	print("HP:", hp)

	if hp <= 0:
		go_to_dead_state()
		return

	# bloqueia múltiplos hits
	if hit_lock:
		return

	hit_lock = true
	go_to_hit_state()
		
func idle_state(delta):

	velocity.x = 0

	anim.play("idle")

	idle_time += delta

	if idle_time >= 3.0:

		direction *= -1
		scale.x *= -1

		go_to_walk_state()
		
func hit_state(_delta):

	velocity = Vector2.ZERO

	if anim.animation != "hit":
		anim.play("hit")

	# espera tempo fixo (1.5s)
	await get_tree().create_timer(0.8).timeout

	hit_lock = false

	# só volta se ainda não morreu
	if status != EsqueletoState.dead:
		go_to_walk_state()
