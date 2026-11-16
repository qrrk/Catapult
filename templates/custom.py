# SCons build configuration for size-optimized Godot release export templates.
# Pass via: scons platform=<linuxbsd|windows> profile=path/to/custom.py

target = "template_release"
optimize = "size_extra"
lto = "full"
debug_symbols = "no"

# Rendering, drivers, and core subsystems
vulkan = "no"
d3d12 = "no"
accesskit = "no"
disable_3d = "yes"
disable_physics_2d = "yes"
disable_physics_3d = "yes"
disable_navigation_2d = "yes"
disable_navigation_3d = "yes"
disable_xr = "yes"

# 3D / XR / Physics / Nav modules
module_camera_enabled = "no"
module_csg_enabled = "no"
module_fbx_enabled = "no"
module_gltf_enabled = "no"
module_glslang_enabled = "no"
module_godot_physics_2d_enabled = "no"
module_godot_physics_3d_enabled = "no"
module_gridmap_enabled = "no"
module_jolt_physics_enabled = "no"
module_lightmapper_rd_enabled = "no"
module_meshoptimizer_enabled = "no"
module_mobile_vr_enabled = "no"
module_navigation_2d_enabled = "no"
module_navigation_3d_enabled = "no"
module_noise_enabled = "no"
module_openxr_enabled = "no"
module_raycast_enabled = "no"
module_vhacd_enabled = "no"
module_visual_shader_enabled = "no"
module_xatlas_unwrap_enabled = "no"

# Audio & video (audio driver is Dummy)
module_interactive_music_enabled = "no"
module_mp3_enabled = "no"
module_ogg_enabled = "no"
module_theora_enabled = "no"
module_vorbis_enabled = "no"

# Unused networking & scripting
module_enet_enabled = "no"
module_jsonrpc_enabled = "no"
module_mono_enabled = "no"
module_multiplayer_enabled = "no"
module_objectdb_profiler_enabled = "no"
module_upnp_enabled = "no"
module_webrtc_enabled = "no"
module_websocket_enabled = "no"

# Unused 3D/VRAM texture codecs (keeps png, svg, jpg, webp)
module_astcenc_enabled = "no"
module_basis_universal_enabled = "no"
module_bcdec_enabled = "no"
module_betsy_enabled = "no"
module_bmp_enabled = "no"
module_cvtt_enabled = "no"
module_dds_enabled = "no"
module_etcpak_enabled = "no"
module_hdr_enabled = "no"
module_ktx_enabled = "no"
module_tga_enabled = "no"
module_tinyexr_enabled = "no"

# Optional later experiment (verify CJK/localized text wrapping if enabled):
# module_text_server_adv_enabled = "no"
# module_text_server_fb_enabled = "yes"
