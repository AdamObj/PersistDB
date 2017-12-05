import Foundation
import Schemata

/// A logical condition used for filtering.
public struct Predicate<Model: PersistDB.Model> {
    internal let sql: SQL.Expression
    
    fileprivate init(_ sql: SQL.Expression) {
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

extension PartialKeyPath where Root: PersistDB.Model {
    var sql: SQL.Expression {
        func column(for property: AnyProperty) -> SQL.Column {
            return SQL.Table(String(describing: property.model))[property.path]
        }
        
        let properties = Root.schema.properties(for: self)
        var value: SQL.Expression = .column(column(for: properties.last!))
        for property in properties.reversed().dropFirst() {
            switch property.type {
            case .toMany:
                fatalError()
            case let .toOne(model):
                let rhs = SQL.Column(
                    table: SQL.Table(String(describing: model)),
                    name: "id"
                )
                value = .join(column(for: property), rhs, value)
            case .value:
                fatalError()
            }
        }
        return value
    }
}

extension ModelValue {
    fileprivate var sql: SQL.Expression {
        return .value(Self.anyValue.encode(self).sql)
    }
}

extension Optional where Wrapped: ModelValue {
    fileprivate var sql: SQL.Expression {
        return .value(map(Wrapped.anyValue.encode)?.sql ?? .null)
    }
}

/// Test that a property of the model matches a value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql == rhs.sql)
}

/// Test that a property of the model matches an optional value.
public func ==<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql == rhs.sql)
}

/// Test that an expression matches a value.
public func ==<Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql == rhs.sql)
}

/// Test that an expression matches an optional value.
public func ==<Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql == rhs.sql)
}

/// Test that a property of the model doesn't match a value.
public func !=<Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql != rhs.sql)
}

/// Test that a property of the model doesn't match an optional value.
public func !=<Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql != rhs.sql)
}

/// Test that an expression doesn't matc a value.
public func !=<Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql != rhs.sql)
}

/// Test that an expression doesn't match an optional value.
public func !=<Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql != rhs.sql)
}

/// Test that a property of the model is less than a value.
public func < <Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql < rhs.sql)
}

/// Test that a property of the model is less than an optional value.
public func < <Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql < rhs.sql)
}

/// Test that an expression is less than a value.
public func < <Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql < rhs.sql)
}

/// Test that an expression is less than an optional value.
public func < <Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql < rhs.sql)
}

/// Test that a property of the model is greater than a value.
public func > <Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql > rhs.sql)
}

/// Test that a property of the model is greater than an optional value.
public func > <Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql > rhs.sql)
}

/// Test that an expression is greater than a value.
public func > <Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql > rhs.sql)
}

/// Test that an expression is greater than an optional value.
public func > <Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql > rhs.sql)
}

/// Test that a property of the model is less than or equal to a value.
public func <= <Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql <= rhs.sql)
}

/// Test that a property of the model is less than or equal to an optional value.
public func <= <Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql <= rhs.sql)
}

/// Test that an expression is less than or equal to a value.
public func <= <Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql <= rhs.sql)
}

/// Test that an expression is less than or equal to an optional value.
public func <= <Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql <= rhs.sql)
}

/// Test that a property of the model is greater than or equal to a value.
public func >= <Model, Value: ModelValue>(lhs: KeyPath<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql >= rhs.sql)
}

/// Test that a property of the model is greater than or equal to an optional value.
public func >= <Model, Value: ModelValue>(lhs: KeyPath<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql >= rhs.sql)
}

/// Test that an expression is greater than or equal to a value.
public func >= <Model, Value: ModelValue>(lhs: Expression<Model, Value>, rhs: Value) -> Predicate<Model> {
    return Predicate(lhs.sql >= rhs.sql)
}

/// Test that an expression is greater than or equal to an optional value.
public func >= <Model, Value: ModelValue>(lhs: Expression<Model, Value?>, rhs: Value?) -> Predicate<Model> {
    return Predicate(lhs.sql >= rhs.sql)
}

extension Predicate {
    /// Creates a predicate that's true when both predicates are true.
    public static func &&(lhs: Predicate, rhs: Predicate) -> Predicate {
        return Predicate(lhs.sql && rhs.sql)
    }
    
    /// Creates a predicate that's true when either predicates is true.
    public static func ||(lhs: Predicate, rhs: Predicate) -> Predicate {
        return Predicate(lhs.sql || rhs.sql)
    }
    
    /// Creates a predicate that's true when the given predicate is false.
    public static prefix func !(predicate: Predicate) -> Predicate {
        return Predicate(!predicate.sql)
    }
}
