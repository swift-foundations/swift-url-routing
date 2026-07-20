//
//  Measurement+InformationStorage.swift
//  swift-url-routing
//
//  MeasurementFormatter is unavailable in swift-corelibs-foundation
//  (Linux), where it traps the whole module out of compiling. Error
//  descriptions need only a short "value unit-symbol" rendering, which
//  is portable by hand.
//

import Foundation

extension Measurement where UnitType == UnitInformationStorage {
    /// Portable short rendering ("512 bytes", "1.5 MB") for error
    /// descriptions; `MeasurementFormatter` is unavailable on Linux.
    /// `@usableFromInline`: referenced from `@inlinable` parser bodies.
    @usableFromInline
    var shortDescription: String {
        let rendered = value == value.rounded()
            ? String(Int(value))
            : String(value)
        return "\(rendered) \(unit.symbol)"
    }
}
