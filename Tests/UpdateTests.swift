@testable import PersistDB
import XCTest

class UpdateSQLTests: XCTestCase {
    func testSQLWithPredicate() {
        let predicate: Predicate = \Widget.id == 1
        let update = Update(
            predicate: predicate,
            valueSet: [
                \.date == .now,
                \.double == 4.7,
            ]
        )
        
        let sql = SQL.Update(
            table: SQL.Table("Widget"),
            values: [
                "date": Expression<Widget, Date>.now.sql,
                "double": .value(.real(4.7))
            ],
            predicate: predicate.sql
        )
        XCTAssertEqual(update.sql, sql)
    }
    
    func testSQLWithoutPredicate() {
        let update = Update(
            predicate: nil,
            valueSet: [
                \Widget.date == .now,
                \Widget.double == 4.7,
            ]
        )
        
        let sql = SQL.Update(
            table: SQL.Table("Widget"),
            values: [
                "date": Expression<Widget, Date>.now.sql,
                "double": .value(.real(4.7))
            ],
            predicate: nil
        )
        XCTAssertEqual(update.sql, sql)
        
    }
}
