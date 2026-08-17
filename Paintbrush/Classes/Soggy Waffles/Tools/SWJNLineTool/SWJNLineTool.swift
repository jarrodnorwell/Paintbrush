//
//  SWJNLineTool.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 17/8/2026.
//

import Foundation

@objcMembers class SWJNLineTool : SWJNTool {
    private var color: NSColor = .black
    
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
            let x: CGFloat = (to.x - from.x) / abs(to.x - from.x)
            let y: CGFloat = (to.y - from.y) / abs(to.y - from.y)
            
            let theta: CGFloat = 180 * atan((to.y - from.y) / (to.x - from.x)) / .pi
            
            var newPoint: NSPoint = .zero
            let size: CGFloat = min(abs(to.x - from.x), abs(to.y - from.y))
            
            if abs(theta) <= 67.5 && abs(theta) >= 22.5 {
                newPoint = NSPoint(x: size * x, y: size * y)
            } else if abs(theta) > 67.5 {
                newPoint = NSPoint(x: 0, y: to.y - from.y)
            } else {
                newPoint = NSPoint(x: to.x - from.x, y: 0)
            }
            
            bezierPath.relativeLine(to: newPoint)
        } else {
            bezierPath.line(to: to)
        }
        
        return bezierPath
    }
    
    override func performDraw(from point: CGPoint,
                              on mainBitmap: NSBitmapImageRep, and bufferBitmap: NSBitmapImageRep,
                              for mouseEvent: SWJNMouseEvent) -> NSBezierPath? {
        _ = insertRedrawRect(from: point, to: savedPoint)
        
        SWImageTools.clearImage(bufferBitmap)
        
        if mouseEvent == .up {
            document.handleUndo(withImageData: nil, frame: .zero)
            canvasBitmapRep = mainBitmap
        } else {
            canvasBitmapRep = bufferBitmap
        }
        
        if mouseEvent == .down {
            color = flags.contains(.option) ? backgroundColor : foregroundColor
        }
        
        SWLockFocus(canvasBitmapRep)
        
        if let context: NSGraphicsContext = NSGraphicsContext.current {
            context.shouldAntialias = false
        }
        
        color.setStroke()
        
        if let path = bezierPath(from: savedPoint, to: point) {
            path.stroke()
        }
        
        SWUnlockFocus(canvasBitmapRep)
        
        return nil
    }
    
    nonisolated override var description: String {
        "Line"
    }
}
