extends Node

# How quickly to interpolate - higher = snappier but less smooth
const INTERPOLATION_SPEED := 15.0

var target_position: Vector3
var target_rotation: Vector3
var initialized := false

func _ready():
	# Only run on remote players
	if get_parent().is_multiplayer_authority():
		set_process(false)
		return
	
	target_position = get_parent().global_position
	target_rotation = get_parent().global_rotation
	initialized = true

func _process(delta):
	if not initialized:
		target_position = get_parent().global_position
		target_rotation = get_parent().global_rotation
		initialized = true
		return
	
	# Smoothly move toward the synced position
	get_parent().global_position = get_parent().global_position.lerp(
		target_position, 
		INTERPOLATION_SPEED * delta
	)
	
	# Smoothly rotate toward the synced rotation
	get_parent().global_rotation = Vector3(
		lerp_angle(get_parent().global_rotation.x, target_rotation.x, INTERPOLATION_SPEED * delta),
		lerp_angle(get_parent().global_rotation.y, target_rotation.y, INTERPOLATION_SPEED * delta),
		lerp_angle(get_parent().global_rotation.z, target_rotation.z, INTERPOLATION_SPEED * delta)
	)

func update_target(pos: Vector3, rot: Vector3):
	# If too far away, snap instead of interpolate
	if get_parent().global_position.distance_to(pos) > 5.0:
		get_parent().global_position = pos
		get_parent().global_rotation = rot
	target_position = pos
	target_rotation = rot
