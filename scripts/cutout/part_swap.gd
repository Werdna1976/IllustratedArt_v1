class_name PartSwap
extends Sprite2D
## A cutout part with interchangeable variants (open/fist/grip hands, neutral/attack/hurt heads).
## Setting `variant` (e.g. from an animation track) switches the atlas region and pivot offset;
## CutoutMirror picks the new region up on its next sync.

@export var variants: Dictionary = {} ## StringName -> Rect2 in the parts sheet
@export var offsets: Dictionary = {} ## StringName -> Vector2 sprite offset for that variant's pivot
@export var variant: StringName = &"":
	set(value):
		variant = value
		if variants.has(value):
			region_rect = variants[value]
		if offsets.has(value):
			offset = offsets[value]
