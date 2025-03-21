extends CharacterBody2D

class_name Player

const FOV_TWEEN_DURATION = 0.075
const RAT_COOLDOWN = 10
const MAX_STAMINA = 100
const STAMINA_USE_DURATION = 2 # number of seconds from 100 to 0 stamina
const STAMINA_REC_DURATION = 10 # number of seconds from 0 to 100 stamina
const SPRINT_THRESHOLD = 40 # at least this value stamina to sprint
const CHEESE_DROP_COOLDOWN = 10
const BUFF_TIME = 15
const BUFF_COOLDOWN = 35

static var roles = ["mouse", "mouse", "rat", "sheriff"]
static var roles_copy = ["mouse", "mouse", "rat", "sheriff"]
static var rng = RandomNumberGenerator.new()

var username

var SPEED = 600.0
var stamina = MAX_STAMINA
var can_sprint = true
var sprinting = false
var anim = "static front"
var role = ""
var started = false
var color = ""
var alive = true
var buffed = false
var buff_end = 0
var next_rat_kill = 0
var sheriff_shot = false
var next_cheese_drop = 0
var cheese = null

var ghost_instance: CharacterBody2D
var ghost_scene: PackedScene
var idx: int
var effect: AudioEffectCapture
var playback: AudioStreamGeneratorPlayback
var input
var output

var death_sound; var angel_sound
var knife_sound; var shot_sound; var walk_sound; var sprint_sound

func _init() -> void:
	var idx = rng.randi_range(0, len(roles) - 1)
	role = roles[idx]
	roles.pop_at(idx)
	alive = true
	buffed = false
	started = false
	ghost_scene = preload("res://ghost_mouse.tscn")
	
	death_sound = preload("res://assets/Music/death_sound.mp3")
	knife_sound = preload("res://assets/Music/knife_stab.mp3")
	shot_sound = preload("res://assets/Music/gunshot.mp3")
	walk_sound = preload("res://assets/Music/walking.mp3")
	sprint_sound = preload("res://assets/Music/sprinting.mp3")
	angel_sound = preload("res://assets/Music/angelic.mp3")

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _pseudo_ready():
	add_to_group("player")
	if role == "":
		print("role not set")
		
func _attach_usernames(id_to_username, id_to_color):
	for id in id_to_color:
		if id_to_color[id] == self.color:
			$Username.text = "[center]" + id_to_username[id]

func starter(color_to_roles, id_to_username, id_to_color):
	if ghost_instance and is_instance_valid(ghost_instance):
		ghost_instance.queue_free()
		ghost_instance = null
	
	var now = Time.get_unix_time_from_system()
	next_rat_kill = now + RAT_COOLDOWN / 2
	next_cheese_drop = now
	buff_end = now - 1
	
	username = id_to_username[multiplayer.get_unique_id()]
	role = color_to_roles[color]
	alive = true
	buffed = false
	sheriff_shot = false
	started = true
	$ViewSphere.enabled = true
	$ViewSphere.texture_scale = 1
	$ViewSphere.energy = 1
	$Vision.enabled = true
	_attach_usernames(id_to_username, id_to_color)
	enable_movement()
	if is_multiplayer_authority():
		$Camera2D.enabled = true
		$Camera2D.make_current()
		if role == "sheriff":
			$Aim.enabled = true
		elif role == "rat":
			stamina = 100
			can_sprint = true
		else:
			$Aim.enabled = false
		return [role, self.get_node("AnimatedSprite2D").modulate, color]
	else:
		$Vision.enabled = false
		$ViewSphere.enabled = false
		$Aim.enabled = false
	return ["", Color(1, 1, 1), ""]

func disable_movement():
	$AnimatedSprite2D.animation = "static front"
	set_physics_process(false)
	if ghost_instance and is_instance_valid(ghost_instance):
		ghost_instance.set_physics_process(false)
	
func enable_movement():
	set_physics_process(true)
	if ghost_instance and is_instance_valid(ghost_instance):
		ghost_instance.set_physics_process(true)

