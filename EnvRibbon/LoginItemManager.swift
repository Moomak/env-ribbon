//
//  LoginItemManager.swift
//  EnvRibbon
//
//  Manages auto-start login item
//

import Foundation
import ServiceManagement
import AppKit

@available(macOS 13.0, *)
extension SMAppService {
    static var loginItem: SMAppService {
        return SMAppService.loginItem(identifier: Bundle.main.bundleIdentifier!)
    }
}

class LoginItemManager {
    static let shared = LoginItemManager()
    
    private let bundleIdentifier: String
    
    private init() {
        // ใช้ bundle identifier ของแอปเอง
        self.bundleIdentifier = Bundle.main.bundleIdentifier ?? "BentoWeb.EnvRibbon"
    }
    
    /// ตรวจสอบว่า auto start เปิดอยู่หรือไม่ (ตรวจสอบจากสถานะจริง)
    func isEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            // ตรวจสอบจากสถานะจริงของ SMAppService
            let service = SMAppService.loginItem
            let status = service.status
            return status == .enabled
        } else {
            // สำหรับ macOS เก่า ตรวจสอบจาก UserDefaults
            return UserDefaults.standard.bool(forKey: "autoStartEnabled")
        }
    }
    
    /// เปิด System Settings ไปที่ Login Items
    func openLoginItemsSettings() {
        DispatchQueue.main.async {
            if #available(macOS 13.0, *) {
                // สำหรับ macOS 13+ ใช้ URL scheme ใหม่
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.loginitems") {
                    NSWorkspace.shared.open(url)
                    print("✅ Opened System Settings > Login Items")
                } else {
                    // Fallback: เปิด System Settings ทั่วไป
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
                }
            } else {
                // สำหรับ macOS 12 ใช้ URL scheme เก่า
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LoginItems") {
                    NSWorkspace.shared.open(url)
                } else {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
                }
            }
        }
    }
    
    /// เปิด/ปิด auto start
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            // ใช้ SMAppService สำหรับ macOS 13+
            let service = SMAppService.loginItem
            let currentStatus = service.status
            
            print("🔍 Current login item status: \(currentStatus.rawValue)")
            
            // ถ้าสถานะตรงกับที่ต้องการแล้ว ไม่ต้องทำอะไร
            if enabled && currentStatus == .enabled {
                print("✅ Login item already enabled")
                UserDefaults.standard.set(true, forKey: "autoStartEnabled")
                return true
            }
            if !enabled && (currentStatus == .notFound || currentStatus == .notRegistered) {
                print("✅ Login item already disabled")
                UserDefaults.standard.set(false, forKey: "autoStartEnabled")
                return true
            }
            
            do {
                if enabled {
                    // ถ้ายังไม่ได้ register หรือถูกปฏิเสธ ให้ลอง register
                    if currentStatus == .notFound || currentStatus == .notRegistered || currentStatus == .requiresApproval {
                        print("🔄 Attempting to register login item...")
                        try service.register()
                        print("✅ Register successful")
                        
                        // รอสักครู่เพื่อให้ระบบอัปเดตสถานะ
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let newStatus = service.status
                            print("🔍 Status after register: \(newStatus.rawValue)")
                            
                            if newStatus == .requiresApproval {
                                // ต้องขออนุญาตจากผู้ใช้ - เปิด System Settings โดยอัตโนมัติ
                                print("⚠️ Requires approval - opening System Settings")
                                self.showAuthorizationAlertAndOpenSettings()
                            } else if newStatus == .enabled {
                                print("✅ Successfully enabled")
                                UserDefaults.standard.set(true, forKey: "autoStartEnabled")
                            }
                        }
                    }
                } else {
                    print("🔄 Attempting to unregister login item...")
                    try service.unregister()
                    print("✅ Unregister successful")
                }
                
                // บันทึกสถานะใน UserDefaults
                UserDefaults.standard.set(enabled, forKey: "autoStartEnabled")
                
                // ตรวจสอบสถานะหลังจากการเปลี่ยนแปลง
                let finalStatus = service.status
                print("🔍 Final status: \(finalStatus.rawValue)")
                
                if enabled && finalStatus == .requiresApproval {
                    // ต้องขออนุญาตจากผู้ใช้ - เปิด System Settings โดยอัตโนมัติ
                    print("⚠️ Requires approval - opening System Settings immediately")
                    showAuthorizationAlertAndOpenSettings()
                    return false
                }
                
                return true
            } catch {
                print("❌ Failed to set login item: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
                showErrorAlert(error: error)
                UserDefaults.standard.set(false, forKey: "autoStartEnabled")
                return false
            }
        } else {
            // ใช้ SMLoginItemSetEnabled สำหรับ macOS 10.9-12
            print("🔄 Using SMLoginItemSetEnabled for older macOS")
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
            if success {
                print("✅ SMLoginItemSetEnabled successful")
                UserDefaults.standard.set(enabled, forKey: "autoStartEnabled")
            } else {
                print("❌ SMLoginItemSetEnabled failed")
                showErrorAlert(error: nil)
            }
            return success
        }
    }
    
    /// แสดง alert และเปิด System Settings โดยอัตโนมัติ
    private func showAuthorizationAlertAndOpenSettings() {
        DispatchQueue.main.async {
            // เปิด System Settings ทันที
            self.openLoginItemsSettings()
            
            // แสดง alert เพื่อบอกผู้ใช้ว่าต้องทำอะไรต่อ
            let alert = NSAlert()
            alert.messageText = "ต้องการสิทธิ์ในการเริ่มต้นอัตโนมัติ"
            alert.informativeText = """
            หน้าต่าง System Settings ถูกเปิดให้แล้ว
            
            กรุณาทำตามขั้นตอน:
            1. ในหน้าต่าง System Settings ที่เปิดอยู่ ไปที่ General > Login Items
            2. คลิกปุ่ม "+" และเลือก EnvRibbon
            3. กลับมาเปิด Auto Start ในแอปอีกครั้ง
            
            หรือถ้าหน้าต่าง System Settings ยังไม่เปิด ให้ไปที่:
            System Settings > General > Login Items
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "เปิด System Settings อีกครั้ง")
            alert.addButton(withTitle: "ตกลง")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // เปิด System Settings อีกครั้ง
                self.openLoginItemsSettings()
            }
        }
    }
    
    /// แสดง error alert
    private func showErrorAlert(error: Error?) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "ไม่สามารถตั้งค่า Auto Start ได้"
            if let error = error {
                alert.informativeText = "เกิดข้อผิดพลาด: \(error.localizedDescription)\n\nกรุณาลองอีกครั้งหรือไปตั้งค่าใน System Settings > General > Login Items"
            } else {
                alert.informativeText = "ไม่สามารถตั้งค่า Auto Start ได้\n\nกรุณาไปตั้งค่าใน System Settings > General > Login Items"
            }
            alert.alertStyle = .warning
            alert.addButton(withTitle: "ตกลง")
            alert.runModal()
        }
    }
    
    /// ตรวจสอบว่าแอปถูกเปิดจาก login item หรือไม่
    func isLaunchedAtLogin() -> Bool {
        // ตรวจสอบจาก launch event
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication && 
               event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
