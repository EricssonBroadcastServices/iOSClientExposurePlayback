import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safeIndex index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