func get_player():
	return self

func get_role():
	return role

func get_color():
	return color

func get_color_prop():
	return $AnimatedSprite2D.modulate
	
func get_shot():
	return sheriff_shot

func get_kill_cooldown():
	return ceil(next_rat_kill - Time.get_unix_time_from_system())

func get_stamina_value():
	return stamina
	
func get_can_sprint():
	return can_sprint
	
func get_buff_progress():
	return (buff_end - Time.get_unix_time_from_system()) * 100 / BUFF_TIME
	
func get_cheese_drop_cooldown():
	return ceil(next_cheese_drop - Time.get_unix_time_from_system())
	
func set_aim_view_visible(b: bool):
	$AimView.visible = b
	
func is_alive():
	return alive
	
func clear_addons():
	$Blood.visible = false
	$Knife.visible = false
	$Gun.visible = false
	
func reset_sprite_to_defaults():
	$Vision.rotation_degrees = -90
	$ViewSphere.texture_scale = 1
	$AnimatedSprite2D.animation = "static front"
	$AnimatedSprite2D.play()
	$AnimatedSprite2D.stop()
	$Aim.rotation_degrees = 0
	$Shadow.visible = true
	clear_addons()
	$SoundEffects.stop()

func _rotation_tween(end_angle: float):
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	
	var start_angle := fmod($Vision.rotation_degrees, 360.0)
	if start_angle < 0:
		start_angle += 360.0
		
	end_angle = fmod(end_angle, 360.0)
	if end_angle < 0:
		end_angle += 360.0
		
	var diff = end_angle - start_angle
	if abs(diff) > 180.0:
		if diff > 0:
			diff -= 360.0
		else:
			diff += 360.0
			
	var target_angle = $Vision.rotation_degrees + diff
	tween.tween_property($Vision, "rotation_degrees", target_angle, FOV_TWEEN_DURATION)
	
func set_vision():
	if velocity.x < 0 and velocity.y < 0:
		_rotation_tween(45)
		$Aim.rotation_degrees = 135
	elif velocity.x < 0 and velocity.y > 0:
		_rotation_tween(315)
		$Aim.rotation_degrees = 45
	elif velocity.x > 0 and velocity.y < 0:
		_rotation_tween(135)
		$Aim.rotation_degrees = -135
	elif velocity.x > 0 and velocity.y > 0:
		_rotation_tween(225)
		$Aim.rotation_degrees = -45
	elif velocity.x < 0:
		_rotation_tween(0)
		$Aim.rotation_degrees = 90
	elif velocity.y < 0:
		_rotation_tween(90)
		$Aim.rotation_degrees = 180
	elif velocity.y > 0:
		_rotation_tween(270)
		$Aim.rotation_degrees = 0
	elif velocity.x > 0:
		_rotation_tween(180)
		$Aim.rotation_degrees = -90

func _process_sprinting(delta: float, direction: Vector2) -> Vector2:
	if Input.is_action_pressed("SHIFT") and ((role == "rat" and can_sprint) or buffed):
		if not sprinting:
			sprinting = true
			$SoundEffects.stop()
		
		if role == "rat":
			stamina = max(0, stamina - MAX_STAMINA / STAMINA_USE_DURATION * delta)
			if stamina == 0:
				can_sprint = false
	else:
		if sprinting:
			sprinting = false
			$SoundEffects.stop()
		
		if role == "rat":
			if not Input.is_action_pressed("SHIFT"):
				stamina = min(MAX_STAMINA, stamina + MAX_STAMINA / STAMINA_REC_DURATION * delta)
				if stamina >= SPRINT_THRESHOLD:
					can_sprint = true
			
	if sprinting:
		direction *= 1.8
		$AnimatedSprite2D.speed_scale = 1.8
	else:
		$AnimatedSprite2D.speed_scale = 1.0
		
	return direction

