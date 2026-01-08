//
//  SettingsView.swift
//  EnvRibbon
//
//  Settings view
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var ipMonitor: IPMonitor
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ส่วนหัว
                Text("EnvRibbon Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // IP Configurations
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Target IP Addresses")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            settingsManager.ipConfigs.append(IPConfig())
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Add New IP")
                    }
                    
                    Text("Ribbon displays when current IP matches configured IP.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach($settingsManager.ipConfigs) { $config in
                        IPConfigRowView(
                            config: $config,
                            onDelete: {
                                if let index = settingsManager.ipConfigs.firstIndex(where: { $0.id == config.id }) {
                                    settingsManager.ipConfigs.remove(at: index)
                                }
                            }
                        )
                    }
                    
                    if settingsManager.ipConfigs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "network")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No Configured IPs")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button(action: {
                                settingsManager.ipConfigs.append(IPConfig())
                            }) {
                                Label("Add First IP", systemImage: "plus.circle")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Default Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Default Ribbon (When IP doesn't match)")
                        .font(.headline)
                    
                    Text("Shows default ribbon when current IP doesn't match any configuration.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Default Ribbon Text Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ribbon Text (Default):")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("e.g., DEFAULT, OTHER", text: $settingsManager.defaultRibbonText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Default Color Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ribbon Color (Default):")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        HStack {
                            ColorPicker("", selection: $settingsManager.defaultRibbonColor)
                                .labelsHidden()
                            Spacer()
                            // แสดงตัวอย่างสี
                            Text(settingsManager.defaultRibbonText.isEmpty ? "Example" : settingsManager.defaultRibbonText)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(settingsManager.defaultRibbonColor)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // สถานะ
                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(.headline)
                    
                    HStack {
                        Text("Current Public IP:")
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 8) {
                            Text(ipMonitor.currentIP)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
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
                            .help("Copy IP")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    
                    let ribbonConfig = settingsManager.getRibbonConfig(for: ipMonitor.currentIP)
                    let isMatching = settingsManager.matchesIP(ipMonitor.currentIP) != nil
                    let isDefault = !isMatching && !ribbonConfig.text.isEmpty
                    
                    if isMatching || isDefault {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(isMatching ? "Ribbon Active (IP Matched)" : "Ribbon Active (Default)")
                                .foregroundColor(.green)
                            Spacer()
                            if !ribbonConfig.text.isEmpty {
                                Text(ribbonConfig.text)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ribbonConfig.color)
                                    .cornerRadius(4)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                            Text("Ribbon Hidden")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding(20)
        }
        .frame(width: 600, height: 650)
    }
}

struct IPConfigRowView: View {
    @Binding var config: IPConfig
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete this IP")
                
                Spacer()
            }
            
            // IP Address Input
            VStack(alignment: .leading, spacing: 6) {
                Text("IP Address:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("e.g., 123.45.67.89", text: $config.ip)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Ribbon Text Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Ribbon Text:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("e.g., ENV, PROD, DEV", text: $config.ribbonText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Color Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Ribbon Color:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack {
                    ColorPicker("", selection: $config.ribbonColor)
                        .labelsHidden()
                    Spacer()
                    // แสดงตัวอย่างสี
                    Text(config.ribbonText.isEmpty ? "Example" : config.ribbonText)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(config.ribbonColor)
                        .cornerRadius(6)
                }
            }
            
            // Sound and Interval
            VStack(alignment: .leading, spacing: 6) {
                Text("Sound Alert:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Picker("", selection: $config.soundName) {
                        ForEach(SoundManager.shared.availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                    
                    if config.soundName != "None" {
                        Stepper(value: $config.soundInterval, in: 0...3600, step: 5) {
                            if config.soundInterval == 0 {
                                Text("Play Once")
                                    .font(.caption)
                            } else {
                                Text("Every \(config.soundInterval) seconds")
                                    .font(.caption)
                            }
                        }
                        
                        Button(action: {
                            SoundManager.shared.playSound(config.soundName)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Test Sound")
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
