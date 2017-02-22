import XCTest
@testable import Aftermath

class EventBusTests: XCTestCase {

  var eventBus: EventBus!
  var errorHandler: ErrorManager!
  var reaction: Reaction<Calculator>!
  var listener: ((Event<AdditionCommand>) -> Void)!
  var state: State?
  var lastError: Error?

  override func setUp() {
    super.setUp()

    eventBus = EventBus()
    errorHandler = ErrorManager()
    eventBus.errorHandler = errorHandler

    reaction = Reaction(
      wait: {
        self.state = .progress
      },
      consume: { result in
        self.state = .data
      },
      rescue: { error in
        self.state = .error
        self.lastError = error
      }
    )

    listener = { event in
      self.reaction.invoke(with: event)
    }

    state = nil
    lastError = nil
  }

  override func tearDown() {
    super.tearDown()
    eventBus.disposeAll()
  }

  // MARK: - Tests

  func testListenTo() {
    XCTAssertEqual(eventBus.listeners.count, 0)

    _ = eventBus.listen(to: AdditionCommand.self, listener: listener)
    XCTAssertEqual(eventBus.listeners.count, 1)

    _ =  eventBus.listen(to: AdditionCommand.self, listener: listener)
    XCTAssertEqual(eventBus.listeners.count, 2)
  }

  func testPublishEvent() {
    let token = eventBus.listen(to: AdditionCommand.self, listener: listener)
    XCTAssertEqual(eventBus.listeners[token]?.status, .pending)

    eventBus.publish(event: Event<AdditionCommand>.progress)
    XCTAssertEqual(eventBus.listeners[token]?.status, .issued)
    XCTAssertEqual(state, .progress)
  }

  func testPublishEventWithoutListeners() {
    let token = eventBus.listen(to: AdditionCommand.self, listener: listener)
    XCTAssertEqual(eventBus.listeners[token]?.status, .pending)

    eventBus.publish(event: Event<TestCommand>.progress)
    XCTAssertEqual(eventBus.listeners[token]?.status, .pending)
    XCTAssertNil(state)

    if let error = errorHandler.lastError as? Warning {
      switch error {
      case .noEventListeners(let event):
        XCTAssertTrue(event is Event<TestCommand>)
      default:
        XCTFail("Invalid error was thrown: \(error)")
      }
    } else {
      XCTFail("No event listeners warning was thrown")
    }
  }

  func testPublishEventWithMiddleware() {
    var executed = false
    let middleware = LogEventMiddleware { _ in
      executed = true
    }

    let token = eventBus.listen(to: AdditionCommand.self, listener: listener)
    XCTAssertEqual(eventBus.listeners[token]?.status, .pending)

    eventBus.middlewares.append(middleware)
    eventBus.publish(event: Event<AdditionCommand>.progress)

    XCTAssertEqual(eventBus.listeners[token]?.status, .issued)
    XCTAssertEqual(state, .progress)
    XCTAssertTrue(executed)
  }

  func testPerformEvent() {
    let token = eventBus.listen(to: AdditionCommand.self, listener: listener)
    XCTAssertEqual(eventBus.listeners[token]?.status, .pending)

    do {
      try eventBus.perform(event: Event<AdditionCommand>.progress)
      XCTAssertEqual(eventBus.listeners[token]?.status, .issued)
      XCTAssertEqual(state, .progress)
    } catch {
      XCTFail("Event bus perform failed with error: \(error)")
    }
  }

  func testPerformEventWithoutListeners() {
    let token = eventBus.listen(to: AdditionCommand.self, listener: listener)
    XCTAssertEqual(eventBus.listeners[token]?.status, .pending)

    do {
      try eventBus.perform(event: Event<TestCommand>.progress)
      XCTFail("Perform may fail with error")
    } catch {
      XCTAssertEqual(eventBus.listeners[token]?.status, .pending)
      XCTAssertNil(state)
      XCTAssertNil(errorHandler.lastError)

      if let error = error as? Warning {
        switch error {
        case .noEventListeners(let event):
          XCTAssertTrue(event is Event<TestCommand>)
        default:
          XCTFail("Invalid error was thrown: \(error)")
        }
      } else {
        XCTFail("Invalid error was thrown: \(error)")
      }
    }
  }

  func testHandleErrorOnEvent() {
    _ = eventBus.listen(to: AdditionCommand.self, listener: listener)
    _ = eventBus.handle(error: TestError.test, on: Event<AdditionCommand>.progress)
    XCTAssertEqual(state, .error)
    XCTAssertTrue(lastError is TestError)
  }

  func testHandleErrorOnEventWithFrameworkError() {
    _ =  eventBus.listen(to: AdditionCommand.self, listener: listener)
    eventBus.handle(error: Failure.invalidEventType, on: Event<AdditionCommand>.progress)
    XCTAssertNil(state)
    XCTAssertNil(lastError)
  }
}
