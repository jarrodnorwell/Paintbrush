//
//  SWJNImageTools.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 15/8/2026.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

private extension BinaryFloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

@objcMembers class SWJNImageTools : NSObject {
    static let shared: SWJNImageTools = SWJNImageTools()
    
    func convert(from fileType: String) -> String {
        var string: String = ""
        
        let lowercasedString: String = fileType.lowercased()
        string = if lowercasedString.count == 3 {
            lowercasedString
        } else {
            if lowercasedString == "jpeg" {
                "jpg"
            } else if lowercasedString == "tiff" {
                "tif"
            } else {
                ""
            }
        }
        
        return string
    }
    
    func clean(fileType: String) -> String {
        var string: String = fileType.lowercased()
        return if string == "jpeg" {
            "jpeg"
        } else if string == "tiff" {
            "tif"
        } else {
            string
        }
    }
    
    // MARK: Image Tools
    func clear(image: NSBitmapImageRep? = nil, in rect: NSRect = .zero) {
        guard let image: NSBitmapImageRep else {
            return
        }
        
        let validRect: NSRect = if rect == .zero {
            NSRect(origin: CGPoint(x: 0, y: 0),
                   size: CGSize(width: image.pixelsWide,
                                height: image.pixelsHigh))
        } else {
            rect
        }
        
        lock(image: image)
        
        NSColor.white.setFill()
        validRect.fill(using: .copy)
        
        unlock()
    }
    
    func crop(image: NSBitmapImageRep, to rect: NSRect = .zero) -> NSBitmapImageRep {
        print(#function)
        
        return NSBitmapImageRep()
    }
    
    func draw(to firstImage: NSBitmapImageRep? = nil, from secondImage: NSBitmapImageRep? = nil,
              at point: NSPoint = .zero, with compositing: Bool) {
        guard let firstImage: NSBitmapImageRep, let secondImage: NSBitmapImageRep else {
            return
        }
        
        lock(image: firstImage)
        
        let compositingOperation: NSCompositingOperation = if compositing {
            .sourceOver
        } else {
            .copy
        }
        
        if let context: NSGraphicsContext = NSGraphicsContext.current {
            context.compositingOperation = compositingOperation
            if let cgImage: CGImage = secondImage.cgImage {
                context.cgContext.draw(cgImage, in: CGRect(origin: point,
                                                           size: CGSize(width: secondImage.pixelsWide, height: secondImage.pixelsHigh)))
            }
        }
        
        unlock()
    }
    
    func initialise(image: inout NSBitmapImageRep, with size: NSSize = .zero) {
        guard let generatedImage: NSBitmapImageRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                                                      pixelsWide: size.width.int,
                                                                      pixelsHigh: size.height.int,
                                                                      bitsPerSample: 8,
                                                                      samplesPerPixel: 4,
                                                                      hasAlpha: true,
                                                                      isPlanar: false,
                                                                      colorSpaceName: .deviceRGB,
                                                                      bytesPerRow: 0,
                                                                      bitsPerPixel: 32) else {
            return
        }
        
        image = generatedImage
        clear(image: generatedImage)
    }
    
    func initialize(with size: NSSize = .zero) -> NSBitmapImageRep {
        var bitmap: NSBitmapImageRep = NSBitmapImageRep()
        initialise(image: &bitmap, with: size)
        return bitmap
    }
    
    func invert(image: NSBitmapImageRep) {
        var bitmapImage: NSBitmapImageRep = NSBitmapImageRep()
        initialise(image: &bitmapImage, with: image.size)
        draw(to: bitmapImage, from: image, with: false)
        
        let colorInvertFilter: CIFilter = CIFilter.colorInvert()
        colorInvertFilter.setValue(CIImage(bitmapImageRep: bitmapImage), forKey: "inputImage")
        
        guard let outputImage: CIImage = colorInvertFilter.outputImage else {
            return
        }
        
        bitmapImage = NSBitmapImageRep(ciImage: outputImage)
        draw(to: image, from: bitmapImage, with: false)
    }
    
    func remove(color: NSColor, from image: NSBitmapImageRep) {
        guard let bitmapData = image.bitmapData else {
            return
        }
        
        let pixelsWide = image.pixelsWide
        let pixelsHigh = image.pixelsHigh
        let bytesPerRow = image.bytesPerRow
        let samplesPerPixel = image.samplesPerPixel
        let bitsPerSample = image.bitsPerSample
        
        guard bitsPerSample == 8, samplesPerPixel >= 4 else {
            return
        }
        
        let deviceRGB = color.usingColorSpace(.deviceRGB) ?? color
        
        var rComp: CGFloat = 0
        var gComp: CGFloat = 0
        var bComp: CGFloat = 0
        var aComp: CGFloat = 0
        deviceRGB.getRed(&rComp, green: &gComp, blue: &bComp, alpha: &aComp)
        
        let r = UInt8((rComp * 255.0).rounded().clamped(to: 0...255))
        let g = UInt8((gComp * 255.0).rounded().clamped(to: 0...255))
        let b = UInt8((bComp * 255.0).rounded().clamped(to: 0...255))
        let a = UInt8((aComp * 255.0).rounded().clamped(to: 0...255))
        
        for row in 0..<pixelsHigh {
            let rowStart = row * bytesPerRow
            for col in 0..<pixelsWide {
                let pixelIndex = rowStart + col * samplesPerPixel
                
                let red   = bitmapData[pixelIndex]
                let green = bitmapData[pixelIndex + 1]
                let blue  = bitmapData[pixelIndex + 2]
                let alpha = bitmapData[pixelIndex + 3]
                
                if (alpha == 0 && a == 0) || (red == r && green == g && blue == b && alpha == a) {
                    bitmapData[pixelIndex]     = 0
                    bitmapData[pixelIndex + 1] = 0
                    bitmapData[pixelIndex + 2] = 0
                    bitmapData[pixelIndex + 3] = 0
                }
            }
        }
    }
    
    // MARK: Other
    func lock(image: NSBitmapImageRep? = nil) {
        guard let image: NSBitmapImageRep else {
            return
        }
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: image)
    }
    
    func unlock() {
        NSGraphicsContext.restoreGraphicsState()
    }
}
