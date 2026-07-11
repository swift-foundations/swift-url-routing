import RFC_3986
import RFC_7231

// MARK: - PointFree API Compatibility

/// Compatibility typealiases for PointFree's swift-url-routing API.
/// This allows code written for PointFree's API to work with the RFC-first fork.

extension URLRouting {
    /// Compatibility alias for PointFree's Route type
    public typealias Route = RFC_3986.URI.Route

    /// Compatibility alias for PointFree's Query parser
    public typealias Query = RFC_3986.URI.Query.Parser

    /// Compatibility alias for PointFree's Conversion protocol (institute L1 engine)
    public typealias Conversion = Parser.Conversion.`Protocol`
}

/// Compatibility alias for PointFree's PathBuilder type
public typealias PathBuilder = RFC_3986.URI.Path.Builder

/// Compatibility alias for PointFree's URLRequestData type
public typealias URLRequestData = RFC_3986.URI.Request.Data

// MARK: - Field Type Resolution

/// In PointFree's URLRouting, "Field" context-dependently refers to either:
/// - Query fields (`RFC_3986.URI.Query.Field`) in Query contexts
/// - Header field parsers (`RFC_7230.Header.Field.Parser`) in Header contexts
///
/// The RFC-first fork maintains separate namespaces. Use:
/// - `RFC_3986.URI.Query.Field` for query parameters
/// - `RFC_7230.Header.Field.Parser` for HTTP header parsers
/// - `RFC_7230.Header.Field` for actual header field structures (name + value)
/// - `RFC_7230.Header.Field.Name` for header field names
/// - `RFC_7230.Header.Field.Value` for validated header field values
///
/// For backwards compatibility in Header contexts, import both:
/// ```swift
/// import URLRouting
/// // In Headers { } blocks, Field resolves to RFC_7230.Header.Field.Parser
/// ```
///
/// Note: We cannot provide a single global `Field` typealias because it would
/// be ambiguous. The compiler resolves based on context.
public typealias Field = RFC_7230.Header.Field.Parser
