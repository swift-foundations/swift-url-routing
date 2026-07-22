public import HTTP_Body
public import HTML_Form_Coder_Codable
public import typealias HTML_Standard.HTML

extension RFC_9110.Body.Coder.`Protocol` {
    /// Creates the canonical URL-encoded HTML form body coder.
    @inlinable
    public static func form<Value: Swift.Codable>(
        _ type: Value.Type,
        decoder: HTML.Form.Coder.Decoder = .init(),
        encoder: HTML.Form.Coder.Encoder = .init()
    ) -> Self where Self == HTML.Form.Coder.Value<Value> {
        .init(type, decoder: decoder, encoder: encoder)
    }
}
