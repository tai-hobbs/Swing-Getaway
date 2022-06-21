extends VehicleBody

const MAX_STEER_ANGLE = 0.35
const STEER_SPEED = 1
const MAX_ENGINE_FORCE = 175
const MAX_BRAKE_FORCE = 10
const MAX_SPEED = 35

var steer_target = 0.0 #where the player wants the wheels to go?
var steer_angle = 0.0  #where the wheels currently are

sync var players = {}
var playerData = {"steer": 0, "engine": 0, "brakes": 0, "position": null}

func _ready():
	players[name] = playerData
	players[name].position = transform
	
	if not is_local_player():
		$Camera.queue_free()

func is_local_player():
	return name == str(Network.localPLayerId)

func _physics_process(delta):
	if is_local_player():
		drive(delta)
	if not Network.localPLayerId == 1:
		transform = players[name].position
	
	steering = players[name].steer
	engine_force = players[name].engine
	brake = players[name].brakes

func drive(delta):
	var steering_value = apply_steering(delta)
	var throttle = apply_throttle()
	var brakes = apply_brakes()
	
	update_server(name, steering_value, throttle, brakes)

func apply_steering(delta):
	var steer_val = 0
	var left = Input.get_action_strength("steer_left")
	var right = Input.get_action_strength("steer_right")
	
	if left:
		steer_val = left
	elif right:
		steer_val = -right
	
	steer_target = steer_val * MAX_STEER_ANGLE
	
	if steer_target < steer_angle:
		steer_angle -= STEER_SPEED * delta
	elif steer_target > steer_angle:
		steer_angle += STEER_SPEED * delta
	
	return steer_angle

func apply_throttle():
	var throttle_val = 0
	var forward = Input.get_action_strength("accelerate")
	var reverse = Input.get_action_strength("reverse")
	
	if linear_velocity.length() < MAX_SPEED:
		if reverse:
			throttle_val = -reverse
		elif forward:
			throttle_val = forward
	
	return throttle_val * MAX_ENGINE_FORCE

func apply_brakes():
	var brake_val = 0
	var brake_strength = Input.get_action_strength("brake")
	
	if brake_strength:
		brake_val = brake_strength

	return brake_val * MAX_BRAKE_FORCE
		
func update_server(id, steering_value, throttle, brakes):
	if not Network.localPLayerId == 1:
		rpc_unreliable_id(1, "manage_clients", id, steering_value, throttle, brakes)
	else:
		manage_clients(id, steering_value, throttle, brakes)

sync func manage_clients(id, steering_value, throttle, brakes):
	players[id].steer = steering_value
	players[id].engine = throttle
	players[id].brake = brakes
	players[id].position = transform
	rset_unreliable("players", players)
