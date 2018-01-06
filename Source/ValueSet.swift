import ReactiveSwift
import Schemata

/// An assignment of a value or expression to a model entity's property.
///
/// This is meant to be used in conjunction with `ValueSet`.
public struct Assignment<Model: PersistDB.Model> {
    internal let keyPath: PartialKeyPath<Model>
    internal let expression: AnyExpression
}

extension Assignment: Hashable {
    public var hashValue: Int {
        return keyPath.hashValue
    }
    
    public static func ==(lhs: Assignment, rhs: Assignment) -> Bool {
        return lhs.keyPath == rhs.keyPath && lhs.expression == rhs.expression
    }
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Value
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, expression: AnyExpression(rhs))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value?
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, expression: AnyExpression(rhs))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Value
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, expression: AnyExpression(rhs))
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value>,
    rhs: Expression<Model, Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, expression: rhs.expression)
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Expression<Model, Value?>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, expression: rhs.expression)
}

public func == <Model, Value: ModelValue>(
    lhs: KeyPath<Model, Value?>,
    rhs: Expression<Model, Value>
) -> Assignment<Model> {
    return Assignment<Model>(keyPath: lhs, expression: rhs.expression)
}

/// A set of values that can be used to insert or update a model entity.
public struct ValueSet<Model: PersistDB.Model> {
    /// The assignments/values that make up the value set.
    internal var values: [PartialKeyPath<Model>: AnyExpression]
    
    init(_ values: [PartialKeyPath<Model>: AnyExpression]) {
        self.values = values
    }
}

extension ValueSet {
    /// Create an empty value set.
    public init() {
        self.init([:])
    }
    
    /// Create a value set from a list of assignments.
    public init(_ assignments: [Assignment<Model>]) {
        self.init([:])
        for assignment in assignments {
            values[assignment.keyPath] = assignment.expression
        }
    }
}

extension ValueSet {
    /// Create a new value set by replacing values in `self` with the values from `valueSet`.
    public func update(with valueSet: ValueSet) -> ValueSet {
        return ValueSet(self.values.merging(valueSet.values) { $1 })
    }
}

extension ValueSet: Hashable {
    public var hashValue: Int {
        return values
            .map { $0.key.hashValue ^ $0.value.hashValue }
            .reduce(0, ^)
    }
    
    public static func ==(lhs: ValueSet, rhs: ValueSet) -> Bool {
        return lhs.values == rhs.values
    }
}

extension ValueSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Assignment<Model>...) {
        self.init(elements)
    }
}

extension ValueSet {
    /// Test whether the value set can be used for insertion.
    ///
    /// In order to be sufficient, every required property must have a value.
    internal var sufficientForInsert: Bool {
        let assigned = Set(values.keys)
        for property in Model.schema.properties.values {
            switch property.type {
            case .value(_, false), .toOne(_, false):
                guard assigned.contains(property.keyPath)
                    else { return false }
            case .value(_, true), .toOne(_, true), .toMany:
                break
            }
        }
        return true
    }
}
