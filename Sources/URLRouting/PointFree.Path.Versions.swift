//
//  PointFree.Path.Versions.swift
//  swift-url-routing
//
//  API-version path constants (.v1 … .v5) on the pointfree-compat Path
//  surface. Moved from swift-server-foundation (decomposition W3, C7).
//

extension Path<PathBuilder.Component<String>> {
    public static let v1 = Path {
        "v1"
    }

    public static let v2 = Path {
        "v2"
    }

    public static let v3 = Path {
        "v3"
    }

    public static let v4 = Path {
        "v4"
    }

    public static let v5 = Path {
        "v5"
    }
}
