import XCTest
@testable import Aftermath

class MutextDisposerTests: XCTestCase {

  var disposer: MutexDisposer!
  let token = "token"

  override func setUp() {
    super.setUp()
    disposer = TestDisposer()
  }

  // MARK: - Tests

  func testDisposeToken() {
    XCTAssertEqual(disposer.listeners.count, 0)
    disposer.listeners[token] = Listener(identifier: "id", callback: { _ in })
    XCTAssertEqual(disposer.listeners.count, 1)
    disposer.dispose(token: token)
    XCTAssertEqual(disposer.listeners.count, 0)
  }

  func testDisposeAll() {
    XCTAssertEqual(disposer.listeners.count, 0)
    disposer.listeners[token] = Listener(identifier: "id", callback: { _ in })
    XCTAssertEqual(disposer.listeners.count, 1)
    disposer.disposeAll()
    XCTAssertEqual(disposer.listeners.count, 0)
  }
}
