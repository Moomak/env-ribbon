//
//  RibbonManager.swift
//  EnvRibbon
//
//  Manages ribbon windows across all screens
//

import SwiftUI
import AppKit
import Combine

// Custom window class ที่ไม่บล็อก menu bar
class RibbonWindow: NSWindow {
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    override func sendEvent(_ event: NSEvent) {
        // ถ้าเป็น mouse event ที่ menu bar area ให้ส่งต่อไป
        if event.type == .leftMouseDown || event.type == .rightMouseDown {
            let location = event.locationInWindow
            // ถ้าคลิกที่ menu bar area (ด้านบนสุดของ screen) ให้ส่ง event ต่อไป
            if let screen = self.screen {
                let screenFrame = screen.frame
                let windowFrame = self.frame
                let globalLocation = CGPoint(x: windowFrame.origin.x + location.x, y: windowFrame.origin.y + location.y)
                
                // ตรวจสอบว่าคลิกที่ menu bar หรือไม่ (ด้านบนสุดของ screen)
                if globalLocation.y > screenFrame.maxY - 30 {
                    // คลิกที่ menu bar area - ไม่ต้อง handle
                    super.sendEvent(event)
                    return
                }
            }
        }
        super.sendEvent(event)
    }
}

class RibbonManager: ObservableObject {
    private var ribbonWindows: [NSWindow] = []
    private var ribbonPositions: [UUID: CGPoint] = [:]
    private var ribbonIDsByScreen: [NSScreen: UUID] = [:]
    
    func showRibbons(text: String, color: Color, width: CGFloat = 200, height: CGFloat = 40) {
        hideRibbons()
        
        let screens = NSScreen.screens
        for screen in screens {
            let ribbonWindow = createRibbonWindow(for: screen, text: text, color: color, width: width, height: height)
            ribbonWindows.append(ribbonWindow)
            // ใช้ orderFront แทน makeKeyAndOrderFront เพราะ window นี้ไม่สามารถเป็น key window ได้
            ribbonWindow.orderFront(nil)
        }
    }
    
    func hideRibbons() {
        // บันทึกตำแหน่งก่อนปิด
        saveAllPositions()
        ribbonWindows.forEach { $0.close() }
        ribbonWindows.removeAll()
        ribbonPositions.removeAll()
        ribbonIDsByScreen.removeAll()
    }
    
    private func getScreenIdentifier(_ screen: NSScreen) -> String {
        // ใช้ frame เพื่อสร้าง identifier
        let frame = screen.frame
        return "\(frame.origin.x),\(frame.origin.y),\(frame.width),\(frame.height)"
    }
    
    private func loadSavedPosition(for screen: NSScreen) -> CGPoint? {
        let screenID = getScreenIdentifier(screen)
        let key = "ribbonPosition_\(screenID)"
        
        // ตรวจสอบว่ามีค่าที่บันทึกไว้หรือไม่
        guard UserDefaults.standard.object(forKey: "\(key)_x") != nil,
              UserDefaults.standard.object(forKey: "\(key)_y") != nil else {
            return nil
        }
        
        let x = UserDefaults.standard.double(forKey: "\(key)_x")
        let y = UserDefaults.standard.double(forKey: "\(key)_y")
        
        return CGPoint(x: x, y: y)
    }
    
    private func savePosition(for screen: NSScreen, position: CGPoint) {
        let screenID = getScreenIdentifier(screen)
        let key = "ribbonPosition_\(screenID)"
        
        UserDefaults.standard.set(Double(position.x), forKey: "\(key)_x")
        UserDefaults.standard.set(Double(position.y), forKey: "\(key)_y")
        UserDefaults.standard.synchronize()
    }
    
    private func saveAllPositions() {
        for (screen, ribbonID) in ribbonIDsByScreen {
            if let position = ribbonPositions[ribbonID] {
                savePosition(for: screen, position: position)
            }
        }
    }
    
