class_name RigSpec
extends RefCounted
## Checks a character's packed parts against the shared skeleton before a rig is built.


## Required skeleton parts (and variants) absent from a character's parts.json.
static func missing_parts(skeleton: Dictionary, rects: Dictionary) -> PackedStringArray:
	var missing := PackedStringArray()
	for spec: Dictionary in skeleton.nodes:
		if spec.get("optional", false):
			continue
		for part: String in spec.get("variants", [spec.part]):
			if not rects.has(part) and not part in missing:
				missing.append(part)
	return missing
