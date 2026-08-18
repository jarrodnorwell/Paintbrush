//
//  SWJNTool.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 13/8/2026.
//

import Cocoa
import Foundation

@objcMembers class SWJNTool : NSObject {
    @objc enum SWJNFillStyle : Int {
        case stroke,
             fill,
             strokeAndFill
    }
    
    @objc enum SWJNMouseEvent : Int {
        case down,
             dragged,
             moved,
             up
    }
    
    var foregroundColor: NSColor = .white
    var backgroundColor: NSColor = .black
    
    var canvasBitmapRep: NSBitmapImageRep? = nil
    var bufferBitmapRep: NSBitmapImageRep? = nil
    var mainBitmapRep: NSBitmapImageRep? = nil
    
    var bezierPath: NSBezierPath? = nil
    
    var lineWidth: CGFloat = 0
    
    var fill: Bool = false,
        stroke: Bool = false
    
    var showFillOptions: Bool = false,
        showTransparencyOptions: Bool = false
    var showContextualMenu: Bool = false
    
    var flags: NSEvent.ModifierFlags = NSEvent.modifierFlags
    
    var savedPoint: NSPoint = .zero
    
    var redrawRect: NSRect = .zero,
        savedRect: NSRect = .zero
    
    var invalidRect: NSRect { redrawRect }
    
    var document: SWDocument
    
    var paintView: SWPaintView
    var toolbox: SWToolbox
    var toolboxController: SWToolboxController
    
    init(document: SWDocument, paintView: SWPaintView, toolbox: SWToolbox, toolboxController: SWToolboxController) {
        self.document = document
        self.paintView = paintView
        self.toolbox = toolbox
        self.toolboxController = toolboxController
        super.init()
        
        toolboxController.addObserver(self, forKeyPath: "lineWidth", options: .new, context: nil)
        toolboxController.addObserver(self, forKeyPath: "foregroundColor", options: .new, context: nil)
        toolboxController.addObserver(self, forKeyPath: "backgroundColor", options: .new, context: nil)
        toolboxController.addObserver(self, forKeyPath: "fillStyle", options: .new, context: nil)
    }
    
    deinit {
        toolboxController.removeObserver(self, forKeyPath: "lineWidth")
        toolboxController.removeObserver(self, forKeyPath: "foregroundColor")
        toolboxController.removeObserver(self, forKeyPath: "backgroundColor")
        toolboxController.removeObserver(self, forKeyPath: "fillStyle")
    }
    
    nonisolated override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let change: [NSKeyValueChangeKey : Any], let value: Any = change[.newKey] else {
            return
        }
        
        switch keyPath {
        case "lineWidth":
            if let cgFloat = value as? CGFloat {
                Task { @MainActor in
                    self.lineWidth = cgFloat
                }
            }
        case "foregroundColor":
            if let color = value as? NSColor {
                Task { @MainActor in
                    self.foregroundColor = color
                }
            }
        case "backgroundColor":
            if let color = value as? NSColor {
                Task { @MainActor in
                    self.backgroundColor = color
                }
            }
        case "fillStyle":
            if let fillStyle = value as? Int {
                Task { @MainActor in
                    self.fill = fillStyle == SWJNFillStyle.fill.rawValue || fillStyle == SWJNFillStyle.strokeAndFill.rawValue
                    self.stroke = fillStyle == SWJNFillStyle.stroke.rawValue || fillStyle == SWJNFillStyle.strokeAndFill.rawValue
                }
            }
        default:
            break
        }
    }
    
    func insertRedrawRect(from beginningPoint: CGPoint, to endingPoint: CGPoint) -> CGRect {
        insertRedrawRect(to: CGRect(origin: CGPoint(x: round(fmin(beginningPoint.x, endingPoint.x) - (lineWidth / 2) - 1),
                                                    y: round(fmin(beginningPoint.y, endingPoint.y) - (lineWidth / 2) - 1)),
                                    size: CGSize(width: (abs(beginningPoint.x - endingPoint.x) + lineWidth + 2),
                                                 height: (abs(beginningPoint.y - endingPoint.y) + lineWidth + 2))))
    }
    
    func insertRedrawRect(to rect: CGRect) -> CGRect {
        redrawRect = CGRectUnion(rect, savedRect)
        savedRect = rect
        redrawRect.size.width += 1.0
        return redrawRect
    }
    
    func bezierPath(from beginningPoint: CGPoint, to endingPoint: CGPoint) -> NSBezierPath? { nil }
    
    func performDraw(from point: CGPoint,
                     on mainBitmap: NSBitmapImageRep, and bufferBitmap: NSBitmapImageRep,
                     for mouseEvent: SWJNMouseEvent) -> NSBezierPath? { nil }
    
    // MARK: Additional
    func deleteKey() {}
    func mouseDidMove(to point: NSPoint) {}
    
    func finalise() {
        print("[I]: Finalising use of tool: \(className)")
    }
}

