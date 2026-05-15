extends CharacterBody2D

enum CogumeloState {
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


const SPEED = 15.0
const JUMP_VELOCITY = -400.0
const ATTACK_DISTANCE = 25

var status: CogumeloState

var direction = 1

var walk_time = 0.0
var wait_time = 0.0
var waiting = false

var chasing_player = false

var hp = 60

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		CogumeloState.walk:
			walk_state(delta)
		CogumeloState.attack:
			attack_state(delta)
		CogumeloState.dead:
			dead_state(delta)
		CogumeloState.hit:
				hit_state(delta)
		CogumeloState.idle:
			idle_state(delta)

	move_and_slide()

func go_to_walk_state():
	status = CogumeloState.walk
	anim.play("walk")
	
func go_to_attack_state():
	status = CogumeloState.attack
	anim.play("attack")
	velocity = Vector2.ZERO
	
func go_to_hit_state():

	status = CogumeloState.hit

	anim.stop()
	anim.frame = 0
	anim.play("hit")

	velocity = Vector2.ZERO
	
func go_to_dead_state():
	status = CogumeloState.dead
	anim.play("dead")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	
var idle_time = 0.0

func go_to_idle_state():

	status = CogumeloState.idle
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
		go_to_walk_state()
		return

	# Dá dano só no último frame da animação
	if anim.frame == anim.sprite_frames.get_frame_count("attack") - 1:

		var alvo = detector_de_player.get_collider()

		if alvo != null and alvo.has_method("take_damage"):
			alvo.take_damage(2)

		anim.play("attack")

func hit_state(_delta):

	velocity = Vector2.ZERO

	if anim.frame == anim.sprite_frames.get_frame_count("hit") - 1:
		go_to_walk_state()
	
func dead_state(_delta):

	velocity.x = 0

	# Espera animação acabar
	if anim.frame == anim.sprite_frames.get_frame_count("dead") - 1:
		queue_free()

func take_damage(damage):

	if status == CogumeloState.dead:
		return

	hp -= damage

	print("Cogumelo HP:", hp)

	# MORTE
	if hp <= 0:
		go_to_dead_state()
		return

	# SE ESTIVER ATACANDO
	if status == CogumeloState.attack:

		anim.play("hit")

		await anim.animation_finished

		# volta pro ataque
		if status == CogumeloState.attack:
			anim.play("attack")

	# SE NÃO ESTIVER ATACANDO
	else:

		go_to_hit_state()
		
func idle_state(delta):

	velocity.x = 0

	anim.play("idle")

	idle_time += delta

	if idle_time >= 3.0:

		direction *= -1
		scale.x *= -1

		go_to_walk_state()
