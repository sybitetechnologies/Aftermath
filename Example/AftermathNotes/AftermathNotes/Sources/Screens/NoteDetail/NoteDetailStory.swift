import Aftermath
import Malibu

struct NoteDetailStory {

  // MARK: - Command

  struct Command: Aftermath.Command {
    typealias Output = Note
    let id: Int
  }

  // MARK: - Command

  struct Request: GETRequestable {
    var message: Message

    init(command: Command) {
      message = Message(resource: "posts/\(command.id)")
    }
  }

  // MARK: - Command handler

  struct Handler: Aftermath.CommandHandler {

    func handle(command: Command) throws -> Event<Command> {
      // Make network request to fetch data.
      let request = Request(command: command)

      Malibu.networking("base").GET(request)
        .validate()
        .toJsonDictionary()
        .then({ try Note($0) })
        .done({ note in
          self.publish(data: note)
        })
        .fail({ error in
          self.publish(error: error)
        })

      return Event.progress
    }
  }
}
