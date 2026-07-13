//
//  PointFree.Path.Constants.swift
//  swift-url-routing
//
//  Web-server path constants (well-known files, SEO/social assets, error
//  pages) on the pointfree-compat Path surface. Moved from
//  swift-server-foundation (decomposition W3, C7). The .well-known pair's
//  eventual RFC 8615 home stays an open ruling (plan register row 28).
//

extension Path<PathBuilder.Component<String>> {

    public static var well_known: Path<PathBuilder.Component<String>> {
        Path { ".well-known" }
    }

    public static var appleAppSiteAssociation: Path<PathBuilder.Component<String>> {
        Path { ".well-known/apple-app-site-association" }
    }

    public static var readmeMd: Path<PathBuilder.Component<String>> {
        Path { "README.md" }
    }

    public static var licenseTxt: Path<PathBuilder.Component<String>> {
        Path { "LICENSE.txt" }
    }

    public static var changelogMd: Path<PathBuilder.Component<String>> {
        Path { "CHANGELOG.md" }
    }

    // SEO and Social Media Integration Files
    public static var openSearchXml: Path<PathBuilder.Component<String>> {
        Path { "opensearch.xml" }
    }

    public static var rssXml: Path<PathBuilder.Component<String>> {
        Path { "rss.xml" }
    }

    public static var atomXml: Path<PathBuilder.Component<String>> {
        Path { "atom.xml" }
    }

    public static var faviconIco: Path<PathBuilder.Component<String>> {
        Path { "favicon.ico" }
    }

    public static var ogImage: Path<PathBuilder.Component<String>> {
        Path { "og-image.jpg" }
    }

    public static var robotsTxt: Path<PathBuilder.Component<String>> {
        Path { "robots.txt" }
    }

    public static var sitemapXml: Path<PathBuilder.Component<String>> {
        Path { "sitemap.xml" }
    }

    public static var documentation: Path<PathBuilder.Component<String>> {
        Path { "documentation" }
    }

    public static var assets: Path<PathBuilder.Component<String>> {
        Path { "assets" }
    }
    public static var css: Path<PathBuilder.Component<String>> {
        Path { "css" }
    }
    public static var scss: Path<PathBuilder.Component<String>> {
        Path { "scss" }
    }
    public static var bootstrap: Path<PathBuilder.Component<String>> {
        Path { "bootstrap" }
    }
    public static var js: Path<PathBuilder.Component<String>> {
        Path { "js" }
    }

    public static var file: Path<PathBuilder.Component<String>> {
        Path { "file" }
    }

    public static var favicon: Path<PathBuilder.Component<String>> {
        Path { "favicon" }
    }

    public static var logo: Path<PathBuilder.Component<String>> {
        Path { "logo" }
    }

    public static var image: Path<PathBuilder.Component<String>> {
        Path { "img" }
    }

    public static var img: Path<PathBuilder.Component<String>> { .image }

    public static var apple_developer_merchantid_domain_association:
        Path<PathBuilder.Component<String>>
    {
        Path { "apple-developer-merchantid-domain-association" }
    }

    public static var manifestJson: Path<PathBuilder.Component<String>> {
        Path { "manifest.json" }
    }

    public static var humansTxt: Path<PathBuilder.Component<String>> {
        Path { "humans.txt" }
    }

    public static var crossdomainXml: Path<PathBuilder.Component<String>> {
        Path { "crossdomain.xml" }
    }

    public static var api: Path<PathBuilder.Component<String>> {
        Path { "api" }
    }

    public static var graphql: Path<PathBuilder.Component<String>> {
        Path { "graphql" }
    }

    public static var opensearchXml: Path<PathBuilder.Component<String>> {
        Path { "opensearch.xml" }
    }

    public static var browserconfigXml: Path<PathBuilder.Component<String>> {
        Path { "browserconfig.xml" }
    }

    public static var siteVerification: Path<PathBuilder.Component<String>> {
        Path { "site-verification" }
    }

    public static var error404: Path<PathBuilder.Component<String>> {
        Path { "404" }
    }

    public static var error500: Path<PathBuilder.Component<String>> {
        Path { "500" }
    }
}
