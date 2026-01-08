# EnvRibbon

แอปพลิเคชัน macOS สำหรับแสดง ribbon ที่มุมขวาบนของจอเมื่อ IP address ตรงกับที่ตั้งค่าไว้

## คุณสมบัติ

- ✅ ตรวจสอบ IP address ปัจจุบันอัตโนมัติ
- ✅ แสดง ribbon บนทุกจอ (multi-display support)
- ✅ ตั้งค่า IP, สี, และข้อความได้
- ✅ ทำงานเป็น menu bar app (ไม่แสดงใน Dock)

## การติดตั้ง

1. เปิดโปรเจกต์ใน Xcode
2. เลือก target เป็น macOS
3. Build และ Run (⌘R)

## การใช้งาน

1. เปิดแอปจาก menu bar (ไอคอน network)
2. ไปที่ "ตั้งค่า" เพื่อกำหนด:
   - IP ที่ต้องการตรวจสอบ
   - ข้อความที่จะแสดงบน ribbon
   - สีของ ribbon
3. แอปจะตรวจสอบ IP อัตโนมัติทุก 5 วินาที
4. เมื่อ IP ตรงกับที่ตั้งค่าไว้ ribbon จะแสดงที่มุมขวาบนของทุกจอ

## ข้อกำหนด

- macOS 12.0 หรือสูงกว่า
- Xcode 14.0 หรือสูงกว่า

## การตั้งค่า Git

```bash
git remote add origin https://github.com/Moomak/env-ribbon.git
git branch -M main
git push -u origin main
```
