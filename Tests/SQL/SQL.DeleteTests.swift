@testable import PersistDB
import XCTest

class SQLDeleteTests: XCTestCase {
    var db: TestDB!
    
    override func setUp() {
        super.setUp()
        db = TestDB()
    }
    
    override func tearDown() {
        super.tearDown()
        db = nil
    }
    
    func testWithPredicate() {
        let table = Author.table
        let predicate = SQL.Expression.binary(
            .equal,
            .column(table["name"]),
            .value(.text(Author.jrrTolkien.name))
        )
        let delete = SQL.Delete(
            table: table,
            predicate: predicate
        )
        
        db.delete(delete)
        
        let query = SQL.Query.select([ .wildcard(table) ])
        XCTAssertEqual(
            Set(db.query(query)),
            [
                Author.orsonScottCard.row,
            ]
        )
    }
    
    func testWithoutPredicate() {
        let table = Author.table
        let delete = SQL.Delete(
            table: table,
            predicate: nil
        )
        
        db.delete(delete)
        
        let query = SQL.Query.select([ .wildcard(table) ])
        XCTAssertEqual(
            Set(db.query(query)),
            []
        )
    }
}

