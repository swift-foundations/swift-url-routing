//
//  Parse+conversion.swift
//  swift-url-routing
//
//  Created by Coen ten Thije Boonkkamp on 15/11/2025.
//

import Parsing

extension Parse {
    @_disfavoredOverload
    @inlinable
    public init<Downstream>(
        _ conversion: Downstream
    ) where Parsers == Parsing.Parsers.MapConversion<Rest<Downstream.Input>, Downstream> {
        self.init { Rest().map(conversion) }
    }
}
