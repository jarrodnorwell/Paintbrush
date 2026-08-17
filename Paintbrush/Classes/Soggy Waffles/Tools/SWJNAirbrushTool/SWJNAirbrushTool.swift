//
//  SWJNAirbrushTool.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 13/8/2026.
//

import Foundation

@objcMembers class SWJNAirbrushTool : SWJNTool {
    struct Variables {
        var isCurrentlyAirbrushing: Bool
        var currentAirbrushPoint: CGPoint
        var airbrushUpdateTimer: Timer? = nil
    }
    
    var variables: Variables
    override init(document: SWDocument, paintView: SWPaintView, toolbox: SWToolbox, toolboxController: SWToolboxController) {
        variables = Variables(isCurrentlyAirbrushing: false,
                              currentAirbrushPoint: .zero,
                              airbrushUpdateTimer: nil)
        super.init(document: document, paintView: paintView, toolbox: toolbox, toolboxController: toolboxController)
    }
    
    override func bezierPath(from beginningPoint: CGPoint, to endingPoint: CGPoint) -> NSBezierPath? {
        redrawRect = NSRect(x: endingPoint.x - 2 * lineWidth,
                            y: endingPoint.y - 2 * lineWidth,
                            width: 4 * lineWidth,
                            height: 4 * lineWidth)
        
        let circleBezierPath: NSBezierPath = NSBezierPath(ovalIn: redrawRect)
        let bezierPath: NSBezierPath = NSBezierPath()
        
        let diameter: CGFloat = 4 * lineWidth
        let particleCount: Int = lineWidth.int * lineWidth.int / 2
        
        for _ in 0..<particleCount {
            var point: CGPoint
            
            repeat {
                point = CGPoint(x: .random(in: 0..<diameter) + endingPoint.x - 2 * lineWidth,
                                y: .random(in: 0..<diameter) + endingPoint.y - 2 * lineWidth)
            } while !circleBezierPath.contains(point)
            
            bezierPath.appendRect(CGRect(origin: CGPoint(x: point.x, y: point.y), size: CGSize(width: 0, height: 0)))
        }
        
        return bezierPath
    }
    
    override func performDraw(from point: CGPoint,
                              on mainBitmap: NSBitmapImageRep, and bufferBitmap: NSBitmapImageRep,
                              for mouseEvent: SWJNMouseEvent) -> NSBezierPath? {
        variables.currentAirbrushPoint = point
        
        switch mouseEvent {
        case .down:
            bufferBitmapRep = bufferBitmap
            mainBitmapRep = mainBitmap
            
            SWImageTools.draw(toImage: bufferBitmapRep, fromImage: mainBitmapRep, withComposition: false)
            
            variables.airbrushUpdateTimer = Timer.scheduledTimer(timeInterval: 0.02,
                                                                 target: self,
                                                                 selector: #selector(airbrush(timer:)),
                                                                 userInfo: nil,
                                                                 repeats: true)
            
            variables.isCurrentlyAirbrushing = true
        case .up:
            finaliseAirbrushing(with: variables.airbrushUpdateTimer)
        default:
            break
        }
        
        bezierPath = nil
        return nil
    }
    
    @objc func airbrush(timer: Timer) {
        SWLockFocus(bufferBitmapRep)
        
        if let context: NSGraphicsContext = NSGraphicsContext.current {
            context.shouldAntialias = false
        }
        
        flags.contains(.option) ? backgroundColor.setStroke() : foregroundColor.setStroke()
        
        if let path = bezierPath(from: savedPoint, to: variables.currentAirbrushPoint) {
            path.stroke()
        }
        
        savedPoint = variables.currentAirbrushPoint
        
        SWUnlockFocus(bufferBitmapRep)
        
        paintView.refreshImage(nil)
    }
    
    func finaliseAirbrushing(with timer: Timer? = nil) {
        guard let timer: Timer else {
            return
        }
        
        timer.invalidate()
        
        variables.isCurrentlyAirbrushing = false
        
        document.handleUndo(withImageData: nil, frame: .zero)
        
        SWImageTools.draw(toImage: mainBitmapRep, fromImage: bufferBitmapRep, withComposition: false)
        SWImageTools.clearImage(bufferBitmapRep)
    }
    
    override func finalise() {
        super.finalise()
        if variables.isCurrentlyAirbrushing {
            finaliseAirbrushing(with: variables.airbrushUpdateTimer)
        }
    }
    
    nonisolated override var description: String {
        "Airbrush"
    }
}
