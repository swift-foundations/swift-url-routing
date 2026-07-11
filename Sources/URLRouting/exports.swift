// MARK: - Core Dependencies — institute L1 parser engine (narrow families)

@_exported import Parser_Primitive
@_exported import Parser_Take_Primitives
@_exported import Parser_Skip_Primitives
@_exported import Parser_Map_Primitives
@_exported import Parser_Conversion_Primitives
@_exported import Parser_Witness_Primitives
@_exported import Parser_Error_Primitives
@_exported import Parser_Always_Primitives
@_exported import Parser_End_Primitives
@_exported import Parser_Match_Primitives
@_exported import Parser_Conformance_Primitives
@_exported import Parser_OneOf_Primitives
@_exported import Parser_Rest_Primitives

// Substring / ArraySlice conformances to `Collection.Slice.Protocol` — required for
// `Parser.End` (and other engine parsers) over the URI request carrier's Substring
// path components. The narrow Parser products don't re-export this transitively.
@_exported import Collection_Slice_Primitives

// MARK: - Enum-case addressing (Case.Path + @Cases, via swift-dual)

@_exported import Dual

// MARK: - RFC Standards

@_exported import RFC_2045
@_exported import RFC_2046
@_exported import RFC_3986
@_exported import RFC_6265
@_exported import RFC_7230
@_exported import RFC_7231
@_exported import RFC_7578

// MARK: - WHATWG Standards

@_exported import WHATWG_HTML_Shared
// Note: WHATWG_HTML_Forms not exported to avoid ambiguity with URLFormCoding.Form
// Import WHATWG_HTML_Forms directly in files that need it

// MARK: - Form Coding

@_exported import URLFormCoding
@_exported import MultipartFormCoding
