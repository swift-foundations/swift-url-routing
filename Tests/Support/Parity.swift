//
//  Parity.swift
//  swift-url-routing
//
//  Shared wire-shape parity helpers for the Batch-0 corpus
//  (url-routing-stack-migration-plan.md, Batch 0). The corpus captures what the
//  CURRENT stack emits — including header absences — so later batches can prove
//  byte-parity or enumerate ratified deltas.
//

public import Foundation
public import RFC_3986
public import URLRouting

/// Wire-shape parity corpus helpers.
public enum Parity {}

extension Parity {
    /// Normalizes randomized multipart boundary tokens (`----FormBoundary<UUID>`)
    /// so snapshots are deterministic where boundary injection is unavailable.
    /// Each normalization site is a Batch-2 `Boundary.random()` work item.
    public static func normalizeBoundary(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"----FormBoundary[0-9A-Fa-f\-]{36}"#,
            with: "----FormBoundary<NORMALIZED>",
            options: .regularExpression
        )
    }

    /// Canonical, order-preserving textual form of a printed request.
    ///
    /// Query order is significant; header order is as-stored (case-insensitive
    /// keys); a body renders as UTF-8 text when valid (boundary-normalized),
    /// else lowercase hex.
    public static func canonical(_ data: RFC_3986.URI.Request.Data) -> String {
        var lines: [String] = []
        lines.append("method: \(data.method.map { "\($0)" } ?? "<nil>")")
        lines.append("path: /" + data.path.map(String.init).joined(separator: "/"))
        for (key, values) in data.query.fields {
            for value in values {
                lines.append("query: \(key)=\(value.map(String.init) ?? "<nil>")")
            }
        }
        for (key, values) in data.headers.fields {
            for value in values {
                lines.append("header: \(key): \(value.map(String.init) ?? "<nil>")")
            }
        }
        if let body = data.body {
            if let text = String(data: body, encoding: .utf8) {
                lines.append("body(utf8): \(normalizeBoundary(text))")
            } else {
                lines.append("body(hex): \(body.map { String(format: "%02x", $0) }.joined())")
            }
        } else {
            lines.append("body: <nil>")
        }
        return lines.joined(separator: "\n")
    }

    /// Prints one route through a router and returns its canonical form.
    public static func canonical<Router: Parser.Bidirectional>(
        of route: Router.Output,
        via router: Router
    ) throws -> String
    where Router.Input == RFC_3986.URI.Request.Data {
        var data = RFC_3986.URI.Request.Data()
        try router.print(route, into: &data)
        return canonical(data)
    }

    /// Builds a corpus document from named routes: canonical print per route,
    /// separated by `== <name> ==` markers.
    public static func corpus<Router: Parser.Bidirectional>(
        of routes: [(name: String, route: Router.Output)],
        via router: Router
    ) throws -> String
    where Router.Input == RFC_3986.URI.Request.Data {
        var sections: [String] = []
        for (name, route) in routes {
            sections.append("== \(name) ==\n" + (try canonical(of: route, via: router)))
        }
        return sections.joined(separator: "\n\n") + "\n"
    }

    /// parse(print(route)) == route round-trip check.
    public static func roundTrips<Router: Parser.Bidirectional>(
        _ route: Router.Output,
        via router: Router
    ) throws -> Bool
    where Router.Input == RFC_3986.URI.Request.Data, Router.Output: Equatable {
        var data = RFC_3986.URI.Request.Data()
        try router.print(route, into: &data)
        let parsed = try router.parse(&data)
        return parsed == route
    }
}

// MARK: - Fixture compare-or-record

extension Parity {
    /// Outcome of a fixture comparison.
    public enum Fixture: Equatable {
        /// Fixture was absent and has been recorded (first Batch-0 run).
        case recorded
        /// Fixture matched byte-for-byte.
        case matched
        /// Fixture differs; payload is a unified summary of the differing lines.
        case mismatched(String)
    }

    /// Compares `corpus` against the committed fixture at `url`, recording it
    /// when absent (Batch-0 capture semantics).
    public static func fixture(
        _ corpus: String,
        at url: URL
    ) throws -> Fixture {
        let manager = FileManager.default
        guard manager.fileExists(atPath: url.path) else {
            try manager.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Foundation.Data(corpus.utf8).write(to: url)
            return .recorded
        }
        let existing = try String(contentsOf: url, encoding: .utf8)
        if existing == corpus { return .matched }
        let expectedLines = existing.split(separator: "\n", omittingEmptySubsequences: false)
        let actualLines = corpus.split(separator: "\n", omittingEmptySubsequences: false)
        var differences: [String] = []
        for index in 0..<max(expectedLines.count, actualLines.count) {
            let expected = index < expectedLines.count ? expectedLines[index] : "<absent>"
            let actual = index < actualLines.count ? actualLines[index] : "<absent>"
            if expected != actual {
                differences.append("line \(index + 1):\n  - \(expected)\n  + \(actual)")
            }
            if differences.count >= 40 {
                differences.append("… (further differences truncated)")
                break
            }
        }
        return .mismatched(differences.joined(separator: "\n"))
    }
}
