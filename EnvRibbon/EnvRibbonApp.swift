//
//  EnvRibbonApp.swift
//  EnvRibbon
//
//  Created on macOS
//

import SwiftUI
import AppKit
import Combine

class RibbonUpdateObserver: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private unowned let settingsManager: SettingsManager
    private unowned let ipMonitor: IPMonitor
    private unowned let ribbonManager: RibbonManager
    
    init(settingsManager: SettingsManager, ipMonitor: IPMonitor, ribbonManager: RibbonManager) {
        self.settingsManager = settingsManager
        self.ipMonitor = ipMonitor
        self.ribbonManager = ribbonManager
        
        // Observe IP changes - ใช้ receive(on:) แทน DispatchQueue.main.async
        ipMonitor.$currentIP
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkAndUpdateRibbon()
            }
            .store(in: &cancellables)
        
        // Observe settings changes
        settingsManager.$ipConfigs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkAndUpdateRibbon()
            }
            .store(in: &cancellables)
        
        // Observe default settings changes
        settingsManager.$defaultRibbonText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkAndUpdateRibbon()
            }
            .store(in: &cancellables)
        
        settingsManager.$defaultRibbonColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkAndUpdateRibbon()
            }
            .store(in: &cancellables)
    }
    
    private func checkAndUpdateRibbon() {
        let config = settingsManager.getRibbonConfig(for: ipMonitor.currentIP)
        
        // แสดง ribbon ถ้ามี default settings (text ไม่ว่าง) หรือมี IP ที่ตรงกัน
        if !config.text.isEmpty {
            ribbonManager.showRibbons(
                text: config.text,
                color: config.color
            )
        } else {
            ribbonManager.hideRibbons()
        }
    }
}

class SettingsWindowManager {
    private var settingsWindow: NSWindow?
    
    func showSettings(
        settingsManager: SettingsManager,
        ipMonitor: IPMonitor,
        ribbonManager: RibbonManager
    ) {
        // ถ้ามี window อยู่แล้ว ให้แสดง
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // สร้าง window ใหม่
        let contentView = SettingsView()
            .environmentObject(settingsManager)
            .environmentObject(ipMonitor)
            .environmentObject(ribbonManager)
        
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 650),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "EnvRibbon Settings"
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        
        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct EnvRibbonApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var ipMonitor = IPMonitor()
    @StateObject private var ribbonManager = RibbonManager()
    @State private var settingsWindowManager = SettingsWindowManager()
    @StateObject private var ribbonObserver: RibbonUpdateObserver
    
    init() {
        // สร้าง state objects ก่อน
        let sm = SettingsManager()
        let im = IPMonitor()
        let rm = RibbonManager()
        _settingsManager = StateObject(wrappedValue: sm)
        _ipMonitor = StateObject(wrappedValue: im)
        _ribbonManager = StateObject(wrappedValue: rm)
        
        // เริ่ม monitoring ทันทีที่เปิดแอพ
        im.startMonitoring()
        
        // สร้าง observer โดยใช้ instances ที่สร้างไว้
        _ribbonObserver = StateObject(wrappedValue: RibbonUpdateObserver(
            settingsManager: sm,
            ipMonitor: im,
            ribbonManager: rm
        ))
    }
    
    var body: some Scene {
        MenuBarExtra("EnvRibbon", systemImage: "network") {
            ContentView(openSettings: {
                settingsWindowManager.showSettings(
                    settingsManager: settingsManager,
                    ipMonitor: ipMonitor,
                    ribbonManager: ribbonManager
                )
            })
            .environmentObject(settingsManager)
            .environmentObject(ipMonitor)
            .environmentObject(ribbonManager)
        }
        .menuBarExtraStyle(.window)
    }
}
