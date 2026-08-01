extends TextureRect
class_name webcams
var camera_extension: CameraServerExtension
var camera_texture: CameraTexture
var current_texture: Texture
var done = true
var camCount := 0
var otherCams = []

const CHANNEL_WEBCAM := 1
const CHUNK_SIZE := 1024
const FRAME_INTERVAL := 0.1  # 10fps
const RESOLUTION := Vector2i(160, 90)
const QUALITY := 0.35

var encode_thread := Thread.new()
var encoding := false
var timer := 0.0

var connected_steam_ids: Array[int] = []

var secondID = 0

@export var grayscale = false

func _ready():
	
	if(is_multiplayer_authority()):
		
		changeStatic()
		# Required in Godot 4.5 - must come first
		CameraServer.monitoring_feeds = true
		
		camera_extension = CameraServerExtension.new()
		
		if camera_extension.permission_granted():
			_setup_feed()
		else:
			camera_extension.permission_result.connect(_on_permission_result)
			camera_extension.request_permission()


		

func changeStatic():
	await get_tree().create_timer(0.1).timeout
	$Sprite2D2.texture.noise.seed += 1
	changeStatic()

func _on_permission_result(granted: bool) -> void:
	if not granted:
		push_error("Camera permission denied")
		return
	_setup_feed()

func _setup_feed() -> void:
	var feeds = CameraServer.feeds()
	if feeds.size() == 0:
		push_error("No camera feeds found")
		return
	
	# Important: don't type hint this as CameraFeed — use var
	var feed = CameraServer.feeds()[0]
	
	camera_texture = CameraTexture.new()
	camera_texture.camera_feed_id = feed.get_id()
	camera_texture.camera_is_active = true
	#done = true

func get_current_frame_image() -> Image:
	if camera_texture == null:
		return null
	return camera_texture.get_image()

func _process(delta: float) -> void:
	
	
	if(is_multiplayer_authority()):
		if(Input.is_action_just_pressed("showCam")):
			done = !done
			$Sprite2D2.visible = !$Sprite2D2.visible
		var imgText: Image = get_current_frame_image()
		imgText.resize(320/2, 180/2, Image.INTERPOLATE_BILINEAR)
		if(grayscale):
			imgText.convert(Image.FORMAT_L8)
		imgText.flip_x()
		current_texture = ImageTexture.create_from_image(imgText)
		global_position = get_viewport_rect().size - (current_texture.get_size()*scale.x)
		#print(camCount)
		texture = current_texture
		
		var cams = get_tree().get_nodes_in_group("cam")
		otherCams = cams.duplicate()
		otherCams.erase(self)
		camCount = otherCams.size()
		
		for i in $"../VBoxContainer".get_child_count():
			if(i >= camCount):
				$"../VBoxContainer".get_child(i).visible = false
			else:
				$"../VBoxContainer".get_child(i).visible = true
				$"../VBoxContainer".get_child(i).texture = otherCams[i].current_texture
				#print(otherCams[i].current_texture)
		
		timer += delta
		if timer >= FRAME_INTERVAL and not encoding:
			
			if encode_thread.is_started():
					encode_thread.wait_to_finish()
			
			timer = 0.0
			encoding = true
			encode_thread.start(_encode_and_send)
	
func _encode_and_send():
	#print(connected_steam_ids, "ids")
	var img := camera_texture.get_image()
	if img == null:
		encoding = false
		return
	#print("lesgo")
	img.resize(RESOLUTION.x, RESOLUTION.y, Image.INTERPOLATE_NEAREST)
	if(grayscale):
		img.convert(Image.FORMAT_L8)
	var frame_bytes := img.save_webp_to_buffer(true, QUALITY)
	var frame_id := Time.get_ticks_msec()
	var total_chunks := ceili(frame_bytes.size() / float(CHUNK_SIZE))
	var my_steam_id := int(get_parent().get_parent().get_parent().second_id)
	#print(get_parent().get_parent().get_parent().get_parent().name, "dad id")
	#print(get_parent().get_parent().get_parent().perma_id, "perma id")
	
	#print(my_steam_id, "My_ID")
	for i in range(total_chunks):
		var chunk := frame_bytes.slice(i * CHUNK_SIZE, min((i + 1) * CHUNK_SIZE, frame_bytes.size()))

		var packet := PackedByteArray()
		packet.resize(12)
		packet.encode_u32(0, my_steam_id)
		packet.encode_u32(4, frame_id)
		packet.encode_u16(8, i)
		packet.encode_u16(10, total_chunks)
		packet.append_array(chunk)
		
		for peer_id in connected_steam_ids:
			#print(peer_id,"suck it")
			Steam.sendMessageToUser(peer_id, packet,Steam.NETWORKING_SEND_UNRELIABLE, CHANNEL_WEBCAM)
	encoding = false