func _physics_process(delta: float) -> void:
	if !alive:
		return
	
	# Get the input direction and handle the movement/deceleration.
	if is_multiplayer_authority() and started:
		var direction := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN").normalized()
		
		direction = _process_sprinting(delta, direction)
		if direction:
			velocity = direction * SPEED
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()
		
		set_vision()
		
		# Set sprite orientation
		if velocity.x != 0:
			if velocity.y > 0:
				anim = "diagonal down"
			elif velocity.y < 0:
				anim = "diagonal up"
			else:
				anim = "left"
			
			if velocity.x < 0:
				$AnimatedSprite2D.flip_h = false
				$Blood.flip_h = false
				$Knife.flip_h = false
				$Gun.flip_h = false
			else:
				$AnimatedSprite2D.flip_h = true
				$Blood.flip_h = true
				$Knife.flip_h = true
				$Gun.flip_h = true
		elif velocity.y != 0:
			if velocity.y < 0:
				anim = "gyatt"
			else:
				anim = "front"
		else:
			if anim == "left":
				anim = "static left"
			elif anim == "gyatt":
				anim = "static gyatt"
			elif anim == "front":
				anim = "static front"
	
		$AnimatedSprite2D.animation = anim
		if velocity.length() > 0:
			$AnimatedSprite2D.play()
			if not $SoundEffects.playing:
				if sprinting:
					$SoundEffects.stream = sprint_sound
				else:
					$SoundEffects.stream = walk_sound
				$SoundEffects.stream.loop = true
				$SoundEffects.play()
		else:
			$AnimatedSprite2D.stop()
			if $SoundEffects.playing:
				$SoundEffects.stream.loop = false
	
	if Time.get_unix_time_from_system() > buff_end:
		self.unbuff()

func _unhandled_input(event: InputEvent) -> void:
	if !alive:
		return
	if is_multiplayer_authority() and started:
		if event.is_action_pressed("ATTACK"):
			if role == "rat":
				if Time.get_unix_time_from_system() < next_rat_kill:
					print(color + " on kill cooldown")
					return
				var set_cooldown = false
				for child in get_tree().get_nodes_in_group("player"):
					if child.has_method("die"):
						if child.get_role() == "rat" or !child.is_alive():
							continue
						if child.position.distance_to(self.position) < 190:
							die_call.rpc(child.get_color())
							next_rat_kill = Time.get_unix_time_from_system() + RAT_COOLDOWN
							set_cooldown = true
							add_kill.rpc("rat")
				print(color + " attack!!!")
				set_physics_process(false)
				$AnimationPlayer.play("attack")
				$Knife.visible = true
				$SoundEffects.stream = knife_sound
				$SoundEffects.stream.loop = false
				$SoundEffects.play()
				if !set_cooldown:
					next_rat_kill = Time.get_unix_time_from_system() + ceil(RAT_COOLDOWN / 4)
			if role == "sheriff":
				var target = $Aim.get_collider()
				if sheriff_shot:
					return
				if target != null and target.has_method("die"):
					if target.get_role() == "sheriff":
						return
					if !target.is_alive():
						return
					target.set_aim_view_visible(false)
					die_call.rpc(target.get_color())
					add_kill.rpc("sheriff")
				sheriff_shot = true
				print(color + " shoot!!!")
				set_physics_process(false)
				animate_shoot()
				$SoundEffects.stream = shot_sound
				$SoundEffects.stream.loop = false
				$SoundEffects.play()
			if role == "mouse":
				if Time.get_unix_time_from_system() < next_cheese_drop:
					print(color + " on cheese drop cooldown")
					return
				
				cheese_create_call.rpc(color)

func animate_shoot():
	var current_anim = $AnimatedSprite2D.animation
	var new_anim = ""
	if current_anim == "left" or current_anim == "static left":
		new_anim = "shoot left"
	elif current_anim == "front" or current_anim == "static front":
		new_anim = "shoot down"
	elif current_anim == "gyatt" or current_anim == "static gyatt":
		new_anim = "shoot up"
	$Gun.visible = true
	$AnimationPlayer.play(new_anim)

