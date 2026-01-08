//
//  ContentView.swift
//  EnvRibbon
//
//  Main content view
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var ipMonitor: IPMonitor
    @EnvironmentObject var ribbonManager: RibbonManager
    var openSettings: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // สถานะ IP
            VStack(alignment: .leading, spacing: 8) {
                Text("IP ปัจจุบัน (Public):")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text(ipMonitor.currentIP)
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Button(action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(ipMonitor.currentIP, forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("คัดลอก IP")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
            
            // สถานะการแสดง ribbon
            let ribbonConfig = settingsManager.getRibbonConfig(for: ipMonitor.currentIP)
            let isMatching = settingsManager.matchesIP(ipMonitor.currentIP) != nil
            let isDefault = !isMatching && !ribbonConfig.text.isEmpty
            
            if isMatching || isDefault {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(isMatching ? "แสดง Ribbon (IP ตรงกัน)" : "แสดง Ribbon (Default)")
                            .font(.caption)
                    }
                    if !ribbonConfig.text.isEmpty {
                        Text(ribbonConfig.text)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ribbonConfig.color)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                    Text("ซ่อน Ribbon")
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            
            Divider()
            
            // เมนู
            Button(action: {
                openSettings?()
            }) {
                Label("ตั้งค่า", systemImage: "gear")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("ออกจากแอป", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding(.vertical, 8)
        .frame(width: 250)

        .onChange(of: ipMonitor.currentIP) {
            checkAndUpdateRibbon()
        }
        .onChange(of: settingsManager.ipConfigs) {
            checkAndUpdateRibbon()
        }
        .onChange(of: settingsManager.defaultRibbonText) {
            checkAndUpdateRibbon()
        }
        .onChange(of: settingsManager.defaultRibbonColor) {
            checkAndUpdateRibbon()
        }
    }
    
    private func checkAndUpdateRibbon() {
        let config = settingsManager.getRibbonConfig(for: ipMonitor.currentIP)
        
        // แสดง ribbon ถ้ามี default settings หรือมี IP ที่ตรงกัน
        if !config.text.isEmpty || settingsManager.matchesIP(ipMonitor.currentIP) != nil {
            ribbonManager.showRibbons(
                text: config.text.isEmpty ? "DEFAULT" : config.text,
                color: config.color
            )
        } else {
            ribbonManager.hideRibbons()
        }
    }
}
