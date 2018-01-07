import PersistDB
import XCTest

class TestStoreFetchTests: XCTestCase {
    func test() {
        let theHobbit = Book.ISBN("the-hobbit")
        let query = Book.all.filter(\Book.title == Book.Data.theHobbit.title)
        let store = TestStore(
            [
                .theHobbit: [
                    \Book.title == Book.Data.theHobbit.title,
                ],
                theHobbit: [
                    \Book.title == Book.Data.theHobbit.title,
                ],
                .theLordOfTheRings: [
                    \Book.title == Book.Data.theLordOfTheRings.title,
                ]
            ]
        )
        XCTAssertEqual(store.fetch(query), [.theHobbit, theHobbit])
    }
    
    func testImplicitlyNilColumn() {
        let query = Author.all.filter(\Author.died == nil)
        let store = TestStore(
            [ .jrrTolkien: [ \Author.name == Author.Data.jrrTolkien.name ]]
        )
        XCTAssertEqual(store.fetch(query), [.jrrTolkien])
    }
}
