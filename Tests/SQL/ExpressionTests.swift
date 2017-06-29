@testable import PersistDB
import XCTest

class SQLExpressionTests: XCTestCase {
    func testEqualityColumn() {
        let table = SQL.Table("foo")
        let column: SQL.Expression<String> = table["bar"]
        XCTAssertEqual(column, table["bar"])
        XCTAssertNotEqual(column, table["boo"])
    }
}
