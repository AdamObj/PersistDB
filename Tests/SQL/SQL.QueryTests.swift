@testable import PersistDB
import XCTest

class SQLQueryTests: XCTestCase {
    var db: TestDB!
    
    override func setUp() {
        super.setUp()
        db = TestDB()
    }
    
    override func tearDown() {
        super.tearDown()
        db = nil
    }
    
    // MARK: - Equality
    
    func testNotEqualWithDifferentResults() {
        XCTAssertNotEqual(
            SQL.Query.select([ SQL.Result(Book.Table.title) ]),
            SQL.Query.select([ SQL.Result(Book.Table.author) ])
        )
    }
    
    func testNotEqualWithDifferentPredicates() {
        let query = SQL.Query.select(Book.Table.allColumns)
        XCTAssertNotEqual(
            query.where(Book.Table.author == .value(.integer(Author.ID.jrrTolkien.int))),
            query.where(Book.Table.author == .value(.integer(Author.ID.orsonScottCard.int)))
        )
    }
    
    func testNotEqualWithDifferentOrder() {
        let query = SQL.Query.select(Book.Table.allColumns)
        XCTAssertNotEqual(
            query.sorted(by: Book.Table.author.ascending),
            query.sorted(by: Book.Table.author.descending)
        )
    }
    
    // MARK: - Select
    
