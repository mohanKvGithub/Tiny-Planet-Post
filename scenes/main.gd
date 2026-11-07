extends Node2D

const PLANET_CENTER := Vector2(480.0, 300.0)
const PLANET_RADIUS := 155.0
const PLAYER_STANDOFF := 19.0
const RUN_SPEED := 170.0
const JUMP_SPEED := 390.0
const GRAVITY := 980.0
const PARCEL_ANGLE := -PI / 2.0
const HOUSE_ANGLE := PI / 2.0
const INTERACTION_DISTANCE := 42.0

var player_angle := PARCEL_ANGLE - 0.35
var player_radius := PLANET_RADIUS + PLAYER_STANDOFF
var radial_speed := 0.0
var carrying_parcel := false
var delivered := false
var jump_was_pressed := false
var interact_was_pressed := false

var star_positions: Array[Vector2] = [
	Vector2(96, 82), Vector2(203, 133), Vector2(332, 65), Vector2(592, 94),
	Vector2(766, 133), Vector2(865, 68), Vector2(112, 427), Vector2(799, 435),
]


func _process(_delta: float) -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	var move_direction := _get_move_direction()
	player_angle = wrapf(player_angle + move_direction * RUN_SPEED / player_radius * delta, -PI, PI)

	var jump_pressed := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP)
	if jump_pressed and not jump_was_pressed and _is_grounded():
		radial_speed = JUMP_SPEED
	jump_was_pressed = jump_pressed

	if not _is_grounded() or radial_speed > 0.0:
		player_radius += radial_speed * delta
		radial_speed -= GRAVITY * delta
		if player_radius <= PLANET_RADIUS + PLAYER_STANDOFF:
			player_radius = PLANET_RADIUS + PLAYER_STANDOFF
			radial_speed = 0.0

	var interact_pressed := Input.is_key_pressed(KEY_E)
	if interact_pressed and not interact_was_pressed:
		_interact()
	interact_was_pressed = interact_pressed

	queue_redraw()


func _get_move_direction() -> float:
	var left_pressed := Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right_pressed := Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	return float(right_pressed) - float(left_pressed)


func _is_grounded() -> bool:
	return is_zero_approx(radial_speed) and is_equal_approx(player_radius, PLANET_RADIUS + PLAYER_STANDOFF)


func _interact() -> void:
	if delivered or not _is_grounded():
		return
	if not carrying_parcel and _is_near_angle(PARCEL_ANGLE):
		carrying_parcel = true
	elif carrying_parcel and _is_near_angle(HOUSE_ANGLE):
		carrying_parcel = false
		delivered = true


func _is_near_angle(target_angle: float) -> bool:
	var arc_distance := absf(wrapf(player_angle - target_angle, -PI, PI)) * PLANET_RADIUS
	return arc_distance <= INTERACTION_DISTANCE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color("101a32"))
	for star in star_positions:
		draw_circle(star, 2.0, Color("c8d7ed", 0.8))

	draw_circle(PLANET_CENTER, PLANET_RADIUS + 5.0, Color("41684f"))
	draw_circle(PLANET_CENTER, PLANET_RADIUS, Color("6ea86e"))
	draw_arc(PLANET_CENTER, PLANET_RADIUS + 2.0, 0.0, TAU, 96, Color("a6d58a"), 3.0)
	_draw_planet_details()
	_draw_house()
	if not carrying_parcel and not delivered:
		_draw_parcel()
	_draw_courier()
	_draw_hud()


func _draw_planet_details() -> void:
	draw_circle(PLANET_CENTER + Vector2(-38, -42), 20.0, Color("78b477"))
	draw_circle(PLANET_CENTER + Vector2(45, 38), 26.0, Color("78b477"))
	draw_circle(PLANET_CENTER + Vector2(12, -78), 12.0, Color("85bf7a"))


func _draw_parcel() -> void:
	var radial := Vector2(cos(PARCEL_ANGLE), sin(PARCEL_ANGLE))
	var parcel_position := PLANET_CENTER + radial * (PLANET_RADIUS + 7.0)
	draw_set_transform(parcel_position, PARCEL_ANGLE + PI / 2.0)
	draw_rect(Rect2(-9, -9, 18, 18), Color("f2b84b"))
	draw_line(Vector2(-8, -1), Vector2(8, -1), Color("fff0b3"), 2.0)
	draw_line(Vector2(0, -8), Vector2(0, 8), Color("fff0b3"), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0)


func _draw_house() -> void:
	var radial := Vector2(cos(HOUSE_ANGLE), sin(HOUSE_ANGLE))
	var house_position := PLANET_CENTER + radial * (PLANET_RADIUS + 2.0)
	draw_set_transform(house_position, HOUSE_ANGLE + PI / 2.0)
	draw_rect(Rect2(-17, -23, 34, 25), Color("f4e6c5"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, -21), Vector2(0, -40), Vector2(22, -21),
	]), Color("d86f62"))
	draw_rect(Rect2(-5, -12, 10, 14), Color("8a6451"))
	draw_circle(Vector2(0, -31), 3.5, Color("f2b84b"))
	draw_set_transform(Vector2.ZERO, 0.0)


func _draw_courier() -> void:
	var radial := Vector2(cos(player_angle), sin(player_angle))
	var player_position := PLANET_CENTER + radial * player_radius
	draw_set_transform(player_position, player_angle + PI / 2.0)
	draw_circle(Vector2(0, 4), 10.0, Color("4164a8"))
	draw_rect(Rect2(-7, -3, 14, 17), Color("557fd0"))
	draw_circle(Vector2(0, -10), 7.0, Color("f3c69b"))
	draw_circle(Vector2(0, -11), 7.0, Color("55463f"))
	draw_circle(Vector2(2.5, -10), 1.0, Color("26334b"))
	if carrying_parcel:
		draw_rect(Rect2(8, -2, 9, 9), Color("f2b84b"))
	draw_set_transform(Vector2.ZERO, 0.0)


func _draw_hud() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(28, 38), "TINY PLANET POST", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f5f1df"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 64), "A / D or arrows: move     Space / Up: jump     E: interact", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("c7d6e8"))

	var objective := "Find the parcel and press E" if not carrying_parcel and not delivered else "Take the parcel to the marked house" if not delivered else "Delivery complete! Nice work!"
	draw_string(ThemeDB.fallback_font, Vector2(28, 96), objective, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("ffe19a") if not delivered else Color("a6e6a1"))

	var prompt := "E  Pick up parcel" if not carrying_parcel and not delivered and _is_near_angle(PARCEL_ANGLE) else "E  Deliver parcel" if carrying_parcel and not delivered and _is_near_angle(HOUSE_ANGLE) else ""
	if not prompt.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(PLANET_CENTER.x - 70, PLANET_CENTER.y - PLANET_RADIUS - 28), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffffff"))

	if delivered:
		draw_rect(Rect2(342, 222, 276, 86), Color(0.06, 0.11, 0.18, 0.9), true)
		draw_string(ThemeDB.fallback_font, Vector2(379, 259), "PARCEL DELIVERED!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("a6e6a1"))
		draw_string(ThemeDB.fallback_font, Vector2(390, 285), "Prototype complete", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f5f1df"))
