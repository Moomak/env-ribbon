# EnvRibbon

A macOS application that displays a ribbon at the top right corner of the screen when the IP address matches the configuration.

## Features

- ✅ Automatically checks current public IP address
- ✅ Shows ribbon on all displays (multi-display support)
- ✅ Configurable IP, color, and text
- ✅ Works as a menu bar app (not shown in Dock)

## Installation

1. Open project in Xcode
2. Select target as macOS
3. Build and Run (⌘R)

## Usage

1. Open app from menu bar (network icon)
2. Go to "Settings" to configure:
   - Target IP to monitor
   - Text to display on ribbon
   - Color of the ribbon
3. The app checks IP automatically every 5 seconds
4. When IP matches the configuration, the ribbon will appear at the top right of every screen

## Requirements

- macOS 12.0 or higher
- Xcode 14.0 or higher

## Git Configuration

```bash
git remote add origin https://github.com/Moomak/env-ribbon.git
git branch -M main
git push -u origin main
```
