import Foundation

/// Errors surfaced by the on-disk message store. Every failure is explicit so
/// the UI can show a real error state instead of silently losing data.
enum MessageStoreError: LocalizedError {
    case readFailed(url: URL, underlying: Error)
    case decodeFailed(url: URL, underlying: Error)
    case encodeFailed(underlying: Error)
    case writeFailed(url: URL, underlying: Error)

    var errorDescription: String? {
        switch self {
        case let .readFailed(url, _):
            "Could not read the message library at \(url.lastPathComponent)."
        case .decodeFailed:
            "The stored message library could not be read. It may be damaged."
        case .encodeFailed:
            "The message library could not be encoded for storage."
        case .writeFailed:
            "The message library could not be written to storage."
        }
    }

    var underlyingDescription: String? {
        switch self {
        case let .readFailed(_, underlying),
             let .decodeFailed(_, underlying),
             let .encodeFailed(underlying),
             let .writeFailed(_, underlying):
            underlying.localizedDescription
        }
    }
}

/// Resolves the shared storage location used by both targets.
enum SharedStorageURLFactory {
    /// `true` when the App Group container is reachable, i.e. when the widget
    /// can actually read the messages written by the application.
    static func isUsingAppGroupContainer(fileManager: FileManager = .default) -> Bool {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: WhisperStorageConfiguration.appGroupIdentifier) != nil
    }

    /// The shared JSON file location.
    ///
    /// Preference order:
    /// 1. the App Group container (required for app ↔ widget sharing);
    /// 2. the target's own Application Support directory as a last resort, so
    ///    the app keeps working in environments without App Group entitlements.
    static func makeStorageURL(fileManager: FileManager = .default) -> URL {
        if let groupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: WhisperStorageConfiguration.appGroupIdentifier
        ) {
            return groupURL.appendingPathComponent(WhisperStorageConfiguration.fileName)
        }

        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let directory = baseURL.appendingPathComponent(
            WhisperStorageConfiguration.fallbackDirectoryName,
            isDirectory: true
        )
        return directory.appendingPathComponent(WhisperStorageConfiguration.fileName)
    }
}

/// JSON-file backed implementation of ``MessageRepository``.
///
/// The file lives in the App Group container so the widget extension reads the
/// exact data the application wrote. Writes are atomic to avoid a partially
/// written library if the process is interrupted.
struct SharedFileMessageRepository: MessageRepository {
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

    /// Location of the JSON file backing this repository.
    var location: URL { storageURL }

    func fetchMessages() throws -> [Message] {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return []
        }

        let data: Data
        do {
            data = try Data(contentsOf: storageURL)
        } catch {
            throw MessageStoreError.readFailed(url: storageURL, underlying: error)
        }

        guard !data.isEmpty else {
            return []
        }

        do {
            return try decoder.decode([Message].self, from: data)
        } catch {
            throw MessageStoreError.decodeFailed(url: storageURL, underlying: error)
        }
    }

    func saveMessages(_ messages: [Message]) throws {
        let directory = storageURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw MessageStoreError.writeFailed(url: storageURL, underlying: error)
        }

        let data: Data
        do {
            data = try encoder.encode(messages)
        } catch {
            throw MessageStoreError.encodeFailed(underlying: error)
        }

        do {
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            throw MessageStoreError.writeFailed(url: storageURL, underlying: error)
        }
    }
}
