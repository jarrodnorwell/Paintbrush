//
//  SWJNEllipseTool.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 19/8/2026.
//

import Foundation

@objcMembers class SWJNEllipseTool : SWJNTool {
    private var primaryColor: NSColor? = nil,
                secondaryColor: NSColor? = nil
    
    override func bezierPath(from beginningPoint: CGPoint, to endingPoint: CGPoint) -> NSBezierPath? {
        bezierPath = NSBezierPath()
        guard let bezierPath: NSBezierPath else {
            return nil
        }
        bezierPath.lineWidth = lineWidth
        bezierPath.move(to: beginningPoint)
        
        var from: NSPoint = beginningPoint
        var to: NSPoint = endingPoint
        if lineWidth.int <= 1 {
            from.x += 0.5
            from.y += 0.5
            
            to.x += 0.5
            to.y += 0.5
        }
        
        if flags.contains(.shift) {
            let size: CGFloat = min(abs(to.x - from.x), abs(to.y - from.y))
            let x: CGFloat = (to.x - from.x) / abs(to.x - from.x)
            let y: CGFloat = (to.y - from.y) / abs(to.y - from.y)
            
            bezierPath.appendOval(in: NSRect(x: from.x, y: from.y, width: x * size, height: y * size))
        } else {
            bezierPath.appendOval(in: NSRect(x: from.x, y: from.y, width: to.x - from.x, height: to.y - from.y))
        }
        
        return bezierPath
    }
    
    override func performDraw(from point: CGPoint,
                              on mainBitmap: NSBitmapImageRep, and bufferBitmap: NSBitmapImageRep,
                              for mouseEvent: SWJNMouseEvent) -> NSBezierPath? {
        _ = insertRedrawRect(from: savedPoint, to: point)
        
        SWImageTools.clearImage(bufferBitmap)
        
        switch mouseEvent {
        case .up:
            document.handleUndo(withImageData: nil, frame: .zero)
            canvasBitmapRep = mainBitmap
        default:
            canvasBitmapRep = bufferBitmap
        }
        
        SWLockFocus(canvasBitmapRep)
        
        if let context: NSGraphicsContext = NSGraphicsContext.current {
            context.shouldAntialias = false
        }
        
        if mouseEvent == .down {
            primaryColor = if flags.contains(.option) {
                backgroundColor
            } else {
                foregroundColor
            }
            
            secondaryColor = if flags.contains(.option) {
                foregroundColor
            } else {
                backgroundColor
            }
        }
        
        guard let primaryColor: NSColor, let secondaryColor: NSColor else {
            return nil
        }
        
        _ = bezierPath(from: savedPoint, to: point)
        guard let bezierPath: NSBezierPath else {
            return nil
        }
        
        if fill.and(stroke) {
            primaryColor.setStroke()
            secondaryColor.setFill()
            
            bezierPath.fill()
            bezierPath.stroke()
        } else if fill {
            primaryColor.setFill()
            bezierPath.fill()
        } else if stroke {
            primaryColor.setStroke()
            bezierPath.stroke()
        }
        
        SWUnlockFocus(canvasBitmapRep)
        
        return nil
    }
    
    nonisolated override var description: String {
        "Ellipse"
    }
}
