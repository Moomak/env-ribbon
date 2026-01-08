//
//  SoundManager.swift
//  EnvRibbon
//
//  Manages sound alerts
//

import Foundation
import AppKit
import Combine

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var timer: Timer?
    private var currentSoundName: String?
    
    // รายชื่อเสียง System Sounds ที่น่าจะใช้ได้
    let availableSounds = [
        "None",
        "Basso",
        "Blow",
        "Bottle",
        "Frog",
        "Funk",
        "Glass",
        "Hero",
        "Morse",
        "Ping",
        "Pop",
        "Purr",
        "Sosumi",
        "Submarine",
        "Tink"
    ]
    
    func playSound(_ name: String) {
        if name == "None" || name.isEmpty { return }
        
        if let sound = NSSound(named: name) {
            sound.play()
        }
    }
    
    func startAlert(soundName: String, interval: Int) {
        // ถ้าเสียงเดิมและ interval เดิม ไม่ต้องทำอะไร
        // แต่ถ้า interval เปลี่ยน หรือ sound เปลี่ยน ให้เริ่มใหม่
        // แต่จริงๆ แล้วเราควร reset timer เพื่อความแม่นยำ
        
        stopAlert()
        
        guard soundName != "None", !soundName.isEmpty, interval > 0 else {
            return
        }
        
        currentSoundName = soundName
        
        // เล่นรอบแรกทันที
        playSound(soundName)
        
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [weak self] _ in
            self?.playSound(soundName)
        }
    }
    
    func stopAlert() {
        timer?.invalidate()
        timer = nil
        currentSoundName = nil
    }
}
