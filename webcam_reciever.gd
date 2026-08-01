extends Node3D

const CHANNEL_WEBCAM := 1

var frame_buffers := {}

func _process(_delta):
	if($"..".ingame):
		_poll_webcam_messages()

func _poll_webcam_messages():
	var messages = Steam.receiveMessagesOnChannel(CHANNEL_WEBCAM, 32)
	
	for msg in messages:
		print("message recieved")
		_handle_packet(msg.payload)

func _handle_packet(data: PackedByteArray):
	var sender_id    := data.decode_u32(0)
	var frame_id     := data.decode_u32(4)
	var chunk_idx    := data.decode_u16(8)
	var total_chunks := data.decode_u16(10)
	var chunk_data   := data.slice(12)
	
	if sender_id not in frame_buffers:
		frame_buffers[sender_id] = {}
	
	var frames: Dictionary = frame_buffers[sender_id]
	
	for old_id in frames.keys():
		if old_id < frame_id - 10:
			frames.erase(old_id)
	
	if frame_id not in frames:
		frames[frame_id] = {}
	
	frames[frame_id][chunk_idx] = chunk_data
	
	if frames[frame_id].size() == total_chunks:
		_assemble_frame(sender_id, frame_id, total_chunks)

func _assemble_frame(sender_id: int, frame_id: int, total_chunks: int):
	var full_bytes := PackedByteArray()
	for i in range(total_chunks):
		full_bytes.append_array(frame_buffers[sender_id][frame_id][i])
	frame_buffers[sender_id].erase(frame_id)
	
	var img := Image.new()
	img.load_webp_from_buffer(full_bytes)
	print(sender_id,"Sender Id")
	print(img)
	PlayerManager.update_player_screen(sender_id, img)
