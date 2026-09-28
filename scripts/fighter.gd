class_name Fighter
extends CharacterBody3D
## Shared body for the player and enemies (spec §5.6–5.7): capsule physics on the gameplay
## plane, a cutout visual mirrored from a 2D rig, move state machine, hit/hurtboxes, hit-stop
## and the blade signature light. Subclasses supply intent().

signal hit_landed(target: Fighter, result: Dictionary)
signal got_hit(result: Dictionary)
signal died ## Emitted once, when HP first reaches 0.

const RADIUS := 0.4
const HEIGHT := 1.8
const HURT_STUN := 0.3
const LAYER_WORLD := 1
const LAYER_ACTORS := 1 << 1 ## Actors collide with the world, not with each other.
const LAYER_HITBOX := 1 << 2
const LAYER_HURTBOX := 1 << 3
const BLADE_COLOR := Color("#39f3ff")
const BLADE_FLASH_ENERGY := 6.0
const BLADE_FLASH_TIME := 0.25
const KNOCKBACK_DECEL := 12.0 ## m/s² of slide while stunned, so hits visibly push.
const DEAD_STUN := 1e9 ## A dead fighter stays down until revive().
const SHAKE_PER_HIT_STOP := 3.0 ## Camera trauma per second of hit-stop (clamped 0.15-0.6).

var facing := 1.0 ## +1 right, -1 left; read by CameraRig for look-ahead.
var vitals: Vitals
var combat := CombatFighter.new()
var is_network := false ## Network-controlled enemies trigger the blade signature light.
var visual: Node3D
var rig: Node2D
var anim: AnimationPlayer
var mirror: CutoutMirror
var hitbox: Area3D
var hurtbox: Area3D
var blade_light: OmniLight3D

var _hitbox_shape: CollisionShape3D
var _dead := false


func build(rig_scene: PackedScene, albedo: Texture2D, normal: Texture2D, emissive: Texture2D,
		move_set: MoveSet, hp: float, stagger: float) -> void:
	axis_lock_linear_z = true
	collision_layer = LAYER_ACTORS
	collision_mask = LAYER_WORLD
	add_child(_capsule_shape())
	vitals = Vitals.make(hp, stagger)
	combat.moves = move_set
	visual = Node3D.new()
	visual.name = "Visual"
	visual.position = Vector3(0.0, -HEIGHT * 0.5, WorldSpec.ACTOR_Z)
	add_child(visual)
	rig = rig_scene.instantiate()
	rig.visible = false
	add_child(rig)
	anim = rig.get_node("AnimationPlayer")
	mirror = CutoutMirror.new()
	visual.add_child(mirror)
	mirror.setup(rig, albedo, normal, emissive)
	hurtbox = Area3D.new()
	hurtbox.collision_layer = LAYER_HURTBOX
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.add_child(_capsule_shape())
	add_child(hurtbox)
	hitbox = Area3D.new()
	hitbox.collision_layer = LAYER_HITBOX
	hitbox.collision_mask = LAYER_HURTBOX
	hitbox.monitorable = false
	_hitbox_shape = CollisionShape3D.new()
	_hitbox_shape.shape = BoxShape3D.new()
	_hitbox_shape.disabled = true
	hitbox.add_child(_hitbox_shape)
	add_child(hitbox)
	blade_light = OmniLight3D.new()
	blade_light.light_color = BLADE_COLOR
	blade_light.omni_range = 4.0
	blade_light.light_energy = 0.0
	blade_light.position = Vector3(0.8, 1.1, 0.3)
	visual.add_child(blade_light)


## Virtual: what this fighter wants to do this physics frame.
func intent() -> Dictionary:
	return {"x": 0.0, "jump": false, "action": &""}


## attacker may be null (environmental damage, tests).
func receive_hit(result: Dictionary, _attacker: Fighter) -> void:
	if _dead:
		return
	var was_staggered := vitals.is_staggered()
	vitals.take(result.damage, result.stagger)
	var kb: Vector2 = result.knockback
	if kb != Vector2.ZERO:
		velocity = Vector3(kb.x, kb.y, 0.0)
	_set_hitbox(false)
	if vitals.is_staggered() and not was_staggered:
		combat.stun(Vitals.STAGGERED_TIME)
		_play(&"staggered")
	elif not vitals.is_staggered():
		combat.stun(HURT_STUN)
		_play(&"hurt")
	got_hit.emit(result)
	if vitals.is_dead():
		# Last, so nothing above overrides the death stun.
		_dead = true
		combat.stun(DEAD_STUN)
		_play(&"staggered")
		died.emit()


