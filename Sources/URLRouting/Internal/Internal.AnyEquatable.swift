@usableFromInline
enum Internal {}

extension Internal {
    @usableFromInline
    static func isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        func open<LHS>(_: LHS.Type) -> Bool? {
            (Box<LHS>.self as? AnyEquatable.Type)?.isEqual(lhs, rhs)
        }
        return _openExistential(type(of: lhs), do: open) ?? false
    }

    @usableFromInline
    enum Box<T> {}

    @usableFromInline
    protocol AnyEquatable {
        static func isEqual(_ lhs: Any, _ rhs: Any) -> Bool
    }
}

extension Internal.Box: Internal.AnyEquatable where T: Equatable {
    @usableFromInline
    static func isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        lhs as? T == rhs as? T
    }
}
