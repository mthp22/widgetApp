import Foundation

struct SharedStorageURLFactory {
    static func makeStorageURL(fileManager: FileManager = .default) -> URL {
        if let groupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: WhisperStorageConfiguration.appGroupIdentifier
        ) {
            return groupURL.appendingPathComponent(WhisperStorageConfiguration.fileName)
        }

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let directory = baseURL.appendingPathComponent("WhisperWidget", isDirectory: true)
        return directory.appendingPathComponent(WhisperStorageConfiguration.fileName)
    }
}

final class SharedFileMessageRepository: MessageRepository {
    private let fileManager: FileManager
    private let storageURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        fileManager: FileManager = .default,
        storageURL: URL = SharedStorageURLFactory.makeStorageURL()
    ) {
        self.fileManager = fileManager
        self.storageURL = storageURL

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
    }

    func fetchMessages() throws -> [Message] {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return []
        }

        let data = try Data(contentsOf: storageURL)
        guard !data.isEmpty else {
            return []
        }

        return try decoder.decode([Message].self, from: data)
    }

    func saveMessages(_ messages: [Message]) throws {
        let directory = storageURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let data = try encoder.encode(messages)
        try data.write(to: storageURL, options: [.atomic])
    }
}
