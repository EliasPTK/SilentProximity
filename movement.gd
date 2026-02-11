extends CharacterBody3D
class_name  playerMove
var id = 0
const SPEED = 5.0
var boost = 0
var sprint = 0
const JUMP_VELOCITY = 4.5
@onready var cam = $Camera3D
var mouse_sens = 0.0025
var waitTime = 1
var currentAuthority = 0

var amSliding = false
@export var hp = 20
var maxhp = 20
var impact = Vector3(0,0,0)
func _ready() -> void:
	#	print(id)
	set_multiplayer_authority(name.to_int())
func _physics_process(delta: float) -> void:
	
	
	if(!is_multiplayer_authority()):
		return
	
	var faces = get_tree().get_nodes_in_group("faces")
	for i in faces.size():
		if(faces[i].imgAsStr != ""):
			var image_data = Marshalls.base64_to_raw(faces[i].imgAsStr)
		
		# Create image from JPEG data
			var image = Image.new()
			var error = image.load_jpg_from_buffer(image_data)
			
			if error != OK:
				print("Error loading image: ", error)
				return
	
	# Update texture
			$CanvasLayer.get_child(i).texture =ImageTexture.create_from_image(image)
			$CanvasLayer.get_child(i).get_child(0).size = $CanvasLayer.get_child(i).size 
	
	cam.set_multiplayer_authority(get_multiplayer_authority())
	#if (!is_multiplayer_authority()):
	#	return
	# Add the gravity.

	
		
	if(hp == 0):
		velocity *= 0
	#$Control/ColorRect2.size.x = remap(hp, 0, maxhp, 0, 297.0)
	if(Input.is_action_just_pressed("Exit")):
		#print_once_per_client.rpc(Steam.getPersonaName())
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
	if(Input.is_action_pressed("Sprint")):
		sprint = 3
	else:
		sprint = 0
	
	if(Input.is_action_pressed("Slide")):
		amSliding = true
		scale.y = 0.5
	else:
		amSliding = false
		scale.y = 1
	if(!amSliding):
		var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * (SPEED + boost + sprint)
			velocity.z = direction.z * (SPEED + boost + sprint)
		else:
			velocity -= Vector3(impact.x,0,impact.z)
			velocity.x = move_toward(velocity.x, 0, (SPEED + boost + sprint))
			velocity.z = move_toward(velocity.z, 0, (SPEED + boost + sprint))
			
	else:
		velocity.x = move_toward(velocity.x, impact.x, (SPEED + boost + sprint)/3 * delta)
		velocity.z = move_toward(velocity.z, impact.z, (SPEED + boost + sprint)/3 * delta)
	velocity += Vector3(impact.x,0,impact.z)
	impact = impact.move_toward(Vector3(0,0,0), 3)
	move_and_slide()
	
func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		if (is_multiplayer_authority() && hp != 0):
			rotate_y(-event.relative.x * mouse_sens)
			cam.rotate_x(-event.relative.y * mouse_sens)
