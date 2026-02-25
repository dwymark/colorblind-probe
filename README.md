# Colorblind Probe

A webcam-based indicator light detector. Point a camera at an indicator light, draw a region of interest around it, and the app continuously reports whether the light is green, red, or off.

Built as a single HTML file wrapped in [Tauri](https://v2.tauri.app/) for desktop distribution.

## Building

### Prerequisites

- [Rust](https://rustup.rs/) toolchain
- Tauri CLI: `cargo install tauri-cli --version "^2"`

### Linux

Install system dependencies (Ubuntu/Debian):

```bash
sudo apt-get install -y libwebkit2gtk-4.1-dev build-essential curl wget file \
  libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev \
  libgtk-3-dev libsoup-3.0-dev libjavascriptcoregtk-4.1-dev
```

Build:

```bash
cargo tauri build
```

Outputs in `src-tauri/target/release/bundle/` — `.deb`, `.rpm`, and `.AppImage`.

### Windows (from WSL)

The `beforeBuildCommand` in `tauri.conf.json` uses Unix commands, so building for Windows requires a few manual steps.

1. Install Rust on the **Windows side** (if not already installed):

   ```bash
   powershell.exe -Command 'Invoke-WebRequest -Uri "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe" -OutFile "$env:TEMP\rustup-init.exe"; Start-Process -FilePath "$env:TEMP\rustup-init.exe" -ArgumentList "-y" -Wait -NoNewWindow'
   ```

2. Install the Tauri CLI on the Windows side:

   ```bash
   powershell.exe -Command '$env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"; cargo install tauri-cli --version "^2"'
   ```

3. Copy the project to the Windows filesystem (building across the WSL/Windows boundary is very slow):

   ```bash
   WIN_DIR="/mnt/c/Users/$USER/colorblind-probe-build"
   rm -rf "$WIN_DIR"
   mkdir -p "$WIN_DIR/src-tauri"
   cp index.html "$WIN_DIR/"
   cp -r src-tauri/Cargo.toml src-tauri/Cargo.lock src-tauri/build.rs \
         src-tauri/tauri.conf.json "$WIN_DIR/src-tauri/"
   cp -r src-tauri/src src-tauri/capabilities src-tauri/icons "$WIN_DIR/src-tauri/"
   ```

4. Prepare the frontend directory and clear the Unix-only build commands:

   ```bash
   mkdir -p "$WIN_DIR/frontend"
   cp "$WIN_DIR/index.html" "$WIN_DIR/frontend/index.html"

   # Blank out the beforeBuildCommand (uses Unix syntax)
   sed -i 's|"beforeBuildCommand":.*|"beforeBuildCommand": "",|' "$WIN_DIR/src-tauri/tauri.conf.json"
   sed -i 's|"beforeDevCommand":.*|"beforeDevCommand": ""|' "$WIN_DIR/src-tauri/tauri.conf.json"
   ```

5. Build:

   ```bash
   powershell.exe -Command '$env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"; cd C:\Users\'"$USER"'\colorblind-probe-build\src-tauri; cargo tauri build'
   ```

Outputs:
- `src-tauri/target/release/colorblind-probe.exe` — standalone executable
- `src-tauri/target/release/bundle/msi/Colorblind Probe_0.1.0_x64_en-US.msi` — installer

### Windows (native)

If building directly on Windows (not from WSL), install Rust and the Tauri CLI normally, create the `frontend/` directory with `index.html` copied into it, and run `cargo tauri build` from `src-tauri/`.

## Running without building

The app is a single HTML file. Serve it over localhost for webcam access:

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000`.

## Deploying to a remote server

```bash
./deploy.sh user@host [port]
```

Deploys `index.html` via SSH and installs a systemd service. Access via SSH tunnel for secure-context webcam access:

```bash
ssh -L 8122:localhost:8122 user@host
# Then open http://localhost:8122
```
