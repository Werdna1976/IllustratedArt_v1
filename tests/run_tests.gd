extends SceneTree
## Headless test runner (use tools/run_tests.sh). Runs every test_* method of every
## res://tests/*_test.gd on a fresh instance. A test fails if it records an assert failure
## or if the engine logs any error while it runs. Exit code 0 = all passed, 1 = any failure.


class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String,
			_rationale: String, _editor_notify: bool, error_type: int,
			_script_backtrace: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			count += 1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var passed := 0
	var failed := 0
	var files := Array(DirAccess.get_files_at("res://tests")).filter(
			func(f: String) -> bool: return f.ends_with("_test.gd"))
	files.sort()
	for file: String in files:
		var script: GDScript = load("res://tests/" + file)
		if script == null or not script.can_instantiate():
			failed += 1
			printerr("FAIL %s: script failed to load" % file)
			continue
		for method in script.get_script_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_"):
				continue
			var errors_before := errors.count
			var t: TestCase = script.new()
			t.tree = self
			await t.call(test_name)
			t.free_nodes()
			await process_frame
			if errors.count > errors_before:
				t.failures.append("engine logged %d error(s) during the test" % (errors.count - errors_before))
			if t.failures.is_empty():
				passed += 1
			else:
				failed += 1
				printerr("FAIL %s::%s" % [file, test_name])
				for f in t.failures:
					printerr("    " + f)
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
