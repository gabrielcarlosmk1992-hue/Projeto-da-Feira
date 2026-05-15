extends CharacterBody2D

enum GoblinState {
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
const ATTACK_DISTANCE = 25

var status: GoblinState

var direction = 1

var walk_time = 0.0
var idle_time = 0.0

var attack_hit_done = false
var hit_lock = false

var chasing_player = false

var hp = 30

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:

	if status == GoblinState.dead:
		dead_state(delta)
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:

		GoblinState.walk:
			walk_state(delta)

		GoblinState.attack:
			attack_state(delta)

		GoblinState.hit:
			hit_state(delta)

		GoblinState.idle:
			idle_state(delta)

	move_and_slide()

func go_to_walk_state():

	if status == GoblinState.dead:
		return

	status = GoblinState.walk

	anim.speed_scale = 1.0
	anim.play("walk")

func go_to_attack_state():

	if status == GoblinState.dead:
		return

	if status == GoblinState.attack:
		return

	if status == GoblinState.hit:
		return

	status = GoblinState.attack

	anim.speed_scale = 0.8
	anim.play("attack")

	attack_hit_done = false

	velocity = Vector2.ZERO

func go_to_hit_state():

	if status == GoblinState.dead:
		return

	status = GoblinState.hit

	anim.speed_scale = 1.0

	anim.stop()
	anim.frame = 0
	anim.play("hit")

	velocity = Vector2.ZERO

func go_to_dead_state():

	status = GoblinState.dead

	anim.speed_scale = 1.0
	anim.play("dead")

	hitbox.monitoring = false

	velocity = Vector2.ZERO

func go_to_idle_state():

	if status == GoblinState.dead:
		return

	status = GoblinState.idle

	anim.play("idle")

	velocity.x = 0

	idle_time = 0.0

func walk_state(delta):

	chasing_player = false

	# PLAYER NA FRENTE
	if detector_player_front.is_colliding():

		var alvo = detector_player_front.get_collider()

		if alvo != null and alvo.is_in_group("player"):

			chasing_player = true

			velocity.x = SPEED * direction

			var distancia = global_position.distance_to(alvo.global_position)

			if distancia <= ATTACK_DISTANCE:

				go_to_attack_state()
				return

	# PLAYER ATRÁS
	if detector_player_back.is_colliding():

		var alvo_back = detector_player_back.get_collider()

		if alvo_back != null and alvo_back.is_in_group("player"):

			chasing_player = true

			direction *= -1
			scale.x *= -1

			velocity.x = SPEED * direction

			var distancia_back = global_position.distance_to(alvo_back.global_position)

			if distancia_back <= ATTACK_DISTANCE:

				go_to_attack_state()
				return

	# WALK NORMAL
	if !chasing_player:

		if anim.animation != "walk":
			anim.play("walk")

		velocity.x = SPEED * direction

		walk_time += delta

		if walk_time >= 3.0:

			walk_time = 0.0
			go_to_idle_state()
			return

	# PAREDE
	if detector.is_colliding():

		direction *= -1
		scale.x *= -1

	# SEM CHÃO
	if !detector_2.is_colliding():

		direction *= -1
		scale.x *= -1

func attack_state(_delta):

	velocity.x = 0

	# perdeu player
	if !detector_de_player.is_colliding():

		attack_hit_done = false

		go_to_walk_state()
		return

	# HIT UMA VEZ
	if anim.frame > 6 and !attack_hit_done:

		attack_hit_done = true

		var alvo = detector_de_player.get_collider()

		if alvo != null and alvo.has_method("take_damage"):

			alvo.take_damage(10)

			print("Goblin deu 15 de dano")

	# RESET
	if anim.frame == 0:
		attack_hit_done = false

	# FIM DA ANIMAÇÃO
	if anim.frame == anim.sprite_frames.get_frame_count("attack") - 1:

		go_to_walk_state()

func hit_state(_delta):

	velocity = Vector2.ZERO

	if anim.animation != "hit":
		anim.play("hit")

	# trava hit
	await get_tree().create_timer(2).timeout

	hit_lock = false

	if status != GoblinState.dead:

		if hp <= 0:
			go_to_dead_state()
		else:
			go_to_walk_state()

func dead_state(_delta):

	velocity = Vector2.ZERO

	if anim.frame == anim.sprite_frames.get_frame_count("dead") - 1:

		queue_free()

func take_damage(damage):

	if status == GoblinState.dead:
		return

	if hit_lock:
		return

	hit_lock = true

	hp -= damage

	print("Goblin HP:", hp)

	if hp <= 0:

		go_to_dead_state()
		return

	go_to_hit_state()

func idle_state(delta):

	velocity.x = 0

	if anim.animation != "idle":
		anim.play("idle")

	idle_time += delta

	if idle_time >= 3.0:

		direction *= -1
		scale.x *= -1

		go_to_walk_state()
