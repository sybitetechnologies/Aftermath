import XCTest
@testable import Aftermath

class EngineTests: XCTestCase {

  var engine: Engine!

  override func setUp() {
    super.setUp()
    engine = Engine()
  }

  // MARK: - Tests

  func testInit() {
    XCTAssertNil(engine.errorHandler)
  }

  func testPipeCommandsThrough() {
    XCTAssertTrue(engine.commandBus.middlewares.isEmpty)

    engine.pipeCommands(through: [
      LogCommandMiddleware(),
      AdditionCommandMiddleware(),
      AbortCommandMiddleware()]
    )

    XCTAssertEqual(engine.commandBus.middlewares.count, 3)
  }

  func testPipeEventsThrough() {
    XCTAssertTrue(engine.eventBus.middlewares.isEmpty)

    engine.pipeEvents(through: [
      LogEventMiddleware(),
      ErrorEventMiddleware(),
      AbortEventMiddleware()]
    )

    XCTAssertEqual(engine.eventBus.middlewares.count, 3)
  }

  func testUseHandler() {
    XCTAssertEqual((engine.commandBus as? CommandBus)?.listeners.count, 0)

    engine.use(handler: TestCommandHandler())
    XCTAssertEqual((engine.commandBus as? CommandBus)?.listeners.count, 1)
  }
}
