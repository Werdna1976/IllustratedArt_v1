extends SceneTree
## Writes the default move sets (M2 plan, Task 4) to data/moves/. Run once; tune the .tres
## files in the inspector afterwards (re-running overwrites them).
## usage: godot --headless --path . --script res://tools/make_moves.gd

# id: [startup, active, recovery, damage, stagger, knockback, hit_stop, cancel_from, next, hitbox_offset, hitbox_size, extra]
const PLAYER := {
	"light1": [.08, .08, .18, 10, 10, Vector2(2, 0), .05, .14, "light2", Vector2(0.9, 1.0), Vector2(1.2, 0.8), {}],
	"light2": [.08, .08, .20, 10, 10, Vector2(2, 0), .05, .14, "light3", Vector2(0.9, 1.0), Vector2(1.2, 0.8), {}],
	"light3": [.12, .10, .30, 16, 18, Vector2(5, 0), .08, -1, "", Vector2(1.0, 1.0), Vector2(1.4, 1.0), {}],
	"heavy": [.30, .12, .40, 25, 35, Vector2(7, 1), .12, -1, "", Vector2(1.1, 1.0), Vector2(1.6, 1.2), {}],
	"launcher": [.18, .10, .35, 12, 15, Vector2(0.5, 11), .08, -1, "", Vector2(0.8, 1.2), Vector2(1.2, 1.6), {}],
	"air_light": [.06, .10, .15, 8, 8, Vector2(1, 3), .05, .12, "air_light", Vector2(0.8, 0.9), Vector2(1.2, 1.0), {"airborne_only": true}],
	"finisher": [.10, .20, .50, 100, 0, Vector2(6, 2), .20, -1, "", Vector2(1.0, 1.0), Vector2(1.8, 1.4), {"requires_staggered_target": true}],
	"parry": [.02, .15, .25, 0, 0, Vector2.ZERO, 0, -1, "", Vector2.ZERO, Vector2.ZERO, {"is_parry": true}],
	"dodge": [0, .25, .12, 0, 0, Vector2.ZERO, 0, -1, "", Vector2.ZERO, Vector2.ZERO, {"is_dodge": true, "dash_speed": 12.0}],
}
const OFFICER := {
	"officer_attack": [.15, .10, .50, 12, 0, Vector2(4, 0), .06, -1, "", Vector2(0.9, 1.0), Vector2(1.2, 0.8), {}],
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/moves")
	var ok := _save(PLAYER, "res://data/moves/player.tres") and _save(OFFICER, "res://data/moves/officer.tres")
	quit(0 if ok else 1)


func _save(table: Dictionary, path: String) -> bool:
	var set := MoveSet.new()
	for id: String in table:
		var r: Array = table[id]
		var m := MoveData.new()
		m.id = id
		m.anim = id
		m.startup = r[0]
		m.active = r[1]
		m.recovery = r[2]
		m.damage = r[3]
		m.stagger = r[4]
		m.knockback = r[5]
		m.hit_stop = r[6]
		m.cancel_from = r[7]
		m.next_combo = r[8]
		m.hitbox_offset = r[9]
		m.hitbox_size = r[10]
		for key: String in r[11]:
			m.set(key, r[11][key])
		set.moves.append(m)
	var err := ResourceSaver.save(set, path)
	print("saved %s (%s)" % [path, error_string(err)])
	return err == OK
