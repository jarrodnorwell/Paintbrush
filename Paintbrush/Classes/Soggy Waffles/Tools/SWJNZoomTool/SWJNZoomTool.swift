//
//  SWJNZoomTool.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 17/8/2026.
//

import Foundation

@objcMembers class SWJNZoomTool : SWJNTool {
    override func performDraw(from point: CGPoint,
                              on mainBitmap: NSBitmapImageRep, and bufferBitmap: NSBitmapImageRep,
                              for mouseEvent: SWJNMouseEvent) -> NSBezierPath? {
        if mouseEvent == .down {
            savedPoint = point
            
            flags.contains(.option) ? document.zoomOut(self) : document.zoomIn(self)
        }
        return nil
    }
    
    nonisolated override var description: String {
        "Zoom"
    }
}
