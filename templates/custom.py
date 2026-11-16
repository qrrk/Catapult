# SCons build configuration for size-optimized Godot release export templates.
# Pass via: scons platform=<linuxbsd|windows> profile=path/to/custom.py

target = "template_release"
optimize = "size"
lto = "full"
debug_symbols = "no"

# Optional size reductions (verify against project usage before enabling):
# disable_3d = "yes"
# disable_advanced_gui = "yes"
# module_text_server_adv_enabled = "no"
# module_text_server_fb_enabled = "yes"
