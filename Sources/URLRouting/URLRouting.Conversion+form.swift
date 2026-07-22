public import HTML_Form_Coder_Codable
public import typealias HTML_Standard.HTML

extension URLRouting.Conversion {
    public static func form<Value>(
        _ type: Value.Type,
        decoder: HTML.Form.Coder.Decoder = .init(),
        encoder: HTML.Form.Coder.Encoder = .init()
    ) -> Self where Self == HTML.Form.Coder.Conversion<Value> {
        .init(type, decoder: decoder, encoder: encoder)
    }
}
