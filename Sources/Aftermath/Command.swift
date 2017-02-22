// MARK: - Commands

public protocol AnyCommand: Identifiable, ErrorEventBuilder {}

public protocol Command: AnyCommand {
  associatedtype Output
}

public extension Command {

  static func buildEvent(fromError error: Error) -> AnyEvent {
    return buildEvent(of: self, fromError: error)
  }

  fileprivate static func buildEvent<T: Command>(of type: T.Type, fromError error: Error) -> AnyEvent {
    return Event<T>.error(error)
  }
}

// MARK: - Command builder

public protocol CommandBuilder {

  func buildCommand() throws -> AnyCommand
}

// MARK: - Command producer

public protocol CommandProducer {}

public extension CommandProducer {

  func execute(command: AnyCommand) {
    Engine.shared.commandBus.execute(command: command)
  }

  func execute(builder: CommandBuilder) {
    Engine.shared.commandBus.execute(builder: builder)
  }

  func execute<T: Action>(action: T) {
    if !Engine.shared.commandBus.contains(handler: T.self) {
      Engine.shared.use(handler: action)
    }

    execute(command: action)
  }
}

public extension CommandProducer where Self: ReactionProducer {

  func execute<T: Command>(command: T, reaction: Reaction<T.Output>) {
    react(to: T.self, with: reaction)
    execute(command: command)
  }
}

// MARK: - Command handling

public protocol CommandHandler {
  associatedtype CommandType: Command

  func handle(command: CommandType) throws -> Event<CommandType>
}

public extension CommandHandler {

  func wait() {
    publish(event: Event.progress)
  }

  func publish(data output: CommandType.Output) {
    publish(event: Event.data(output))
  }

  func publish(error: Error) {
    publish(event: Event.error(error))
  }

  func publish(event: Event<CommandType>) {
    Engine.shared.eventBus.publish(event: event)
  }
}

// MARK: - Action

public protocol Action: Command, CommandHandler {
  associatedtype CommandType = Self
}

// MARK: - Command middleware

public typealias Execute = (AnyCommand) throws -> Void
public typealias ExecuteCombination = (@escaping Execute) throws -> Execute

public protocol CommandMiddleware {

  func intercept(command: AnyCommand, execute: Execute, next: Execute) throws
  func compose(execute: @escaping Execute) throws -> ExecuteCombination
}

public extension CommandMiddleware {

  func compose(execute: @escaping Execute) throws -> ExecuteCombination {
    return try Middleware(intercept: intercept).compose(execute: execute)
  }
}
