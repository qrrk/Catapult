class_name ScalingDPITexture
extends DPITexture


func _init() -> void:
	
	Geom.connect("scale_changed", func(new_scale):
		base_scale = new_scale
	)