@rpc("call_local", "reliable")
func die_call(color):
	for child in get_tree().get_nodes_in_group("player"):
		if child.has_method("die") and child.get_color() == color:
			child.die()

func die():
	if !alive:
		return
	print(color + " killed!!!")
	alive = false
	$Vision.enabled = false
	set_physics_process(false)
	$AnimationPlayer.stop()
	$AnimationPlayer.clear_queue()
	clear_addons()
	$AnimationPlayer.play("die")
	if is_multiplayer_authority():
		$SoundEffects.stream = death_sound
		$SoundEffects.stream.loop = false
		$SoundEffects.play()
		ghost_instance = spawn_ghost(self.get_node("AnimatedSprite2D").modulate)
		await get_tree().create_timer(0.2).timeout
		fade_out_vision(0.1)
		$SoundEffects.stream = angel_sound
		$SoundEffects.stream.loop = false
		$SoundEffects.play()
		await get_tree().create_timer(0.2).timeout
		activate_ghost(0.1)
	else:
		$ViewSphere.enabled = false
	await get_tree().create_timer(0.2).timeout
	

func fade_out_vision(tween_seconds: float) -> void:
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($ViewSphere, "energy", 0, tween_seconds)
	
func spawn_ghost(color: Color) -> CharacterBody2D:
	var ghost := ghost_scene.instantiate()
	ghost.global_position = global_position
	color.a = 0.5
	ghost.get_node("AnimatedSprite2D").modulate = color
	get_parent().add_child(ghost)
	if multiplayer.has_multiplayer_peer():
		ghost.set_multiplayer_authority(multiplayer.get_unique_id())
		print("ghost mult authority set to", ghost.get_multiplayer_authority())
	return ghost

# kill screen animation here maybe
func activate_ghost(tween_duration: float):
	if ghost_instance and ghost_instance.has_node("Camera2D"):
		var tween := get_tree().create_tween()
		tween.set_ease(Tween.EASE_IN)
		ghost_instance.started = true
		ghost_instance.visible = true
		
		tween.tween_property(ghost_instance.get_node("ViewSphere"), "energy", 1.5, tween_duration)
		#tween.tween_property(ghost_instance.get_node("AnimatedSprite2D"), "modulate", Color("#71bdee87"), tween_duration)
		print("setting camera")
		var camera = ghost_instance.get_node("Camera2D")
		
		# disable dead body's cam and enable ghost's cam
		$Camera2D.enabled = false
		camera.enabled = true
		camera.make_current()
			
@rpc("call_local", "reliable")
func add_kill(killer: String):
	if killer == "rat":
		Main.rat_killed += 1
	if killer == "sheriff":
		Main.sheriff_killed += 1
		
@rpc("call_local", "reliable")
func cheese_create_call(owner_color: String):
	# Search for owner node
	var owner = null
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("get_color") and player.get_color() == owner_color:
			owner = player
	if owner == null:
		print("cheese constructor cannot find owner")
	
	if owner.cheese != null:
		owner.cheese.queue_free()
		print(color + " cheese despawned")
	
	owner.cheese = Cheese.constructor(owner)
	owner.next_cheese_drop = Time.get_unix_time_from_system() + CHEESE_DROP_COOLDOWN
	
func buff():
	self.buffed = true
	self.buff_end = Time.get_unix_time_from_system() + BUFF_TIME
	self.next_cheese_drop = Time.get_unix_time_from_system() + BUFF_COOLDOWN
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property($ViewSphere, "scale", Vector2(30, 30), 0.5)
	
func unbuff():
	self.buffed = false
	var tween := get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property($ViewSphere, "scale", Vector2(10, 10), 0.5)

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if effect:
		if effect.can_get_buffer(1024) and playback.can_push_buffer(1024):
			send_data.rpc(effect.get_buffer(1024))
		effect.clear_buffer()
	else:
		print("no effect")

@rpc("call_remote", "unreliable")
func send_data(data : PackedVector2Array):
	for i in range(0,1024):
		playback.push_frame(data[i])
