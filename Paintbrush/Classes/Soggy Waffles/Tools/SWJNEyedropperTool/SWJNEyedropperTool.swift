//
//  SWJNEyedropperTool.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 17/8/2026.
//

import Foundation

@objcMembers class SWJNEyedropperTool : SWJNTool {
    override func performDraw(from point: CGPoint,
                              on mainBitmap: NSBitmapImageRep, and bufferBitmap: NSBitmapImageRep,
                              for mouseEvent: SWJNMouseEvent) -> NSBezierPath? {
        if let color: NSColor = mainBitmap.colorAt(x: point.x.int, y: mainBitmap.pixelsHigh - point.y.int - 1) {
            guard let converted: NSColor = color.usingColorSpace(.deviceRGB) else {
                return nil
            }
            
            if flags.contains(.option) {
                toolboxController.backgroundColorWell.color = converted
            } else {
                toolboxController.foregroundColorWell.color = converted
            }
        }
        
        return nil
    }
    
    nonisolated override var description: String {
        "Eyedropper"
    }
}
