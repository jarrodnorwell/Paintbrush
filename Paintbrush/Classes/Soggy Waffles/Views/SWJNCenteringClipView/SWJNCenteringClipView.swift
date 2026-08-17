//
//  SWJNCenteringClipView.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 15/8/2026.
//

import Foundation

@objcMembers class SWJNCenteringClipView : NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var constrainedBounds: CGRect = super.constrainBoundsRect(proposedBounds)
        
        guard let documentView: NSView else {
            return NSRect()
        }
        
        let documentRect: NSRect = documentView.frame
        
        let maxX: CGFloat = documentRect.width - constrainedBounds.width
        let maxY: CGFloat = documentRect.height - constrainedBounds.height
        
        constrainedBounds.origin.x = if documentRect.width < constrainedBounds.width {
            round(maxX / 2.0)
        } else {
            round(max(0, min(constrainedBounds.origin.x, maxX)))
        }
        
        constrainedBounds.origin.y = if documentRect.height < constrainedBounds.height {
            round(maxY / 2.0)
        } else {
            round(max(0, min(constrainedBounds.origin.y, maxY)))
        }
        
        return constrainedBounds
    }
    
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        
        guard let documentView: NSView else {
            return
        }
        
        let rect: NSRect = documentView.frame
        
        if shadow.isNil {
            shadow = NSShadow()
            guard let shadow: NSShadow else {
                return
            }
            
            shadow.shadowBlurRadius = 8.0
            shadow.shadowColor = NSColor.secondarySystemFill
            shadow.shadowOffset = .zero
        }
        
        if let shadow: NSShadow {
            shadow.set()
        }
        
        rect.fill()
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    override func viewBoundsChanged(_ notification: Notification) {
        super.viewBoundsChanged(notification)
        center()
    }
    
    override func viewFrameChanged(_ notification: Notification) {
        super.viewFrameChanged(notification)
        center()
    }
    
    
    override func setBoundsOrigin(_ newOrigin: NSPoint) {
        super.setBoundsOrigin(newOrigin)
        center()
    }
    
    override func setBoundsSize(_ newSize: NSSize) {
        super.setBoundsSize(newSize)
        center()
    }
    
    override var frame: NSRect {
        didSet {
            center()
        }
    }
    
    override func setFrameOrigin(_ newOrigin: NSPoint) {
        super.setFrameOrigin(newOrigin)
        center()
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        center()
    }
    
    override var frameRotation: CGFloat {
        didSet {
            center()
        }
    }
    
    func center() {
        guard let documentView: NSView else {
            return
        }
        
        let documentRect: CGRect = documentView.frame
        var clipRect: CGRect = bounds
        
        if documentRect.width < clipRect.width {
            clipRect.origin.x = round((documentRect.width - clipRect.width) / 2.0)
        }
        
        if documentRect.height < clipRect.height {
            clipRect.origin.y = round((documentRect.height - clipRect.height) / 2.0)
        }
        
        scroll(to: clipRect.origin)
    }
}