    func testSelectingAWildcard() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.Data.byJRRTolkien + Book.Data.byOrsonScottCard)
        )
    }
    
    func testSelectingOneExpression() {
        let query = SQL.Query
            .select([ SQL.Result(Author.Table.id)  ])
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row(["id": .integer(Author.ID.orsonScottCard.int)]),
                Row(["id": .integer(Author.ID.jrrTolkien.int)]),
            ])
        )
    }
    
    func testSelectingMultipleExpressions() {
        let query = SQL.Query
            .select([
                SQL.Result(Author.Table.id),
                SQL.Result(Author.Table.name),
            ])
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row([
                    "id": .integer(Author.ID.orsonScottCard.int),
                    "name": .text("Orson Scott Card"),
                ]),
                Row([
                    "id": .integer(Author.ID.jrrTolkien.int),
                    "name": .text("J.R.R. Tolkien"),
                ]),
            ])
        )
    }
    
    func testSelectingWithAlias() {
        let query = SQL.Query.select([ SQL.Result(Author.Table.name).as("foo") ])
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Row([ "foo": .text("Orson Scott Card") ]),
                Row([ "foo": .text("J.R.R. Tolkien") ]),
            ])
        )
    }
    
    // MARK: - Generic Operators
    
    func testEqual() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(Book.Table.author == Author.Table.id)
            .where(Author.Table.id == .value(.integer(Author.ID.jrrTolkien.int)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.Data.byJRRTolkien)
        )
    }
    
    func testEqualsNil() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(Author.Table.died == .value(.null))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    func testNilEquals() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.value(.null) == Author.Table.died)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    func testNotEqual() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(Book.Table.author == Author.Table.id)
            .where(Author.Table.id != .value(.integer(Author.ID.jrrTolkien.int)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.Data.byOrsonScottCard)
        )
    }
    
    func testDoesNotEqualNil() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(Author.Table.died != .value(.null))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.jrrTolkien.row])
        )
    }
    
    func testNilDoesNotEqual() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(.value(.null) != Author.Table.died)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.jrrTolkien.row])
        )
    }
    
    func testLessThan() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(Author.Table.born < .value(.integer(1951)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.jrrTolkien.row])
        )
    }
    
    func testGreaterThan() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(Author.Table.born > .value(.integer(1950)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    func testLessThanOrEqual() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(Author.Table.born <= .value(.integer(1892)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.jrrTolkien.row])
        )
    }
    
    func testGreaterThanOrEqual() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(Author.Table.born >= .value(.integer(1951)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    // MARK: - Bool Operators
    
    func testOr() {
        let title = Book.Table.title
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(title == .value(.text(Book.Data.endersGame.title)) || title == .value(.text(Book.Data.xenocide.title)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([
                Book.Data.endersGame.row,
                Book.Data.xenocide.row,
            ])
        )
    }
    
    func testNot() {
        let query = SQL.Query
            .select(Author.Table.allColumns)
            .where(!(Author.Table.name == .value(.text(Author.Data.jrrTolkien.name))))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([Author.Data.orsonScottCard.row])
        )
    }
    
    // MARK: - Aggregates
    
    func testMax() {
        let maximum = max(
            Author.Table.born,
            Author.Table.died
        )
        let query = SQL.Query
            .select([ SQL.Result(maximum) ])
            .where(Author.Table.id == .value(.integer(Author.ID.jrrTolkien.int)))
        
        let row: Row = [maximum.sql.debugDescription: .integer(Author.Data.jrrTolkien.died!)]
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([row])
        )
    }
    
    func testMin() {
        let maximum = min(
            Author.Table.born,
            Author.Table.died
        )
        let query = SQL.Query
            .select([ SQL.Result(maximum) ])
            .where(Author.Table.id == .value(.integer(Author.ID.jrrTolkien.int)))
        
        let row: Row = [maximum.sql.debugDescription: .integer(Author.Data.jrrTolkien.born)]
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set([row])
        )
    }
    
    // MARK: - Joins
    
    func testJoin() {
        let join = SQL.Expression.join(
            SQL.Column(table: Book.table, name: "author"),
            SQL.Column(table: Author.table, name: "id"),
            Author.Table.name == .value(.text(Author.Data.jrrTolkien.name))
        )
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(join)
    
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(Book.Data.byJRRTolkien)
        )
    }
    
    func testSortJoin() {
        let join = SQL.Expression.join(
            SQL.Column(table: Book.table, name: "author"),
            SQL.Column(table: Author.table, name: "id"),
            .column(SQL.Column(table: Author.table, name: "name"))
        )
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .sorted(by:
                join.ascending,
                Book.Table.title.ascending
            )
        
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.theHobbit.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.childrenOfTheMind.row,
                Book.Data.endersGame.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.xenocide.row,
            ]
        )
    }
    
    func testResultJoin() {
        let join = SQL.Expression.join(
            SQL.Column(table: Book.table, name: "author"),
            SQL.Column(table: Author.table, name: "id"),
            .column(SQL.Column(table: Author.table, name: "name"))
        )
        let query = SQL.Query
            .select([ SQL.Result(join).as("authorName") ])
            .where(Book.Table.title == .value(.text(Book.Data.theHobbit.title)))
        
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                ["authorName": .text(Author.Data.jrrTolkien.name)],
            ]
        )
    }
    
    // MARK: - Collections
    
    func testContains() {
        let books = [ Book.Data.theHobbit, Book.Data.xenocide ]
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(books.map { $0.title }.contains(Book.Table.title))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set(books.map { $0.row })
        )
    }
    
    // MARK: - where(_:)
    
    func testMultipleWhereMethods() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(Book.Table.author != .value(.integer(Author.ID.jrrTolkien.int)))
            .where(Book.Table.author != .value(.integer(Author.ID.orsonScottCard.int)))
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            Set(db.query(query)),
            Set()
        )
    }
    
    // MARK: - sorted(by:)
    
    func testSortedByAscending() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .sorted(by: Book.Table.title.ascending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.childrenOfTheMind.row,
                Book.Data.endersGame.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.theHobbit.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.xenocide.row,
            ]
        )
    }
    
    func testSortedByDescending() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .sorted(by: Book.Table.title.descending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.xenocide.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.theHobbit.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.endersGame.row,
                Book.Data.childrenOfTheMind.row,
            ]
        )
    }
    
    func testSortedByWithMultipleDescriptors() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(Book.Table.author == Author.Table.id)
            .sorted(by:
                Author.Table.name.ascending,
                Book.Table.title.ascending
            )
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.theHobbit.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.childrenOfTheMind.row,
                Book.Data.endersGame.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.xenocide.row,
            ]
        )
    }
    
    func testSortedByWithMultipleCalls() {
        let query = SQL.Query
            .select(Book.Table.allColumns)
            .where(Book.Table.author == Author.Table.id)
            .sorted(by: Book.Table.title.ascending)
            .sorted(by: Author.Table.name.ascending)
        XCTAssertEqual(query, query)
        XCTAssertEqual(
            db.query(query),
            [
                Book.Data.theHobbit.row,
                Book.Data.theLordOfTheRings.row,
                Book.Data.childrenOfTheMind.row,
                Book.Data.endersGame.row,
                Book.Data.speakerForTheDead.row,
                Book.Data.xenocide.row,
            ]
        )
    }
}

class SQLQueryAffectedByTests: XCTestCase {
    let query = SQL.Query
        .select([ .init(Author.Table.name, alias: "foo") ])
        .where(.binary(.isNot, Author.Table.died, .value(.null)))
        .sorted(by: SQL.Ordering(Author.Table.born, .ascending))
    
