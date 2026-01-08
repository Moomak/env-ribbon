# Build and Distribute Instructions for EnvRibbon

## 📦 Building App for Distribution

### Method 1: Using Xcode (Recommended)

1. **Open Project in Xcode**
   ```bash
   open EnvRibbon.xcodeproj
   ```

2. **Select Scheme and Destination**
   - Select Scheme: `EnvRibbon`
   - Select Destination: `Any Mac (Apple Silicon, Intel)`

3. **Build for Release**
   - Go to menu: `Product` > `Archive`
   - Wait for build to complete

4. **Export App**
   - After Archive is complete, Organizer window will open
   - Click `Distribute App`
   - Select `Copy App` (for direct distribution)
   - Select destination folder
   - Click `Export`

5. **App will be created at:**
   - `~/Desktop/envRibbon/EnvRibbon/EnvRibbon.app` (or your selected location)

## 🎨 Changing App Icon

### Steps to Change Icon

1. **Prepare Icon Files**
   - Create PNG file for each size:
     - `icon_16x16.png` (16x16 pixels)
     - `icon_16x16@2x.png` (32x32 pixels)
     - `icon_32x32.png` (32x32 pixels)
     - `icon_32x32@2x.png` (64x64 pixels)
     - `icon_128x128.png` (128x128 pixels)
     - `icon_128x128@2x.png` (256x256 pixels)
     - `icon_256x256.png` (256x256 pixels)
     - `icon_256x256@2x.png` (512x512 pixels)
     - `icon_512x512.png` (512x512 pixels)
     - `icon_512x512@2x.png` (1024x1024 pixels)

2. **Method 1: Using Xcode**
   - Open `Assets.xcassets` in Xcode
   - Select `AppIcon`
   - Drag icon files to corresponding slots

3. **Method 2: Using Script**
   - Place all icon files in `icons/` folder
   - Run script: `./update_icons.sh`

### Use Icon from Single File

If you have a single large icon file (1024x1024), you can use this script:

```bash
# Generate icons from single file
sips -z 16 16 icon_1024.png --out icon_16x16.png
sips -z 32 32 icon_1024.png --out icon_16x16@2x.png
sips -z 32 32 icon_1024.png --out icon_32x32.png
sips -z 64 64 icon_1024.png --out icon_32x32@2x.png
sips -z 128 128 icon_1024.png --out icon_128x128.png
sips -z 256 256 icon_1024.png --out icon_128x128@2x.png
sips -z 256 256 icon_1024.png --out icon_256x256.png
sips -z 512 512 icon_1024.png --out icon_256x256@2x.png
sips -z 512 512 icon_1024.png --out icon_512x512.png
sips -z 1024 1024 icon_1024.png --out icon_512x512@2x.png
```

## 📝 Additional Settings

### 1. Change App Name
- Go to `Info.plist` or Build Settings
- Edit `PRODUCT_NAME` or `CFBundleName`

### 2. Change Version
- Edit `MARKETING_VERSION` in Build Settings
- Or edit `CFBundleShortVersionString` in `Info.plist`

### 3. Change Bundle Identifier
- Go to Build Settings
- Edit `PRODUCT_BUNDLE_IDENTIFIER`

## 🚀 Distributing App

### For General Users

1. **Zip App**
   ```bash
   cd build/export
   zip -r EnvRibbon.zip EnvRibbon.app
   ```

2. **Distribute**
   - Upload to website
   - Or send directly to users

### For App Store

1. Must have Apple Developer Account
2. Use Xcode Organizer to upload to App Store Connect
3. Configure settings in App Store Connect

## ⚠️ Notes

- This app uses Sandbox and has entitlements for network access
- Users may need to allow network access when running the app for the first time
- For auto start, permission to add login item is required
