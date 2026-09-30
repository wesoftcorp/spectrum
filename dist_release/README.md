# Spectrum Studio — v0.1.0 Windows Release
> Ultra-fast, hardware-accelerated photo viewer & color grading studio.

## Release Artifacts

| Artifact | Size | SHA-256 |
|---|---|---|
| `Spectrum-Windows-v0.1.0-x64.zip` | 39.8 MB | `B834717A1749B3AE572889229D2F5781A5CDB63D93097AFC51754D9E32B301BB` |
| `Spectrum-WindowsStore-v0.1.0-x64.msix` | 24.3 MB | `F923D11A81A9DF9564F4940602E6D6D99A815E9A38237309CE13314189772BD5` |

## Installation

### ZIP (Portable — No Install Required)
1. Extract `Spectrum-Windows-v0.1.0-x64.zip` to any folder.
2. Run `spectrum.exe`.
3. First launch: Windows SmartScreen may warn — click **More info → Run anyway**.

### MSIX (Windows Store / Sideload)
1. Double-click `Spectrum-WindowsStore-v0.1.0-x64.msix`.
2. Click **Install** in Windows App Installer.
3. If sideloading is blocked: **Settings → System → For Developers → Sideload apps**.

## What's Fixed in This Build
- **Crash fix**: Folder scanning now runs in a Flutter-managed background isolate (`compute()`) — UI stays fully responsive on folders with thousands of images across deep subfolder trees
- **Subfolder scanning**: Opening a folder recursively scans all nested subfolders (up to 10 levels, up to 30,000 images)
- **Stretched preview fix**: Thumbnails no longer distort portrait/landscape images — removed forced square decode; aspect ratio is always preserved
- **Thumbnail fade-in**: Smooth opacity animation as each thumbnail loads from disk
- **Logo fix**: Spectrum logo renders correctly in the sidebar and welcome screen
- **Watcher stability**: FileSystem watcher errors are swallowed silently; never crashes the gallery

## System Requirements
- Windows 10 (1903+) or Windows 11, x64
- GPU with DirectX 11 support recommended