    let joined = SQL.Query
        .select([
            .init(.join(
                Book.table["author"],
                Author.table["id"],
                Author.Table.name
            ), alias: "foo")
        ])
        .where(.binary(
            .isNot,
            .join(Book.table["author"], Author.table["id"], Author.Table.died),
            .value(.null)
        ))
        .sorted(by: SQL.Ordering(
            .join(Book.table["author"], Author.table["id"], Author.Table.born),
            .ascending
        ))
    
    func testNotAffectedByInsertInAnotherTable() {
        let insert = SQL.Insert(
            table: Book.table,
            values: [
                "name": .value(.text("name")),
                "born": .value(.text("born")),
                "died": .value(.text("died")),
            ]
        )
        
        XCTAssertFalse(query.affected(by: .insert(insert)))
    }
    
    func testAffectedByInsert() {
        let insert = SQL.Insert(
            table: Author.table,
            values: [
                "name": .value(.text("name")),
                "born": .value(.text("born")),
                "died": .value(.text("died")),
            ]
        )
        
        XCTAssertTrue(query.affected(by: .insert(insert)))
    }
    
    func testAffectedByInsertedInJoinedQuery() {
        let insert = SQL.Insert(
            table: Author.table,
            values: [
                "name": .value(.text("name")),
                "born": .value(.text("born")),
                "died": .value(.text("died")),
            ]
        )
        
        XCTAssertTrue(joined.affected(by: .insert(insert)))
    }
    
    func testNotAffectedByDeleteInAnotherTable() {
        let delete = SQL.Delete(table: Book.table, predicate: nil)
        XCTAssertFalse(query.affected(by: .delete(delete)))
    }
    
    func testAffectedByDelete() {
        let delete = SQL.Delete(table: Author.table, predicate: nil)
        XCTAssertTrue(query.affected(by: .delete(delete)))
    }
    
    func testJoinedAffectedByDelete() {
        let delete = SQL.Delete(table: Author.table, predicate: nil)
        XCTAssertTrue(joined.affected(by: .delete(delete)))
    }
    
    func testNotAffectedByUpdateInAnotherTable() {
        let update = SQL.Update(
            table: Book.table,
            values: [
                "name": .value(.text("name"))
            ],
            predicate: nil
        )
        XCTAssertFalse(query.affected(by: .update(update)))
    }
    
    func testNotAffectedByUpdateToUnusedColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "givenName": .value(.text("givenName"))
            ],
            predicate: nil
        )
        XCTAssertFalse(query.affected(by: .update(update)))
    }
    
    func testNotAffectedByUpdateToUnusedJoinedColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "givenName": .value(.text("givenName"))
            ],
            predicate: nil
        )
        XCTAssertFalse(joined.affected(by: .update(update)))
    }
    
    func testAffectedByUpdateToSortColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "born": .value(.integer(1000))
            ],
            predicate: nil
        )
        XCTAssertTrue(query.affected(by: .update(update)))
    }
    
    func testAffectedByUpdateToJoinedSortColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "born": .value(.integer(1000))
            ],
            predicate: nil
        )
        XCTAssertTrue(joined.affected(by: .update(update)))
    }
    
    func testAffectedByUpdateToFilterColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "died": .value(.integer(1000))
            ],
            predicate: nil
        )
        XCTAssertTrue(query.affected(by: .update(update)))
    }
    
    func testAffectedByUpdateToJoinedFilterColumn() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "died": .value(.integer(1000))
            ],
            predicate: nil
        )
        XCTAssertTrue(joined.affected(by: .update(update)))
    }
    
    func testAffectedByUpdateToJoinedAliasedColumnResult() {
        let update = SQL.Update(
            table: Author.table,
            values: [
                "name": .value(.text("givenName"))
            ],
            predicate: nil
        )
        XCTAssertTrue(joined.affected(by: .update(update)))
    }
    
    func testAffectedByUpdateToDoubleJoinedAliasedColumnResult() {
        let publisher = SQL.Table("Publisher")
        let query = SQL.Query
            .select([.init(
                .join(
                    Book.table["author"],
                    Author.table["id"],
                    .join(
                        Author.table["publisher"],
                        publisher["id"],
                        .column(publisher["name"])
                    )
                ),
                alias: "foo"
            )])
        let update = SQL.Update(
            table: publisher,
            values: [
                "name": .value(.text("givenName"))
            ],
            predicate: nil
        )
        XCTAssertTrue(query.affected(by: .update(update)))
    }
}
