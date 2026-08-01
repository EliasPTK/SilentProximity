extends CharacterBody3D
class_name  playerMove
var id = 0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var cam = $Camera3D
var mouse_sens = 0.0025
var waitTime = 1
var NearObjects = []
@onready var camFather = $Camera3D/Node2D
var lobby_id = 0
var perma_id = 0

@export var second_id = 0

@export var sync_position: Vector3 = Vector3.ZERO
@export var sync_rotation: Vector3 = Vector3.ZERO
@export var my_item: Node3D

#TODO: Change player manager key to be new Id of player(player num)

func _enter_tree():
	var id = int(get_parent().name)
	get_parent().set_multiplayer_authority(id)
	set_multiplayer_authority(id)
	$"../MultiplayerSynchronizer".set_multiplayer_authority(id)
@rpc("any_peer", "call_remote", "reliable")
func _announce_steam_id(steam_id: int):
	var peer_id = int(name)
	PlayerManager.peer_to_steam[peer_id] = steam_id
	PlayerManager.register_player(steam_id, self)
	
func _register_me():
	print("register me capn")
	var peer_id: int = int(get_parent().name)
	var my_steam_id: int = 0
	if is_multiplayer_authority():
		$Camera3D/Node2D.visible = true
		my_steam_id = PlayerManager.get_steam_id_from_peer(peer_id)
		if my_steam_id != 0:
			PlayerManager.register_player(my_steam_id, self)
			_announce_steam_id.rpc(my_steam_id)
	perma_id = my_steam_id
	
	
func _ready() -> void:
	
	
	_register_me()
	cam.current = is_multiplayer_authority()
	if(is_multiplayer_authority()):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await get_tree().create_timer(waitTime).timeout
		print("connected")
		print(Steam.getPersonaName())
		set_player_name.rpc(Steam.getPersonaName())
		id = get_tree().get_multiplayer().get_unique_id()
		print(id)
		second_id = get_tree().get_nodes_in_group("players").size()
	else:
		$"../MultiplayerSynchronizer".synchronized.connect(_on_synchronized)

func _on_synchronized():
	$PlayerInterpolater.update_target(sync_position, sync_rotation)

func _physics_process(delta: float) -> void:
	if (!is_multiplayer_authority()):
		return
	# Add the gravity.
	#if(camFather.get_child(0).current_texture != null):
	get_parent().get_parent()._sync_webcam_peers()
	
	if(Input.is_action_just_pressed("UseItem")):
		my_item.use()
	
	#	send_cam_text(camFather.get_child(0).current_texture)
	if(Input.is_action_just_pressed("Exit")):
		if(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE):
			
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		if (is_multiplayer_authority()):
			rotate_y(-event.relative.x * mouse_sens)
			cam.rotate_x(-event.relative.y * mouse_sens)


@rpc("any_peer", "call_local", "unreliable", 0)
func print_once_per_client(playerName):
	print(str(playerName) +" called a function")
	

@rpc("any_peer", "call_local", "unreliable", 0)
func set_player_name(playerName):
	$Label3D.text = playerName
	
func update_screen(img: Image):
	camFather.get_child(0).current_texture = ImageTexture.create_from_image(img)
