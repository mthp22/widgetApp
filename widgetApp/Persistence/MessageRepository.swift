import Foundation

protocol MessageRepository {
    func fetchMessages() throws -> [Message]
    func saveMessages(_ messages: [Message]) throws
}
