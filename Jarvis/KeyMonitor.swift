import Cocoa
import Carbon

class KeyMonitor {
    var onDoubleControl: (() -> Void)?
    var onDoubleOption: (() -> Void)?
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    // Control tracking
    private var lastControlRelease: Date?
    private var controlPressed = false
    
    // Option tracking
    private var lastOptionRelease: Date?
    private var optionPressed = false
    
    private let doubleTapInterval: TimeInterval = 0.4
    
    func start() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        // Global monitor (when app doesn't have focus)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handler)
        
        // Local monitor (when app has focus)  
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            handler(event)
            return event
        }
    }
    
    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags
        let now = Date()
        
        // Debug logging
        print("🔑 Flags changed: Control=\(flags.contains(.control)) Option=\(flags.contains(.option))")
        
        // ===== CONTROL KEY =====
        let controlIsPressed = flags.contains(.control)
        
        if controlIsPressed && !controlPressed {
            // Control just pressed - do nothing
            controlPressed = true
        } else if !controlIsPressed && controlPressed {
            // Control just released
            controlPressed = false
            
            if let lastRelease = lastControlRelease, now.timeIntervalSince(lastRelease) < doubleTapInterval {
                // Second release - fire!
                print("🔥 Control double-tap detected! Firing callback...")
                DispatchQueue.main.async { [weak self] in
                    self?.onDoubleControl?()
                }
                lastControlRelease = nil
            } else {
                lastControlRelease = now
            }
        }
        
        // ===== OPTION KEY =====
        let optionIsPressed = flags.contains(.option)
        
        if optionIsPressed && !optionPressed {
            // Option just pressed - do nothing
            optionPressed = true
        } else if !optionIsPressed && optionPressed {
            // Option just released
            optionPressed = false
            
            if let lastRelease = lastOptionRelease, now.timeIntervalSince(lastRelease) < doubleTapInterval {
                // Second release - fire!
                print("🔥 Option double-tap detected! Firing callback...")
                DispatchQueue.main.async { [weak self] in
                    self?.onDoubleOption?()
                }
                lastOptionRelease = nil
            } else {
                lastOptionRelease = now
            }
        }
    }
    
    deinit {
        stop()
    }
}
