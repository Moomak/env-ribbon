//
//  IPMonitor.swift
//  EnvRibbon
//
//  Monitors current IP address
//

import Foundation
import Network
import Combine
import SystemConfiguration

class IPMonitor: ObservableObject {
    @Published var currentIP: String = "Checking..."
    @Published var isMonitoring: Bool = false
    
    private var timer: Timer?
    private let monitorQueue = DispatchQueue(label: "IPMonitor")
    private var currentTask: URLSessionDataTask?
    
    // รายการ API สำหรับดึง public IP (fallback)
    private let ipAPIs = [
        "https://api.ipify.org?format=json",
        "https://api64.ipify.org?format=json",
        "https://ifconfig.me/ip",
        "https://icanhazip.com",
        "https://checkip.amazonaws.com"
    ]
    private var currentAPIIndex = 0
    
    private var pathMonitor: NWPathMonitor?
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        // เริ่มต้น Monitor แบบ Real-time
        startPathMonitor()
        
        // Initial check
        getIPAddress()
        
        // ตั้ง Timer ไว้เป็น fallback (เช่น ทุก 60 วินาที) เผื่อกรณีอื่นๆ
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.getIPAddress()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        pathMonitor?.cancel()
        pathMonitor = nil
        currentTask?.cancel()
        currentTask = nil
    }
    
    // Monitors network changes continuously
    private func startPathMonitor() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            if path.status == .satisfied {
                // เมื่อ network เปลี่ยน (เช่น ต่อ VPN, เปลี่ยน WiFi) ให้เช็ค IP ใหม่ทันที
                // เพิ่ม delay เล็กน้อยเพื่อให้ connection secure ดีก่อน (บางที VPN ต่อติดแต่ routing ยังไม่มา)
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    self.getIPAddress()
                }
            } else {
                DispatchQueue.main.async {
                    self.currentIP = "No Connection"
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        pathMonitor?.start(queue: queue)
    }
    
    // ไม่จำเป็นต้องใช้ checkIP แบบ one-shot แล้ว ให้เรียก getIPAddress ได้เลยหรือผ่าน Monitor
    private func checkIP() {
        getIPAddress()
    }
    
    private func getIPAddress() {
        // ยกเลิก task เก่าถ้ามี
        currentTask?.cancel()
        
        // ลองใช้ API แรกก่อน
        currentAPIIndex = 0
        tryNextAPI()
    }
    
    private func tryNextAPI() {
        // ถ้าใช้ API ทั้งหมดแล้วยังไม่ได้ ให้แสดง error
        guard currentAPIIndex < ipAPIs.count else {
            DispatchQueue.main.async {
                self.currentIP = "Unable to check"
            }
            return
        }
        
        let apiURL = ipAPIs[currentAPIIndex]
        currentAPIIndex += 1
        
        guard let url = URL(string: apiURL) else {
            // ลอง API ถัดไป
            tryNextAPI()
            return
        }
        
        // สร้าง request พร้อม timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.httpMethod = "GET"
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // ตรวจสอบ error
            if let error = error {
                // ถ้าเป็น cancellation error ไม่ต้องทำอะไร
                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }
                // ลอง API ถัดไป
                self.tryNextAPI()
                return
            }
            
            // ตรวจสอบ HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    // ลอง API ถัดไป
                    self.tryNextAPI()
                    return
                }
            }
            
            guard let data = data else {
                self.tryNextAPI()
                return
            }
            
            // พยายาม parse IP จาก response
            var ip: String?
            
            // วิธีที่ 1: JSON format ({"ip": "xxx.xxx.xxx.xxx"})
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let jsonIP = json["ip"] as? String {
                ip = jsonIP
            }
            // วิธีที่ 2: Plain text format (xxx.xxx.xxx.xxx)
            else if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                    isValidIP(text) {
                ip = text
            }
            
            if let ip = ip {
                DispatchQueue.main.async {
                    self.currentIP = ip
                }
            } else {
                // ลอง API ถัดไป
                self.tryNextAPI()
            }
        }
        
        currentTask?.resume()
    }
    
    private func isValidIP(_ ip: String) -> Bool {
        // ตรวจสอบรูปแบบ IP address
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return false }
        
        for part in parts {
            guard let num = Int(part),
                  num >= 0 && num <= 255 else {
                return false
            }
        }
        
        return true
    }
}
