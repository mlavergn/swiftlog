import XCTest
@testable import SwiftLog

class SwiftLogTests: XCTestCase {
    func testExample() {
		Log.configure(level: .ALL)
		Log.debug("hello")
        XCTAssertEqual("test", "test")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
