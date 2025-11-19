extends EnemyState
class_name EnemyRetreat

@export_category("Movement")
@export var move_speed: float = 40.0
@export var uses_stamina: bool = true
@export var stamina_min_to_retreat: float = 10.0

@export_category("State transitions")
@export var attack_state: EnemyState        # where to go when retreat area is exited (e.g. Attack)
@export var wander_state: EnemyState        # where to go if player is dead / invalid
@export var knockback_state: EnemyState
@export var dead_state: EnemyState          # optional, falls back to state_machine.dead_state

@export_category("Areas")
@export var retreat_area: Area2D            # optional; will fall back to enemy.RetreatArea if null

@export_category("On hit behaviour (optional)")
@export var reset_cooldown_on_hit: bool = true      # if enemy has `inCooldown`
@export var auto_throw_on_hit: bool = true          # if enemy has `throw()`
@export var throw_charge_time: float = 0.6

var player: CharacterBody2D
var _queued_state: EnemyState = null
var _area_connected: bool = false


func enter(previous_state: EnemyState) -> void:
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	_connect_retreat_area()

	# Usually, if we are retreating, we are not "attacking" anymore
	if enemy and "isAttacking" in enemy:
		enemy.isAttacking = false


func exit() -> void:
	_queued_state = null


func physics_update(_delta: float) -> EnemyState:
	if enemy == null:
		return null

	var global_dead: EnemyState = dead_state if dead_state != null else state_machine.dead_state

	# --- death ---
	if "dead" in enemy and enemy.dead and global_dead:
		if "isAttacking" in enemy:
			enemy.isAttacking = false
		return global_dead

	# --- hit / knockback ---
	if "hit" in enemy and enemy.hit and knockback_state:
		if reset_cooldown_on_hit and "inCooldown" in enemy:
			enemy.inCooldown = false
		if auto_throw_on_hit and enemy.has_method("throw"):
			enemy.throw(throw_charge_time)
		return knockback_state

	# --- invalid / dead player -> Wander (if configured) ---
	if not _player_valid():
		if wander_state:
			if "isAttacking" in enemy:
				enemy.isAttacking = false
			return wander_state
		return null

	# --- deferred transition from area signal ---
	if _queued_state:
		var target := _queued_state
		_queued_state = null
		return target

	# --- respect idle / transition lock flags if enemy uses them ---
	if ("idle" in enemy and enemy.idle) or ("transitionLocked" in enemy and enemy.transitionLocked):
		if "velocity" in enemy:
			enemy.velocity = Vector2.ZERO
		return null

	# --- face away and move away from player ---
	if enemy.sprite:
		# flip so visually he faces away from player (like your original)
		enemy.sprite.flip_h = player.global_position.x > enemy.global_position.x

	var direction := (enemy.global_position - player.global_position)

	# optional stamina UI
	if "stamina_bar" in enemy and enemy.stamina_bar:
		enemy.stamina_bar.value = enemy.current_stamina

	# stamina logic
	if uses_stamina and "current_stamina" in enemy:
		if enemy.current_stamina > stamina_min_to_retreat:
			if "timer_stamina_regen" in enemy and enemy.timer_stamina_regen:
				enemy.timer_stamina_regen.stop()
		else:
			if "timer_stamina_regen_start" in enemy and enemy.timer_stamina_regen_start:
				if enemy.timer_stamina_regen_start.is_stopped():
					enemy.timer_stamina_regen_start.start()

	# movement
	if "velocity" in enemy:
		enemy.velocity = direction.normalized() * move_speed

	return null


# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

func _connect_retreat_area() -> void:
	if _area_connected:
		return
	_area_connected = true

	var area := retreat_area
	if area == null and enemy and enemy.has_node("RetreatArea"):
		area = enemy.get_node("RetreatArea") as Area2D

	if area and not area.is_connected("body_exited", Callable(self, "_on_retreat_area_exited")):
		area.connect("body_exited", Callable(self, "_on_retreat_area_exited"))


func _on_retreat_area_exited(body: Node) -> void:
	# Player is no longer "too close" -> go back to attack state if set
	if body.is_in_group("Player") and attack_state:
		_queued_state = attack_state


func _player_valid() -> bool:
	return player != null and player.current_health > 0
