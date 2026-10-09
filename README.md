# Spectrum Studio

<p align="center">
  <strong>Ultra-Fast Hardware-Accelerated Photo Viewer, RAW Inspector & Color Grading Studio for Windows</strong>
</p>

<p align="center">
  <a href="https://apps.microsoft.com/detail/9P1QW99KRX7N?hl=en-us&gl=IN&ocid=pdpshare">
    <img src="https://img.shields.io/badge/Microsoft%20Store-Download-0078D4?style=for-the-badge&logo=microsoft&logoColor=white" alt="Microsoft Store" />
  </a>
  <img src="https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-0078D4?style=for-the-badge" alt="Platform" />
  <img src="https://img.shields.io/badge/Version-0.1.1-22C55E?style=for-the-badge" alt="Version" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License" />
</p>

---

## 🌟 Overview

**Spectrum Studio** is a modern desktop photo viewer and creative studio engineered for photographers, designers, and enthusiasts. Combining the borderless minimalism of classic viewers with a high-performance 60/120 FPS rendering pipeline, Spectrum Studio delivers instant photo browsing across massive collections (4,000–5,000+ images), non-destructive color grading, and native Windows integration.

---

## ✨ Key Features

### 🖼️ Frameless Spatial Photo Viewer
- **Google Picasa-Inspired Borderless Canvas**: Edge-to-edge frameless viewing window with auto-hiding frosted glass HUD.
- **Continuous Physics Zoom Engine**: Analog momentum zoom with key-hold glide, continuous mouse wheel scaling, and instant pixel-perfect 1:1 Actual Size mode.
- **Authentic Quick Look Motion**: Smooth macOS-style stretch-to-point opening and closing bloom animations.
- **Spatial Thumbnail Strip & Loupe**: Non-stretching filmstrip carousel with neighborhood precaching and a live Loupe Navigator for inspecting ultra-high-resolution files.
- **Ambient Side-Peeks**: Contextual hover preview cards on screen borders for browsing upcoming and past images without losing focus.

### 🎨 Creative Darkroom & Image Editor
- **Interactive 8-Point Crop Engine**: Freeform mouse-drag box creation with hit-tested corner/edge handles, high-contrast rule-of-thirds grid, and live dimension badge.
- **Aspect Ratio Presets & Flip**: 1:1 Square, 4:5 Portrait, 9:16 Story, 16:9 Cinema, 4:3, 3:2, and one-tap orientation flipping.
- **Fine Rotation & Straighten**: Continuous precision slider ($\pm 45.0^\circ$ at $0.1^\circ$ granularity) with automatic aspect-preserving canvas bounds.
- **Tone & Color Adjustments**: Live GPU-accelerated adjustments for Exposure, Contrast, Saturation, Warmth/Color Temperature, Tint, Highlights, Shadows, and Sepia.
- **Headless Background Export**: Full-resolution multithreaded isolate pipeline that preserves EXIF metadata.

### ⚡ Large-Scale Performance (4k–5k+ Photos)
- **Background Isolate Folder Scanner**: Traverses massive folder hierarchies asynchronously without dropping main-thread UI frames.
- **Virtualized Grid Viewport**: Renders only the 20–30 cards visible on-screen, keeping RAM usage < 800 KB for 5,000 image metadata entries.
- **Tuned Desktop Image Cache**: 250 MB / 2,500-item memory cache retains ~400 decoded thumbnails simultaneously in VRAM for instant scrolling.
- **High-Volume Sibling Discovery**: Immediate directory indexing in < 2ms using Schwartzian transform sorting.

### 🔒 Privacy, Security & Platform Native
- **100% Offline & Private**: Zero background tracking or telemetry. Your photos stay strictly on your local machine.
- **Hardware-Backed Credential Security**: Integrates with Windows DPAPI via `FlutterSecureStorage` for external integrations.
- **Extensive Format Support**: Native rendering for `.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`, `.ico`, `.gif`, vector `.svg`/`.svgz`, and RAW camera formats (`.cr2`, `.nef`, `.arw`, `.dng`).

---

## 📥 Download & Installation

### Option 1: Microsoft Store (Recommended)
Install directly from the Microsoft Store for automatic background updates and sandboxed security:
👉 **[Get Spectrum Studio on the Microsoft Store](https://apps.microsoft.com/detail/9P1QW99KRX7N?hl=en-us&gl=IN&ocid=pdpshare)**

### Option 2: Portable Release
1. Download the latest `Spectrum-Windows-v0.1.1-x64.zip` from the Releases section.
2. Extract the archive to any folder.
3. Run `spectrum.exe`. No installer or administrator rights required.

### 💡 Setting as Default Windows Photo Viewer
1. Right-click any image file (`.jpg`, `.png`, etc.) → **Open with** → **Choose another app**.
2. Select **Spectrum Studio** (or browse to your extracted `spectrum.exe`).
3. Check **Always use this app to open files**.

---

## ⌨️ Desktop Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Left` / `Right` Arrow | Previous / Next Image |
| `Up` / `Down` Arrow | Smooth Zoom In / Zoom Out (hold for continuous glide) |
| `Mouse Wheel` | Analog Zoom at Cursor Position |
| `Space` | Toggle Slideshow |
| `F` / `F11` | Toggle Fullscreen |
| `E` | Open in Photo Editor |
| `I` | Toggle EXIF Metadata Drawer |
| `H` | Toggle Real-Time RGB Histogram |
| `M` | Toggle Loupe Navigator Map |
| `T` | Toggle Bottom Filmstrip |
| `Delete` | Delete Current Image / Selected Files (with confirmation) |
| `Esc` | Close Viewer / Clear Multi-Selection |

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Desktop Windows x64 Embedder)
- **Language**: Dart 3
- **State Architecture**: Riverpod 2.6 (Notifier & AsyncNotifier patterns)
- **Local Storage**: Isar Database (Collections, Albums, Virtual Tags)
- **Image Pipeline**: Extended Image, Photo View, Image Processing Isolate Workers
- **Desktop Window Management**: `window_manager` with native Win32/C++ frameless window styling

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
