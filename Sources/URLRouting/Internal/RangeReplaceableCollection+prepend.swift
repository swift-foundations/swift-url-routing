// Restores the `prepend` affordance the former pointfree engine provided on
// `RangeReplaceableCollection`. The URI / header printers push printed components
// onto the front of the request carrier (`ArraySlice<Substring>` path segments and
// `ArraySlice<Substring?>` field values), so a mutating front-insert is required.

extension RangeReplaceableCollection {
    /// Inserts `element` at the front of the collection.
    @inlinable
    mutating func prepend(_ element: Element) {
        self.insert(element, at: self.startIndex)
    }

    /// Inserts the contents of `newElements` at the front of the collection.
    @inlinable
    mutating func prepend(contentsOf newElements: some Swift.Collection<Element>) {
        self.insert(contentsOf: newElements, at: self.startIndex)
    }
}
