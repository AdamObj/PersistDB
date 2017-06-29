import Foundation
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: Schemata.Model> {
    /// Test whether the predicate evaluates to true for the given model.
    public let evaluate: (Model) -> Bool
    
    internal let sql: SQL.Expression
    
    fileprivate init(
        evaluate: @escaping (Model) -> Bool,
        sql: SQL.Expression
    ) {
        self.evaluate = evaluate
        self.sql = sql
    }
}

extension Predicate: Hashable {
    public var hashValue: Int {
        return sql.hashValue
    }
    
    public static func == (lhs: Predicate, rhs: Predicate) -> Bool {
        return lhs.sql == rhs.sql
    }
}

/// Test whether a property of the model matches a value.
public func ==<Model>(lhs: KeyPath<Model, String>, rhs: String) -> Predicate<Model> {
    let sql = Model.schema
        .properties(for: lhs)
        .map { property -> SQL.Expression in
            let lhsTable = SQL.Table(String(describing: property.model))
            switch property.type {
            case .toMany:
                fatalError()
            case let .toOne(model):
                return lhsTable[property.path] == SQL.Table(String(describing: model))["id"]
            case .value:
                return lhsTable[property.path] == rhs
            }
        }
        .reduce(nil) { result, expression -> SQL.Expression in
            return result.map { $0 && expression } ?? expression
        }!
    
    return Predicate<Model>(
        evaluate: { $0[keyPath: lhs] == rhs },
        sql: sql
    )
}

extension Predicate {
    /// Creates a predicate that's true when both predicates are true.
    public static func &&(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    /// Creates a predicate that's true when either predicates is true.
    public static func ||(lhs: Predicate, rhs: Predicate) -> Predicate {
        fatalError()
    }
    
    /// Creates a predicate that's true when the given predicate is false.
    public static prefix func !(predicate: Predicate) -> Predicate {
        fatalError()
    }
}