    private func createRibbonWindow(for screen: NSScreen, text: String, color: Color, width: CGFloat, height: CGFloat) -> NSWindow {
        let visibleFrame = screen.visibleFrame
        
        // ขนาดของ ribbon
        let ribbonWidth = width
        let ribbonHeight = height
        
        // โหลดตำแหน่งที่บันทึกไว้ หรือใช้ตำแหน่งเริ่มต้น: มุมขวาบน
        let savedPosition = loadSavedPosition(for: screen)
        
        // คำนวณตำแหน่ง window
        // ใช้มุมขวาบนเป็นจุดอ้างอิง เพื่อให้เมื่อเปลี่ยนขนาด window จะยังอยู่ที่มุมขวาบน
        var defaultX: CGFloat
        var defaultY: CGFloat
        
        if let saved = savedPosition {
            // saved position เป็น origin (มุมซ้ายล่าง) ของ window เก่า
            // ใช้ตำแหน่งที่บันทึกไว้ แต่ปรับให้ window ใหม่อยู่ภายในหน้าจอ
            defaultX = max(visibleFrame.minX, min(saved.x, visibleFrame.maxX - ribbonWidth))
            defaultY = max(visibleFrame.minY, min(saved.y, visibleFrame.maxY - ribbonHeight))
            
            // ถ้า window ใหม่ใหญ่เกินไป ให้ใช้ตำแหน่งเริ่มต้น (มุมขวาบน)
            if defaultX + ribbonWidth > visibleFrame.maxX || defaultY + ribbonHeight > visibleFrame.maxY {
                defaultX = visibleFrame.maxX - ribbonWidth - 20
                defaultY = visibleFrame.maxY - ribbonHeight - 20
            }
        } else {
            // ใช้ตำแหน่งเริ่มต้น: มุมขวาบน
            defaultX = visibleFrame.maxX - ribbonWidth - 20
            defaultY = visibleFrame.maxY - ribbonHeight - 20
        }
        
        // สร้าง custom window class ที่ไม่บล็อก menu bar
        // ใช้ width และ height ที่ส่งมาโดยตรง
        let customWindow = RibbonWindow(
            contentRect: NSRect(x: defaultX, y: defaultY, width: ribbonWidth, height: ribbonHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        customWindow.backgroundColor = .clear
        customWindow.isOpaque = false
        customWindow.hasShadow = false // ปิด shadow เพื่อไม่ให้ดูเหมือน border
        customWindow.level = .floating
        customWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        customWindow.ignoresMouseEvents = false
        customWindow.acceptsMouseMovedEvents = true
        customWindow.isMovableByWindowBackground = false
        
        // ตั้งค่าเพื่อให้ rendering ชัดขึ้น
        customWindow.contentView?.wantsLayer = true
        if let layer = customWindow.contentView?.layer {
            layer.contentsScale = screen.backingScaleFactor
        }
        
        // สร้าง ribbon ID
        let ribbonID = UUID()
        
        // ใช้ custom window แทน
        let hostingView = NSHostingView(rootView: DraggableRibbonView(text: text, color: color, ribbonWindow: customWindow, ribbonID: ribbonID, screen: screen, ribbonManager: self))
        hostingView.frame = customWindow.contentView!.bounds
        
        // ตั้งค่าเพื่อให้ rendering ชัดขึ้น
        hostingView.wantsLayer = true
        if let layer = hostingView.layer {
            layer.contentsScale = screen.backingScaleFactor
            layer.shouldRasterize = false
            layer.isOpaque = false
            layer.masksToBounds = false
            layer.borderWidth = 0
            layer.borderColor = nil
        }
        hostingView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        
        customWindow.contentView = hostingView
        
        // เก็บตำแหน่งและ mapping
        ribbonPositions[ribbonID] = CGPoint(x: defaultX, y: defaultY)
        ribbonIDsByScreen[screen] = ribbonID
        
        return customWindow
        
    }
    
    func savePosition(for ribbonID: UUID, position: CGPoint, screen: NSScreen) {
        ribbonPositions[ribbonID] = position
        // บันทึกไปยัง UserDefaults ทันที
        savePosition(for: screen, position: position)
    }
}

// Custom view ที่รองรับการลาก
struct DraggableRibbonView: NSViewRepresentable {
    let text: String
    let color: Color
    let ribbonWindow: NSWindow
    let ribbonID: UUID
    let screen: NSScreen
    let ribbonManager: RibbonManager
    
    func makeNSView(context: Context) -> NSView {
        let containerView = DraggableContainerView()
        containerView.ribbonWindow = ribbonWindow
        containerView.ribbonID = ribbonID
        containerView.screen = screen
        containerView.ribbonManager = ribbonManager
        
        let hostingView = NSHostingView(rootView: RibbonView(text: text, color: color))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // อัปเดต view ถ้าจำเป็น
    }
}

class DraggableContainerView: NSView {
    var ribbonWindow: NSWindow?
    var ribbonID: UUID?
    var screen: NSScreen?
    var ribbonManager: RibbonManager?
    private var isDragging = false
    private var dragStartScreenPoint: NSPoint = .zero
    private var windowStartOrigin: NSPoint = .zero
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // ตั้งค่าให้ view รับ mouse events
        // ไม่ต้องตั้งค่า acceptsTouchEvents เพราะ deprecated แล้ว
        self.wantsLayer = true
        if let layer = self.layer {
            layer.borderWidth = 0
            layer.borderColor = nil
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        // ใช้ location ใน view coordinate
        let locationInView = self.convert(event.locationInWindow, from: nil)
        
        // ตรวจสอบว่าคลิกที่ ribbon หรือไม่
        if self.bounds.contains(locationInView) {
            isDragging = true
            // เก็บตำแหน่งเริ่มต้นของ window และ mouse ใน screen coordinates
            if let window = ribbonWindow {
                windowStartOrigin = window.frame.origin
                // ใช้ mouse location ใน screen coordinates โดยตรง
                dragStartScreenPoint = NSEvent.mouseLocation
            }
        } else {
            // ถ้าคลิกนอก ribbon ให้ส่ง event ต่อไป (ไม่บล็อก menu bar)
            super.mouseDown(with: event)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if isDragging, let window = ribbonWindow {
            // ใช้ mouse location ใน screen coordinates โดยตรง
            let currentScreenPoint = NSEvent.mouseLocation
            
            // คำนวณ delta จากตำแหน่งเริ่มต้นใน screen coordinates
            let deltaX = currentScreenPoint.x - dragStartScreenPoint.x
            let deltaY = currentScreenPoint.y - dragStartScreenPoint.y
            
            // macOS coordinate system: y increases upward
            var newOrigin = windowStartOrigin
            newOrigin.x += deltaX
            newOrigin.y += deltaY
            
            // จำกัดให้อยู่ในขอบเขตของ screen
            if let screen = window.screen {
                let screenFrame = screen.visibleFrame
                let windowFrame = window.frame
                
                newOrigin.x = max(screenFrame.minX, min(newOrigin.x, screenFrame.maxX - windowFrame.width))
                newOrigin.y = max(screenFrame.minY, min(newOrigin.y, screenFrame.maxY - windowFrame.height))
            }
            
            // อัปเดตตำแหน่ง window
            window.setFrameOrigin(newOrigin)
            
            // อัปเดต windowStartOrigin และ dragStartScreenPoint เพื่อให้การลากต่อเนื่องและ smooth
            windowStartOrigin = newOrigin
            dragStartScreenPoint = currentScreenPoint
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if isDragging {
            // บันทึกตำแหน่งเมื่อลากเสร็จ
            if let window = ribbonWindow,
               let ribbonID = ribbonID,
               let screen = screen,
               let ribbonManager = ribbonManager {
                let currentPosition = window.frame.origin
                ribbonManager.savePosition(
                    for: ribbonID,
                    position: CGPoint(x: currentPosition.x, y: currentPosition.y),
                    screen: screen
                )
            }
        }
        isDragging = false
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // แปลง point เป็น local coordinate
        let localPoint = self.convert(point, from: nil)
        
        // ตรวจสอบว่าคลิกที่ ribbon หรือไม่
        // ใช้ bounds ที่ถูกต้อง
        if self.bounds.contains(localPoint) {
            // คลิกที่ ribbon - ให้ return self เพื่อให้ลากได้
            return self
        }
        // คลิกนอก ribbon - return nil เพื่อให้ event ผ่านไปยัง menu bar
        return nil
    }
    
    override func mouseEntered(with event: NSEvent) {
        // เมื่อ mouse เข้ามาใน ribbon
        super.mouseEntered(with: event)
    }
    
    override func mouseExited(with event: NSEvent) {
        // เมื่อ mouse ออกจาก ribbon
        super.mouseExited(with: event)
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        // รับ mouse event แรกเพื่อให้ลากได้ทันที
        return true
    }
}

struct RibbonView: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                )
        }
        .compositingGroup()
    }
}
