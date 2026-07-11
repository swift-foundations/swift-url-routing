//
//  PointFree.Rest.swift
//  swift-url-routing
//
//  Top-level `Rest()` authoring surface — the pointfree spelling for the
//  consumer-local ``URLRouting/Rest`` "consume the rest" bidirectional leaf.
//

/// A bidirectional parser-printer that consumes all remaining input on `parse`
/// and restores it on `print`.
///
/// Top-level pointfree-compatible alias for ``URLRouting/Rest``.
public typealias Rest = URLRouting.Rest
