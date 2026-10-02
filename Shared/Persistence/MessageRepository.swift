import Foundation

/// Storage contract for the message library.
///
/// One implementation exists for the product (`SharedFileMessageRepository`);
/// tests provide their own in-memory implementation. Higher layers depend on
/// this protocol rather than on the concrete store (Dependency Inversion).
///
/// Implementations are synchronous by design: the store is a single small JSON
/// document written atomically, so it is cheaper to perform inline than to add
/// an actor hop between every mutation the user makes.
protocol MessageRepository {
    /// Loads every persisted message. Returns an empty array when the store
    /// does not exist yet. Throws when the stored data cannot be decoded.
    func fetchMessages() throws -> [Message]

    /// Replaces the whole message library with `messages`.
    func saveMessages(_ messages: [Message]) throws
}
