import XCTest
@testable import Aftermath

extension String: Identifiable {}

class IdentifiableTests: XCTestCase {

  // MARK: - Tests

  func testIdentifier() {
    XCTAssertEqual(String.identifier, String(reflecting: String.self))
    XCTAssertEqual(TestCommand.identifier, String(reflecting: TestCommand.self))
  }
}
