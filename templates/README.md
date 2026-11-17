# Custom Export Templates

This directory holds size-optimized Godot `template_release` binaries built from upstream Godot source using `custom.py`.
Rebuild these templates when changing the project's target Godot version or updating build flags, then point `custom_template/release` in `export_presets.cfg` to the compiled binaries.

- **Current version:** 4.7.2

## What is Customized

Current `custom.py` builds with LTO, optimizes for executable size, and strips out engine subsystems that Catapult does not use:

- Vulkan, Direct3D 12, 3D, Physics, Navigation, and XR
- Audio & Video
- Multiplayer & Extra Networking
- AccessKit, Mono, and 3D/VRAM Texture Codecs

Kept enabled because Catapult relies on them:
- `advanced_gui`
- `mbedtls`
- `regex`
- `svg`
- `zip`
- `freetype`/`msdfgen`
- `text_server_adv`

## Building

Clone the matching Godot release tag outside this repository:

```bash
git clone --depth 1 --branch 4.7.2-stable https://github.com/godotengine/godot.git
```

### Windows

Requires **Python 3**, **SCons 4.4+** (`pip install scons`), and **Visual Studio 2022** with the *Desktop development with C++* workload.

1. Open **x64 Native Tools Command Prompt for VS 2022**.
2. From the Godot source root, run:
   ```cmd
   scons platform=windows profile=path\to\Catapult\templates\custom.py -j%NUMBER_OF_PROCESSORS%
   ```
3. Copy `bin\godot.windows.template_release.x86_64.exe` here as `windows_release_x86_64.exe`.

### Linux

Tested on **Ubuntu 22.04** (recommended for broad `glibc` compatibility).

1. Install build dependencies and SCons 4.4+ (Ubuntu 22.04's `apt` package is too old):
   ```bash
   sudo apt-get update
   sudo apt-get install -y build-essential pkg-config python3-pip \
       libx11-dev libxcursor-dev libxi-dev libxinerama-dev libxrandr-dev \
       libxext-dev libgl1-mesa-dev libglu1-mesa-dev libasound2-dev \
       libpulse-dev libudev-dev libwayland-dev libxkbcommon-dev
   pip3 install --user --upgrade scons
   ```
2. From the Godot source root, run:
   ```bash
   ~/.local/bin/scons platform=linuxbsd profile=/path/to/Catapult/templates/custom.py -j$(nproc)
   ```
3. Copy `bin/godot.linuxbsd.template_release.x86_64` here as `linuxbsd_release.x86_64`.
