class_name TestCase
extends RefCounted
## Base class for tests run by tests/run_tests.gd. Record failures with the assert_* helpers;
## nodes added with add_node() are freed after the test.

var tree: SceneTree
var failures: PackedStringArray = []
var _nodes: Array[Node] = []


func add_node(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes.append(node)
	return node


func free_nodes() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	_nodes.clear()


func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected <%s>, got <%s>" % [msg, expected, actual])


func assert_near(actual: float, expected: float, tol: float, msg: String) -> void:
	if absf(actual - expected) > tol:
		failures.append("%s: expected %s ± %s, got %s" % [msg, expected, tol, actual])


func assert_color_near(actual: Color, expected: Color, msg: String, tol: float = 0.01) -> void:
	var diff := maxf(maxf(absf(actual.r - expected.r), absf(actual.g - expected.g)),
			maxf(absf(actual.b - expected.b), absf(actual.a - expected.a)))
	if diff > tol:
		failures.append("%s: expected %s, got %s" % [msg, expected, actual])
