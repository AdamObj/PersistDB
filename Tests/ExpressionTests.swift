@testable import PersistDB
import XCTest

class ExpressionTests: XCTestCase {
    func test_initWithValue() {
        let expression = Expression<Book, String>("foo")
        let sql = SQL.Expression.value(.text("foo"))
        XCTAssertEqual(expression.sql, sql)
    }
    
    func test_initWithOptionalValue_some() {
        let expression = Expression<Book, String?>("foo")
        let sql = SQL.Expression.value(.text("foo"))
        XCTAssertEqual(expression.sql, sql)
    }
    
    func test_initWithOptionalValue_none() {
        let expression = Expression<Book, String?>(nil)
        let sql = SQL.Expression.value(.null)
        XCTAssertEqual(expression.sql, sql)
    }
}

class ExpressionDateTests: XCTestCase {
    func testNow() {
        let expr = Expression<Book, Date>.now
        let sql = SQL.Expression.function(.strftime, [
            .value(.text("%s")),
            .value(.text("now")),
        ])
        XCTAssertEqual(expr.sql, sql)
    }
}
