import RFC_3986

// MARK: - URLRouting Namespace

public enum URLRouting {}

// MARK: - Router Type Alias

extension URLRouting {
    public typealias Router<Output> = ParserPrinter<RFC_3986.URI.Request.Data, Output>
}
