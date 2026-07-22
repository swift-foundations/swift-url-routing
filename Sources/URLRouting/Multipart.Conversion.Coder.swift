import Foundation
public import HTTP_Body
import Media_Type_Standard
public import RFC_2046
public import RFC_3986

extension RFC_2046.Multipart.Conversion {
    /// Transitional HTTP body coder over the existing multipart conversion.
    ///
    /// Its static media identity is `multipart/form-data`; encode returns the
    /// conversion's realized boundary and decode rebuilds the conversion from
    /// the boundary carried by the request's `Content-Type`.
    public struct Coder: @unchecked Sendable {
        @usableFromInline
        let conversion: RFC_2046.Multipart.Conversion<Value>

        @inlinable
        public init(_ conversion: RFC_2046.Multipart.Conversion<Value>) {
            self.conversion = conversion
        }
    }
}

extension RFC_2046.Multipart.Conversion.Coder: RFC_9110.Body.Coder.`Protocol` {
    public typealias Input = [Byte]
    public typealias Buffer = [Byte]
    public typealias Output = Value
    public typealias Failure = RFC_3986.URI.Routing.Error
    public typealias Body = Never

    @inlinable
    public var body: Never {
        borrowing get {
            fatalError("leaf codec — parse(_:) and serialize(_:into:) are implemented directly")
        }
    }

    public static var contentType: HTTP.MediaType { .formData }

    @inlinable
    public func parse(_ input: inout [Byte]) throws(Failure) -> Value {
        let data = Foundation.Data(input.map(\.underlying))
        let output = try conversion.apply(data)
        input = []
        return output
    }

    @inlinable
    public func decode(
        _ input: inout [Byte],
        as mediaType: HTTP.MediaType
    ) throws(Failure) -> Value {
        guard let rawBoundary = mediaType.parameters["boundary"] else {
            throw RFC_3986.URI.Routing.Error(
                component: .header(name: "Content-Type"),
                failure: .invalid("multipart/form-data requires a boundary parameter")
            )
        }

        let boundary: RFC_2046.Boundary
        do {
            boundary = try RFC_2046.Boundary(rawBoundary)
        } catch {
            throw RFC_3986.URI.Routing.Error(
                component: .header(name: "Content-Type"),
                failure: .invalid("\(error)")
            )
        }

        let decoding = RFC_2046.Multipart.Conversion(
            Value.self,
            encoder: conversion.encoder,
            boundary: boundary
        )
        let data = Foundation.Data(input.map(\.underlying))
        let output = try decoding.apply(data)
        input = []
        return output
    }

    @inlinable
    public func serialize(_ output: Value, into buffer: inout [Byte]) throws(Failure) {
        let data = try conversion.unapply(output)
        buffer.append(contentsOf: data.map(Byte.init))
    }

    @inlinable
    public func encode(
        _ output: Value,
        into buffer: inout [Byte]
    ) throws(Failure) -> HTTP.MediaType {
        try serialize(output, into: &buffer)
        return HTTP.MediaType(conversion.contentType)
    }
}
