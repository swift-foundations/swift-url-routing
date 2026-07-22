public import Foundation
public import HTTP_Body
import Media_Type_Standard
import RFC_2045
public import RFC_2046
public import RFC_3986
import RFC_7230

extension URLRouting {
    /// A request-level body router.
    ///
    /// The unlabeled initializer preserves the legacy conversion behavior: it
    /// reads and writes body bytes but does not touch headers. The `coding:`
    /// initializer is the B4 opt-in and couples those bytes to `Content-Type`.
    /// Keeping both operations at this request level is load-bearing — a
    /// `Parser.Conversion` over `Foundation.Data` cannot see request headers.
    public struct Body<Output> {
        @usableFromInline
        let _parse: (inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) -> Output

        @usableFromInline
        let _serialize:
            (Output, inout RFC_3986.URI.Request.Data) throws(RFC_3986.URI.Routing.Error) -> Void

        /// Preserves the pre-B4 byte-only behavior for compatibility.
        @available(
            *,
            deprecated,
            message: "Use URLRouting.Body(coding:) so body bytes and Content-Type travel together."
        )
        public init<C: Parser.Conversion.`Protocol`>(
            _ conversion: C,
            maxSize: Measurement<UnitInformationStorage> = RFC_7230.Body.Parser<
                URLRouting.Rest<Foundation.Data>
            >.defaultMaxSize
        ) where C.Input == Foundation.Data, C.Output == Output {
            let parser = RFC_7230.Body.Parser(conversion, maxSize: maxSize)
            self._parse = { input throws(RFC_3986.URI.Routing.Error) in
                try parser.parse(&input)
            }
            self._serialize = { output, input throws(RFC_3986.URI.Routing.Error) in
                try parser.serialize(output, into: &input)
            }
        }

        /// Couples body bytes and their realized media type in both directions.
        public init<C: RFC_9110.Body.Coder.`Protocol` & Copyable>(
            coding coder: C,
            maxSize: Measurement<UnitInformationStorage> = RFC_7230.Body.Parser<
                URLRouting.Rest<Foundation.Data>
            >.defaultMaxSize
        ) where C.Output == Output {
            let maxBytes = Int(maxSize.converted(to: .bytes).value)

            self._parse = { input throws(RFC_3986.URI.Routing.Error) in
                guard let body = input.body else {
                    throw RFC_3986.URI.Routing.Error(component: .body, failure: .missing)
                }
                guard body.count <= maxBytes else {
                    let actual = Measurement(
                        value: Double(body.count),
                        unit: UnitInformationStorage.bytes
                    )
                    throw RFC_3986.URI.Routing.Error(
                        component: .body,
                        failure: .invalid(
                            "Body size \(actual.shortDescription) exceeds maximum allowed size of \(maxSize.shortDescription)"
                        )
                    )
                }
                guard
                    let wrapped = input.headers["Content-Type"]?.first,
                    let value = wrapped
                else {
                    throw RFC_3986.URI.Routing.Error(
                        component: .header(name: "Content-Type"),
                        failure: .missing
                    )
                }

                let contentType: RFC_2045.ContentType
                do {
                    contentType = try RFC_2045.ContentType(String(value))
                } catch {
                    throw RFC_3986.URI.Routing.Error(
                        component: .header(name: "Content-Type"),
                        failure: .invalid("\(error)")
                    )
                }
                let mediaType = RFC_9110.MediaType(contentType)
                guard coder.accepts(mediaType) else {
                    throw RFC_3986.URI.Routing.Error(
                        component: .header(name: "Content-Type"),
                        failure: .mismatch(
                            expected: C.contentType.description,
                            actual: mediaType.description
                        )
                    )
                }

                var bytes = body.map(Byte.init)
                let output: Output
                do {
                    output = try coder.decode(&bytes, as: mediaType)
                } catch {
                    throw RFC_3986.URI.Routing.Error(
                        component: .body,
                        failure: .parseFailed("\(error)")
                    )
                }

                input.body = Foundation.Data(bytes.map(\.underlying))
                input.headers["Content-Type"]?.removeFirst()
                if input.headers["Content-Type"]?.isEmpty ?? true {
                    input.headers["Content-Type"] = nil
                }
                return output
            }

            self._serialize = { output, input throws(RFC_3986.URI.Routing.Error) in
                var bytes: [Byte] = []
                let mediaType: RFC_9110.MediaType
                do {
                    mediaType = try coder.encode(output, into: &bytes)
                } catch {
                    throw RFC_3986.URI.Routing.Error(
                        component: .body,
                        failure: .parseFailed("\(error)")
                    )
                }

                guard
                    mediaType.type == C.contentType.type,
                    mediaType.subtype == C.contentType.subtype
                else {
                    throw RFC_3986.URI.Routing.Error(
                        component: .header(name: "Content-Type"),
                        failure: .mismatch(
                            expected: C.contentType.description,
                            actual: mediaType.description
                        )
                    )
                }

                let contentType: RFC_2045.ContentType
                do {
                    contentType = try RFC_2045.ContentType(mediaType)
                } catch {
                    throw RFC_3986.URI.Routing.Error(
                        component: .header(name: "Content-Type"),
                        failure: .invalid("\(error)")
                    )
                }

                input.body = Foundation.Data(bytes.map(\.underlying))
                input.headers["Content-Type"] = [Optional(contentType.rawValue[...])][...]
            }
        }

    }
}

extension URLRouting.Body: Parser.Bidirectional {
    public typealias Input = RFC_3986.URI.Request.Data
    public typealias Buffer = RFC_3986.URI.Request.Data
    public typealias Failure = RFC_3986.URI.Routing.Error
    public typealias Body = Never

    @inlinable
    public var body: Never {
        borrowing get {
            fatalError("leaf router — parse(_:) and serialize(_:into:) are implemented directly")
        }
    }

    @inlinable
    public func parse(
        _ input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) -> Output {
        try _parse(&input)
    }

    @inlinable
    public func serialize(
        _ output: Output,
        into input: inout RFC_3986.URI.Request.Data
    ) throws(RFC_3986.URI.Routing.Error) {
        try _serialize(output, &input)
    }
}
