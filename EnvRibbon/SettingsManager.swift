//
//  SettingsManager.swift
//  EnvRibbon
//
//  Manages app settings and preferences
//

import SwiftUI
import Combine
import AppKit

struct IPConfig: Identifiable, Equatable {
    var id = UUID()
    var ip: String
    var ribbonText: String
    var ribbonColor: Color
    
    static func == (lhs: IPConfig, rhs: IPConfig) -> Bool {
        return lhs.id == rhs.id && lhs.ip == rhs.ip && lhs.ribbonText == rhs.ribbonText
    }
    
    // สำหรับเก็บสีในรูปแบบที่ Codable ได้
    private var colorData: Data?
    
    init(ip: String = "", ribbonText: String = "ENV", ribbonColor: Color = .red) {
        self.ip = ip
        self.ribbonText = ribbonText
        self.ribbonColor = ribbonColor
        self.colorData = Self.encodeColor(ribbonColor)
    }
    
    static func encodeColor(_ color: Color) -> Data? {
        let nsColor = NSColor(color)
        return try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false)
    }
    
    static func decodeColor(from data: Data?) -> Color {
        guard let data = data,
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return .red
        }
        return Color(nsColor)
    }
    
    // Codable support
    enum CodingKeys: String, CodingKey {
        case id, ip, ribbonText, colorData
    }
}

extension IPConfig: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ip = try container.decode(String.self, forKey: .ip)
        ribbonText = try container.decode(String.self, forKey: .ribbonText)
        colorData = try container.decodeIfPresent(Data.self, forKey: .colorData)
        ribbonColor = Self.decodeColor(from: colorData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ip, forKey: .ip)
        try container.encode(ribbonText, forKey: .ribbonText)
        try container.encode(Self.encodeColor(ribbonColor), forKey: .colorData)
    }
}

class SettingsManager: ObservableObject {
    @Published var ipConfigs: [IPConfig] {
        didSet {
            saveIPConfigs()
        }
    }
    
    @Published var defaultRibbonText: String {
        didSet {
            UserDefaults.standard.set(defaultRibbonText, forKey: "defaultRibbonText")
        }
    }
    
    @Published var defaultRibbonColor: Color {
        didSet {
            saveDefaultColor(defaultRibbonColor)
        }
    }
    
    // สำหรับ backward compatibility
    var targetIP: String {
        get {
            ipConfigs.first?.ip ?? ""
        }
        set {
            if ipConfigs.isEmpty {
                ipConfigs = [IPConfig(ip: newValue, ribbonText: ribbonText, ribbonColor: ribbonColor)]
            } else {
                ipConfigs[0].ip = newValue
            }
        }
    }
    
    var ribbonText: String {
        get {
            ipConfigs.first?.ribbonText ?? "ENV"
        }
        set {
            if ipConfigs.isEmpty {
                ipConfigs = [IPConfig(ip: targetIP, ribbonText: newValue, ribbonColor: ribbonColor)]
            } else {
                ipConfigs[0].ribbonText = newValue
            }
        }
    }
    
    var ribbonColor: Color {
        get {
            ipConfigs.first?.ribbonColor ?? .red
        }
        set {
            if ipConfigs.isEmpty {
                ipConfigs = [IPConfig(ip: targetIP, ribbonText: ribbonText, ribbonColor: newValue)]
            } else {
                var config = ipConfigs[0]
                config.ribbonColor = newValue
                ipConfigs[0] = config
            }
        }
    }
    
    func matchesIP(_ ip: String) -> IPConfig? {
        return ipConfigs.first { $0.ip == ip && !$0.ip.isEmpty }
    }
    
    func getRibbonConfig(for ip: String) -> (text: String, color: Color) {
        if let matchingConfig = matchesIP(ip) {
            return (matchingConfig.ribbonText, matchingConfig.ribbonColor)
        } else {
            // ใช้ default settings
            return (defaultRibbonText, defaultRibbonColor)
        }
    }
    
    private func saveDefaultColor(_ color: Color) {
        let nsColor = NSColor(color)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: "defaultRibbonColor")
        }
    }
    
    private func loadDefaultColor() -> Color {
        guard let colorData = UserDefaults.standard.data(forKey: "defaultRibbonColor"),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
            return .gray // สี default
        }
        return Color(nsColor)
    }
    
    private func saveIPConfigs() {
        if let encoded = try? JSONEncoder().encode(ipConfigs) {
            UserDefaults.standard.set(encoded, forKey: "ipConfigs")
        }
    }
    
    private func loadIPConfigs() -> [IPConfig] {
        if let data = UserDefaults.standard.data(forKey: "ipConfigs"),
           let configs = try? JSONDecoder().decode([IPConfig].self, from: data) {
            return configs
        }
        // Backward compatibility: โหลดค่าเก่า
        if let oldIP = UserDefaults.standard.string(forKey: "targetIP"), !oldIP.isEmpty {
            let oldText = UserDefaults.standard.string(forKey: "ribbonText") ?? "ENV"
            let oldColor = loadColor()
            return [IPConfig(ip: oldIP, ribbonText: oldText, ribbonColor: oldColor)]
        }
        return []
    }
    
    private func loadColor() -> Color {
        guard let colorData = UserDefaults.standard.data(forKey: "ribbonColor"),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
            return .red
        }
        return Color(nsColor)
    }
    
    init() {
        // โหลด default settings ก่อน
        let defaultText = UserDefaults.standard.string(forKey: "defaultRibbonText") ?? ""
        let defaultColor: Color
        if let colorData = UserDefaults.standard.data(forKey: "defaultRibbonColor"),
           let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            defaultColor = Color(nsColor)
        } else {
            defaultColor = .gray
        }
        
        self.defaultRibbonText = defaultText
        self.defaultRibbonColor = defaultColor
        
        // โหลด IP configs
        self.ipConfigs = []
        self.ipConfigs = loadIPConfigs()
    }
}
