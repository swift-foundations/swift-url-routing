import Dependencies
import Logger_Dependencies
import Logging
import RFC_3986

extension Parser.Bidirectional where Input == RFC_3986.URI.Request.Data {
    /// Prints a route to an RFC 3986 path and query string.
    @inlinable
    public func urlPath(for route: Output) -> String {
        do {
            var data = RFC_3986.URI.Request.Data()
            try self.print(route, into: &data)
            var path = RFC_3986.URI.Request.Data()
            path.path = data.path
            path.query = data.query
            return try path.uri().value
        } catch {
            @Dependency(\.logger) var logger
            logger.error(
                """
                ---
                Could not generate a URL for route:

                  \(route)

                The router has not been configured to parse this output and so it cannot print it back \
                into a URL. A '#route-not-found' fragment has been printed instead.

                \(error)
                ---
                """
            )
            return "#route-not-found"
        }
    }
}
