#!/bin/bash

# Script สำหรับอัปเดต App Icon
# ใช้ไฟล์ icon_1024.png เป็นต้นฉบับ

ICON_SOURCE="icon_1024.png"
ICONSET_DIR="EnvRibbon/Assets.xcassets/AppIcon.appiconset"

# ตรวจสอบว่ามีไฟล์ต้นฉบับหรือไม่
if [ ! -f "$ICON_SOURCE" ]; then
    echo "❌ ไม่พบไฟล์ $ICON_SOURCE"
    echo "กรุณาวางไฟล์ icon ขนาด 1024x1024 ชื่อ icon_1024.png ในโฟลเดอร์โปรเจค"
    exit 1
fi

echo "🔄 กำลังสร้าง icons จาก $ICON_SOURCE..."

# สร้าง icons ตามขนาดที่ต้องการ
sips -z 16 16 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_16x16.png" 2>/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_16x16@2x.png" 2>/dev/null
sips -z 32 32 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_32x32.png" 2>/dev/null
sips -z 64 64 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_32x32@2x.png" 2>/dev/null
sips -z 128 128 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_128x128.png" 2>/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_128x128@2x.png" 2>/dev/null
sips -z 256 256 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_256x256.png" 2>/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_256x256@2x.png" 2>/dev/null
sips -z 512 512 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_512x512.png" 2>/dev/null
sips -z 1024 1024 "$ICON_SOURCE" --out "${ICONSET_DIR}/icon_512x512@2x.png" 2>/dev/null

echo "✅ สร้าง icons เสร็จแล้ว"
echo "📝 ต้องอัปเดต Contents.json ด้วยตนเองใน Xcode"
echo ""
echo "วิธีใช้:"
echo "1. เปิด Assets.xcassets ใน Xcode"
echo "2. เลือก AppIcon"
echo "3. ลากไฟล์ icon ที่สร้างไว้ไปวางในช่องที่ตรงกับขนาด"
