//
//  SWJNTextTool.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 17/8/2026.
//

import Foundation

@objcMembers class SWJNTextTool : SWJNTool {
    struct Variables {
        var isAllowedToInsertText: Bool
        var attributedStringToInsert: NSAttributedString? = nil
    }
    
    private var variables: Variables
    
    override init(document: SWDocument, paintView: SWPaintView, toolbox: SWToolbox, toolboxController: SWToolboxController) {
        variables = Variables(isAllowedToInsertText: false,
                              attributedStringToInsert: nil)
        super.init(document: document, paintView: paintView, toolbox: toolbox, toolboxController: toolboxController)
        NotificationCenter.default.addObserver(self, selector: #selector(insertText(notification:)),
                                               name: .textEnteredNotificationName,
                                               object: nil)
    }
    
    override func performDraw(from point: CGPoint,
                              on mainBitmap: NSBitmapImageRep, and bufferBitmap: NSBitmapImageRep,
                              for mouseEvent: SWJNMouseEvent) -> NSBezierPath? {
        bufferBitmapRep = bufferBitmap
        mainBitmapRep = mainBitmap
        
        SWImageTools.clearImage(bufferBitmap)
        
        if variables.isAllowedToInsertText {
            if mouseEvent == .moved {
                canvasBitmapRep = bufferBitmap
            } else if mouseEvent == .down {
                document.handleUndo(withImageData: nil, frame: .zero)
                canvasBitmapRep = mainBitmap
                variables.isAllowedToInsertText = false
            } else {
                return nil
            }
            
            guard let attributedStringToInsert: NSAttributedString = variables.attributedStringToInsert else {
                return nil
            }
            
            guard let canvasBitmapRep: NSBitmapImageRep else {
                return nil
            }
            
            let size: NSSize = attributedStringToInsert.size()
            var rect: NSRect = attributedStringToInsert.boundingRect(with: size, options: .usesFontLeading.union(.usesDeviceMetrics))
            
            let xOffset: CGFloat = abs(rect.origin.x)
            let yOffset: CGFloat = abs(rect.origin.y)
            
            rect.size.width += xOffset + size.width
            rect.size.height += yOffset + size.height
            
            rect.origin = NSPoint(x: floor(point.x), y: floor(point.y))
            rect.origin.y -= rect.size.height
            rect.origin.y += yOffset
            
            _ = insertRedrawRect(to: rect)
            
            rect.origin.x += xOffset
            rect.origin.y = canvasBitmapRep.pixelsHigh.float - rect.origin.y - rect.size.height
            
            SWLockFocus(canvasBitmapRep)
            
            let transform: NSAffineTransform = NSAffineTransform(transform: .identity)
            transform.scaleX(by: 1.0, yBy: -1.0)
            transform.translateX(by: 0.0, yBy: 0.0 - canvasBitmapRep.pixelsHigh.float)
            transform.concat()
            
            attributedStringToInsert.draw(at: rect.origin)
            
            SWUnlockFocus(canvasBitmapRep)
            
            paintView.refreshImage(nil)
        } else if mouseEvent == .down {
            NotificationCenter.default.post(name: .textNotificationName, object: foregroundColor)
            variables.isAllowedToInsertText = true
        }
        
        return nil
    }
    
    override func mouseDidMove(to point: NSPoint) {
        guard let bufferBitmapRep: NSBitmapImageRep, let mainBitmapRep: NSBitmapImageRep else {
            return
        }
        
        _ = performDraw(from: point, on: mainBitmapRep, and: bufferBitmapRep, for: .moved)
    }
    
    @objc func insertText(notification: NSNotification) {
        guard let attributedString: NSAttributedString = notification.object as? NSAttributedString else {
            return
        }
        
        variables.attributedStringToInsert = NSAttributedString(attributedString: attributedString)
        
        paintView.refreshImage(nil)
    }
    
    override func finalise() {
        super.finalise()
        variables.isAllowedToInsertText = false
        variables.attributedStringToInsert = nil
    }
    
    nonisolated override var description: String {
        "Text"
    }
}
