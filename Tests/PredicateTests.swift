@testable import PersistDB
import XCTest

class PredicateTests: XCTestCase {
    // MARK: - sql
    
    func test_sql_equal_date() {
        let predicate = \Widget.date == Date(timeIntervalSinceReferenceDate: 100_000)
        let sql: SQL.Expression = SQL.Table("Widget")["date"] == .value(.real(100_000))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_toOne_optional_int() {
        let predicate = \Book.author.died == nil
        
        let author = SQL.Table("Author")
        let book = SQL.Table("Book")
        let sql: SQL.Expression = book["author"] == author["id"] && author["died"] == .value(.null)
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_optional_int() {
        let predicate = \Author.died == nil
        let sql: SQL.Expression = SQL.Table("Author")["died"] == .value(.null)
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_int() {
        let predicate = \Author.born == 1900
        let sql: SQL.Expression = SQL.Table("Author")["born"] == .value(.integer(1900))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_string() {
        let predicate = \Author.name == "J.K. Rowling"
        let sql: SQL.Expression = SQL.Table("Author")["name"] == .value(.text("J.K. Rowling"))
        XCTAssertEqual(predicate.sql, sql)
    }
    
    func test_sql_equal_toOne_string() {
        let predicate = \Book.author.name == "J.K. Rowling"
        
        let author = SQL.Table("Author")
        let book = SQL.Table("Book")
        let sql: SQL.Expression = book["author"] == author["id"] && author["name"] == .value(.text("J.K. Rowling"))
        XCTAssertEqual(predicate.sql, sql)
    }
}
