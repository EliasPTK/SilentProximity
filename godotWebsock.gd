extends Node2D

var python_process: int = -1
var websocket_client = WebSocketPeer.new()
var connected = false
@export var imgAsStr: String
@export var builtStr: String
@export var sprit: Sprite2D
var web_id = 8912


func list_available_cameras():
	var output = []
	var exit_code = OS.execute("python.exe", ["newtest.py"], output)
	$"../CanvasLayer/Label2".text = str(output)
	print(output)
func _notification(what) -> void:

	# Check if notifcation is a "close request"
	if what == NOTIFICATION_WM_CLOSE_REQUEST:

		# Stop the webcam server
		webcam_server_stop()
		Steam.steamShutdown()
		# Close _this_ application
		get_tree().quit()

## Closes the application based on the operating system
func webcam_server_stop() -> void:
	print("AHH")
	if connected:
		stop_camera_stream()
	websocket_client.close()
	if python_process != -1:
		OS.kill(python_process)
		print("Stopped Python process")

func setup():
	# Start the Python websocket server
	
	if(!is_multiplayer_authority()):
		return
	
	web_id = webID.web_id
	start_python_websocket()
	
	# Wait a bit for server to start, then connect
	await get_tree().create_timer(2.0).timeout
	connect_to_websocket()
	

func start_python_websocket():
	var script_path = ProjectSettings.globalize_path("res://pywebtest.py")
	var exe_path = ProjectSettings.globalize_path("res://dist/pywebtest.exe")
	if !OS.has_feature("editor"):
		exe_path = OS.get_executable_path().get_base_dir() + "/pywebtest.exe"
	print("Starting Python server at: ", script_path)
	
	#var args = [script_path,web_id,webID.cam_id]
	#python_process = OS.create_process("python" , args)
	
	var args = [web_id,webID.cam_id]
	python_process = OS.create_process(exe_path, args)
	
	if python_process != -1:
		print("Python websocket server started with PID: ", python_process)
	else:
		print("Failed to start Python process")
		
func stop_camera_stream():
	var command = {"command": "stop_stream"}
	websocket_client.send_text(JSON.stringify(command))
	print("Requested camera stream stop")
	
func connect_to_websocket():
	var url = "ws://localhost:"
	url += str(web_id)
	var err = websocket_client.connect_to_url(url)
	
	if err != OK:
		print("Failed to connect to websocket: ", err)
	else:
		$"../CanvasLayer/Label".text = "Connecting to websocket..."
		print("Connecting to websocket...")

func _process(_delta):
	if(!get_parent().is_multiplayer_authority()):
		return
		
	if(Input.is_action_just_pressed("List")):
		list_available_cameras()
	websocket_client.poll()
	var state = websocket_client.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not connected:
			connected = true
			$"../CanvasLayer/Label".text = "Connected to websocket!"
			print("Connected to websocket!")
			# Start the camera stream
			camera_stream()
		
		# Check for incoming messages
		while websocket_client.get_available_packet_count():
			var packet = websocket_client.get_packet()
			var message = packet.get_string_from_utf8()
			process_frame(message)
	
	elif state == WebSocketPeer.STATE_CLOSED:
		if connected:
			print("Websocket connection closed")
			connected = false

func camera_stream():
	var command = {"command": "start_stream"}
	websocket_client.send_text(JSON.stringify(command))
	

func process_frame(message: String):
	var json = JSON.new()
	var parse_result = json.parse(message)
	
	if parse_result != OK:
		print("JSON Parse Error: ", json.get_error_message())
		return
	
	var data = json.data
	if (data.get("status") == "camera_list"):
		print("Available cameras: ", data.get("cameras"))

	imgAsStr = data["data"]
	
	# Decode base64 image
	var image_data = Marshalls.base64_to_raw(imgAsStr)
	
	# Create image from JPEG data
	var image = Image.new()
	var error = image.load_jpg_from_buffer(image_data)
	
	if error != OK:
		print("Error loading image: ", error)
		return
	
	# Update texture
	sprit.texture =ImageTexture.create_from_image(image)
