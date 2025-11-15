// MARK: - Core Dependencies

@_exported import Parsing

// MARK: - RFC Standards

@_exported import RFC_2045
@_exported import RFC_3986
@_exported import RFC_6265
@_exported import RFC_7230
@_exported import RFC_7231

// MARK: - WHATWG Standards

@_exported import WHATWG_HTML_Shared
// Note: WHATWG_HTML_Forms not exported to avoid ambiguity with URLFormCoding.Form
// Import WHATWG_HTML_Forms directly in files that need it

// MARK: - Form Coding

@_exported import URLFormCoding
@_exported import MultipartFormCoding
