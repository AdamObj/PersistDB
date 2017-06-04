import Foundation
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: RecordModel> {

}

extension Predicate: Hashable {
    public var hashValue: Int {
        return 0
    }
    
    public static func ==(lhs: Predicate, rhs: Predicate) -> Bool {
        return true
    }
}
