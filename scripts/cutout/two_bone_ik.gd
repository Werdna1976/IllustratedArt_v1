class_name TwoBoneIK
extends RefCounted
## Analytic two-bone IK in 2D screen space (y down). Returns the global angles of both segments
## (0 = +x). Unreachable targets get a straight reach toward the target.


static func solve(root: Vector2, target: Vector2, len_a: float, len_b: float, bend: float) -> PackedFloat32Array:
	var to_target := target - root
	var base := to_target.angle()
	var d := to_target.length()
	if d >= len_a + len_b - 1e-4 or d < 1e-4:
		return PackedFloat32Array([base, base])
	var cos_a := clampf((len_a * len_a + d * d - len_b * len_b) / (2.0 * len_a * d), -1.0, 1.0)
	var upper := base - bend * acos(cos_a)
	var elbow := root + Vector2.from_angle(upper) * len_a
	return PackedFloat32Array([upper, (target - elbow).angle()])
