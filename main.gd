extends Node3D

const LANES = [-2.2, 0.0, 2.2]
var lane := 1
var speed := 10.0
var score := 0.0
var coins := 0
var alive := true
var spawn_time := 0.5
var player: MeshInstance3D
var camera: Camera3D
var hud: Label
var end_screen: Control
var end_label: Label
var objects: Array[MeshInstance3D] = []
var touch_start := Vector2.ZERO

func _ready() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(11, 180)
	ground.mesh = plane
	ground.position.z = -65
	ground.material_override = material(Color(0.14, 0.18, 0.23))
	add_child(ground)
	for x in [-3.4, -1.1, 1.1, 3.4]:
		var stripe := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.06, 0.02, 140)
		stripe.mesh = mesh
		stripe.position = Vector3(x, 0.02, -60)
		stripe.material_override = material(Color(0.4, 0.55, 0.68))
		add_child(stripe)
	player = MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(0.95, 0.95, 0.95)
	player.mesh = cube
	player.material_override = material(Color(0.1, 0.75, 1.0))
	add_child(player)
	camera = Camera3D.new()
	camera.position = Vector3(0, 5, 9)
	camera.rotation_degrees.x = -22
	add_child(camera)
	camera.current = true
	var ui := CanvasLayer.new()
	add_child(ui)
	hud = Label.new()
	hud.position = Vector2(20, 30)
	hud.add_theme_font_size_override("font_size", 35)
	ui.add_child(hud)
	end_screen = Control.new()
	end_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(end_screen)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.8)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_screen.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	end_screen.add_child(box)
	end_label = Label.new()
	end_label.add_theme_font_size_override("font_size", 38)
	box.add_child(end_label)
	var again := Button.new()
	again.text = "HRÁT ZNOVU"
	again.custom_minimum_size = Vector2(280, 95)
	again.pressed.connect(restart)
	box.add_child(again)
	restart()

func material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func restart() -> void:
	for item in objects:
		item.queue_free()
	objects.clear()
	lane = 1
	speed = 10.0
	score = 0.0
	coins = 0
	alive = true
	spawn_time = 0.4
	player.position = Vector3(0, 0.65, 0)
	end_screen.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not alive:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
		else:
			var dx: float = event.position.x - touch_start.x
			if absf(dx) > 40:
				move_lane(1 if dx > 0 else -1)
	if event.is_action_pressed("ui_left"):
		move_lane(-1)
	if event.is_action_pressed("ui_right"):
		move_lane(1)

func move_lane(direction: int) -> void:
	lane = clampi(lane + direction, 0, 2)

func _process(delta: float) -> void:
	if not alive:
		return
	speed = minf(speed + delta * 0.25, 26.0)
	score += speed * delta
	hud.text = "SKÓRE: %d   MINCE: %d" % [int(score), coins]
	player.position.x = lerpf(player.position.x, LANES[lane], minf(1.0, delta * 13))
	player.rotation.y += delta * 2
	camera.position.x = lerpf(camera.position.x, player.position.x * 0.35, minf(1.0, delta * 4))
	spawn_time -= delta
	if spawn_time <= 0:
		spawn_time = randf_range(0.65, 1.1)
		spawn_row()
	for item in objects.duplicate():
		item.position.z += speed * delta
		if item.position.z > 9:
			objects.erase(item)
			item.queue_free()
			continue
		if absf(item.position.z) < 0.85 and absf(item.position.x - player.position.x) < 0.95:
			if item.is_in_group("coin"):
				coins += 1
				score += 25
				objects.erase(item)
				item.queue_free()
			else:
				alive = false
				end_label.text = "KONEC HRY\nSkóre: %d | Mince: %d" % [int(score), coins]
				end_screen.show()
				break

func spawn_row() -> void:
	var safe := randi_range(0, 2)
	for i in range(3):
		if i != safe and randf() < 0.75:
			spawn_object(LANES[i], -55, false)
	if randf() < 0.65:
		for k in range(3):
			spawn_object(LANES[safe], -55 - k * 2.5, true)

func spawn_object(x: float, z: float, coin: bool) -> void:
	var item := MeshInstance3D.new()
	if coin:
		var mesh := SphereMesh.new()
		mesh.radius = 0.37
		mesh.height = 0.74
		item.mesh = mesh
		item.material_override = material(Color(1.0, 0.8, 0.1))
		item.add_to_group("coin")
	else:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.4, 1.5, 1.4)
		item.mesh = mesh
		item.material_override = material(Color(1.0, 0.22, 0.3))
	item.position = Vector3(x, 0.8, z)
	add_child(item)
	objects.append(item)
