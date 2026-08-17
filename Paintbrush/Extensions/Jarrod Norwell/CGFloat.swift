//
//  CGFloat.swift
//  Paintbrush
//
//  Created by Jarrod Norwell on 14/8/2026.
//

import Foundation

extension CGFloat {
    var int: Int { Int(self) }
    
    var uint32: UInt32 { UInt32(self) }
    
    func neq(to: CGFloat) -> Bool { self != to }
}