## Back to full health, free to act (respawn).
func revive() -> void:
	_dead = false
	vitals.reset()
	combat.stun(0.0)
	velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	vitals.advance(delta)
	for event in combat.advance(delta):
		_on_event(event)
	var want := intent()
	var move := combat.current
	var locked := combat.is_stunned() or (move != null and not move.is_dodge and combat.phase() <= MoveData.Phase.ACTIVE)
	var x: float = 0.0 if locked else want.x
	if x != 0.0 and move == null:
		facing = signf(x)
	var jump: bool = want.jump and move == null and not combat.is_stunned()
	var slide_x := velocity.x
	velocity = PlayerMotor.step(velocity, x, jump, is_on_floor(), delta)
	if combat.is_stunned():
		velocity.x = move_toward(slide_x, 0.0, KNOCKBACK_DECEL * delta)
	if move and move.is_dodge and combat.phase() == MoveData.Phase.ACTIVE:
		velocity.x = move.dash_speed * facing
	if want.action != &"":
		combat.request(want.action, not is_on_floor())
	visual.scale.x = facing
	if not _hitbox_shape.disabled:
		_check_hits()
	move_and_slide()
	_update_base_anim()


func _on_event(event: StringName) -> void:
	if event.begins_with("started:"):
		_set_hitbox(false)
		_play(combat.current.anim)
	elif event == &"active_start":
		var move := combat.current
		if move.hitbox_size != Vector2.ZERO:
			(_hitbox_shape.shape as BoxShape3D).size = Vector3(move.hitbox_size.x, move.hitbox_size.y, 1.0)
			# hitbox_offset.y is measured up from the feet; the body origin is the capsule centre.
			_hitbox_shape.position = Vector3(move.hitbox_offset.x * facing, move.hitbox_offset.y - HEIGHT * 0.5, 0.0)
			_set_hitbox(true)
	elif event == &"active_end" or event == &"done":
		_set_hitbox(false)


func _check_hits() -> void:
	var move := combat.current
	if move == null:
		_set_hitbox(false)
		return
	for area in hitbox.get_overlapping_areas():
		var target := area.get_parent() as Fighter
		if target == null or target == self or combat.hit_this_move.has(target):
			continue
		combat.hit_this_move[target] = true
		var result := HitResolver.resolve(move, global_position.x, facing, target.global_position.x,
				target.facing, target.combat.is_parrying(), target.combat.is_invulnerable())
		match result.outcome:
			HitResolver.Outcome.HIT:
				target.receive_hit(result, self)
				HitStop.trigger(get_tree(), move.hit_stop)
				get_tree().call_group(&"camera_rig", &"add_trauma", clampf(move.hit_stop * SHAKE_PER_HIT_STOP, 0.15, 0.6))
				if target.is_network:
					_flash_blade()
				hit_landed.emit(target, result)
			HitResolver.Outcome.PARRIED:
				combat.stun(HitResolver.PARRY_STUN)
				_set_hitbox(false)
				_play(&"hurt")
				target._flash_blade()
				return


func _flash_blade() -> void:
	blade_light.light_energy = BLADE_FLASH_ENERGY
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(blade_light, "light_energy", 0.0, BLADE_FLASH_TIME)


func _set_hitbox(on: bool) -> void:
	_hitbox_shape.disabled = not on


func _update_base_anim() -> void:
	if combat.current or combat.is_stunned():
		return
	var want := &"idle"
	if not is_on_floor():
		want = &"jump" if velocity.y > 0.0 else &"fall"
	elif absf(velocity.x) > 0.5:
		want = &"run"
	if anim.current_animation != want:
		anim.play(want)


func _play(anim_name: StringName) -> void:
	anim.play(anim_name)
	anim.seek(0.0, true)


static func _capsule_shape() -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	shape.shape = capsule
	return shape
