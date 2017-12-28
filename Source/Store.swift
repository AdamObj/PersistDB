import Foundation
import ReactiveSwift
import Result
import Schemata

/// An error that occurred while opening an on-disk `Store`.
public enum OpenError: Error {
    /// The schema of the on-disk database is incompatible with the schema of the store.
    case incompatibleSchema
    /// An unknown error occurred. An unfortunate reality.
    case unknown(AnyError)
}

/// A store of model objects, either in memory or on disk, that can be modified, queried, and
/// observed.
public final class Store {
    /// The underlying SQL database.
    fileprivate let db: Database
    
    /// A pipe of the actions that are mutating the store.
    ///
    /// Used to determine when observed queries must be refetched.
    fileprivate let actions = Signal<SQL.Action, NoError>.pipe()
    
    /// The designated initializer.
    ///
    /// - parameters:
    ///   - db: An opened SQL database that backs the store.
    ///   - schemas: The schemas of the models in the store.
    ///
    /// - throws: An `OpenError` if the store cannot be created from the given database.
    ///
    /// As part of initialization, the store will verify the schema of and create tables in the
    /// database.
    private init(_ db: Database, for schemas: [AnySchema]) throws {
        self.db = db
        
        let existing = Dictionary(uniqueKeysWithValues: db
            .schema()
            .map { ($0.table, $0) }
        )
        for schema in schemas {
            let sql = schema.sql
            if let existing = existing[sql.table] {
                if existing != sql {
                    throw OpenError.incompatibleSchema
                }
            } else {
                db.create(sql)
            }
        }
        
        actions.output.observeValues(db.perform)
    }
    
    /// Create an in-memory store for the given schemas.
    public convenience init(for schemas: [AnySchema]) {
        try! self.init(Database(), for: schemas)
    }
    
    /// Create an in-memory store for the given model types.
    public convenience init(for types: [Schemata.AnyModel.Type]) {
        self.init(for: types.map { $0.anySchema })
    }
    
    /// Open an on-disk store.
    ///
    /// - parameters:
    ///   - url: The file URL of the store to open.
    ///   - schemas: The schemas for the models in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// This will create a store at that URL if one doesn't already exist.
    public static func open(
        at url: URL,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        return SignalProducer<Store, OpenError> { observer, _ in
            do {
                let db = try Database(at: url)
                let store = try Store(db, for: schemas)
                observer.send(value: store)
                observer.sendCompleted()
            } catch let error as OpenError {
                observer.send(error: error)
            } catch let error {
                observer.send(error: OpenError.unknown(AnyError(error)))
            }
        }
    }
    
    /// Open an on-disk store.
    ///
    /// - parameters:
    ///   - url: The file URL of the store to open.
    ///   - types: The model types in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// This will create a store at that URL if one doesn't already exist.
    public static func open(
        at url: URL,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return open(at: url, for: types.map { $0.anySchema })
    }
    
    /// Open an on-disk store inside the Application Support directory.
    ///
    /// - parameters:
    ///   - fileName: The name of the file within the Application Support directory to use for the
    ///               store.
    ///   - schemas: The schemas for the models in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// This will create a store at that URL if one doesn't already exist.
    public static func open(
        libraryNamed fileName: String,
        for schemas: [AnySchema]
    ) -> SignalProducer<Store, OpenError> {
        return SignalProducer(value: fileName)
            .attemptMap { fileName in
                return try FileManager
                    .default
                    .url(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true
                    )
                    .appendingPathComponent(fileName)
            }
            .mapError(OpenError.unknown)
            .flatMap(.latest) { url in
                return self.open(at: url, for: schemas)
            }
    }
    
    /// Open an on-disk store inside the Application Support directory.
    ///
    /// - parameters:
    ///   - fileName: The name of the file within the Application Support directory to use for the
    ///               store.
    ///   - types: The model types in the store.
    ///
    /// - returns: A `SignalProducer` that will create and send a `Store` or send an `OpenError` if
    ///            one couldn't be opened.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    ///
    /// This will create a store at that URL if one doesn't already exist.
    public static func open(
        libraryNamed fileName: String,
        for types: [Schemata.AnyModel.Type]
    ) -> SignalProducer<Store, OpenError> {
        return open(libraryNamed: fileName, for: types.map { $0.anySchema })
    }
}

extension Store {
    /// Insert a model entity into the store.
    ///
    /// - important: This is done asynchronously.
    public func insert<Model>(_ insert: Insert<Model>) {
        actions.input.send(value: .insert(insert.sql))
    }
    
    /// Delete a model entity from the store.
    ///
    /// - important: This is done asynchronously.
    public func delete<Model>(_ delete: Delete<Model>) {
        actions.input.send(value: .delete(delete.sql))
    }
    
    /// Update properties for a model entity in the store.
    ///
    /// - important: This is done asynchronously.
    public func update<Model>(_ update: Update<Model>) {
        actions.input.send(value: .update(update.sql))
    }
}

extension Store {
    /// Fetch a projected query from the store.
    ///
    /// This method backs the public `fetch` and `observe` methods.
    ///
    /// - parameters:
    ///   - projected: The projected query to be fetched from the store.
    ///
    /// - returns: A `SignalProducer` that will fetch projections for entities that match the query.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    private func fetch<Projection>(
        _ projected: ProjectedQuery<Projection>
    ) -> SignalProducer<Projection, NoError> {
        return SignalProducer { [db = self.db] observer, _ in
            let values = db
                .query(projected.sql)
                .map(projected.values(for:))
                .flatMap(Projection.projection.makeValue)
            values.forEach(observer.send(value:))
            observer.sendCompleted()
        }
    }
    
    /// Fetch projections from the store with a query.
    ///
    /// - parameters:
    ///   - query: A query matching the model entities to be projected.
    ///
    /// - returns: A `SignalProducer` that will fetch projections for entities that match the query.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func fetch<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> SignalProducer<Projection, NoError> {
        let projected = ProjectedQuery<Projection>(query)
        return fetch(projected)
    }
    
    /// Observe projections from the store with a query.
    ///
    /// When `insert`, `delete`, or `update` is called that *might* affect the result, the
    /// projections will be re-fetched. But the projections will only be sent on the producer when
    /// they've changed.
    ///
    /// - parameters:
    ///   - query: A query matching the model entities to be projected.
    ///
    /// - returns: A `SignalProducer` that will send sets of projections for entities that match the
    ////           query, sending a new set whenever it's changed.
    ///
    /// - important: Nothing will be done until the returned producer is started.
    public func observe<Projection: ModelProjection>(
        _ query: Query<Projection.Model>
    ) -> SignalProducer<[Projection], NoError> {
        let projected = ProjectedQuery<Projection>(query)
        return fetch(projected)
            .collect()
            .concat(.never)
            .take(until: actions.output
                .filter(projected.sql.affected(by:))
                .map { _ in () }
            )
            .repeat(.max)
            .skipRepeats { $0 == $1 }
    }
}
