extends Node2D

var wait = 0.5
var thread: Thread
var socket: WebSocketPeer = WebSocketPeer.new()
var socket_url = "ws://localhost:8765"
# Called when the node enters the scene tree for the first time.
func summonElias(textureNode: Sprite2D):
	var output = []
	var exit_code = OS.execute("python.exe", ["newtest.py"], output)
	
	var outputString:String = output[0]
	
	#print('\n' == outputString[-1])
	outputString = outputString.substr(1,len(outputString) - 4)
	
	#while('\n' == outputString[-1]):
	#	outputString = outputString.substr(0,len(outputString) - 2)

	if((len(outputString)%4) != 0):
		for i in (4 - (len(outputString)%4)):
			
			outputString += "="
	
	outputString.replace("_","/")
	outputString.replace("-","+")
	outputString.replace(",","/")

	var raw_data = Marshalls.base64_to_raw(outputString)

	# Create an Image from the raw data
	var image = Image.new()

	# Load an image from the binary contents of a JPEG file
	var result = image.load_jpg_from_buffer(raw_data)

	# Check if the image loaded from the buffer
	if !result:

		# Creates a new `ImageTexture` and initializes it by allocating and setting the data from an `Image`
		var new_texture = ImageTexture.create_from_image(image)

		# Set _this_ node's Texture2D resource
		
		textureNode.call_deferred("set_texture2", new_texture)
	await  get_tree().create_timer(0.01).timeout
	summonElias(textureNode)
func _ready() -> void:
	thread = Thread.new()
	# You can bind multiple arguments to a function Callable.
	thread.start(summonElias.bind($Sprite2D))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
