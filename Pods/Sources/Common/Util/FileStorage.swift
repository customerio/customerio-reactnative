import Foundation

public protocol FileStorage: AutoMockable {
    /// return `true` if the save was successful and no errors were caught/logged
    /// `fileId` - the file name. `nil` if
    func save(type: FileType, contents: Data, fileId: String?) -> Bool
    /// return `nil` if an error was caught and logged *or* if the file simply doesn't exist
    func get(type: FileType, fileId: String?) -> Data?
    func delete(type: FileType, fileId: String) -> Bool
}

public enum FileType {
    case queueInventory
    case queueTask

    func getDirectoryPath(directoryUrl: URL) -> URL {
        switch self {
        case .queueInventory:
            return directoryUrl
                .appendingPathComponent("queue", isDirectory: true)
        case .queueTask:
            return directoryUrl
                .appendingPathComponent("queue", isDirectory: true)
                .appendingPathComponent("tasks", isDirectory: true)
        }
    }

    var searchPath: FileManager.SearchPathDirectory {
        .applicationSupportDirectory
    }

    var fileName: String? {
        switch self {
        case .queueInventory: return "inventory.json"
        default: return nil
        }
    }

    var fileExtension: String {
        switch self {
        case .queueTask, .queueInventory: return ".json"
        }
    }
}

/*
 Save data to a file on the device file system.

 Responsibilities:
 * Be able to mock so we can use in unit tests without using the real file system
 * Be the 1 source of truth for where certain types of files are stored.
   Making code less prone to errors and typos for file paths.

 Way that files are stored in this class:
 ```
 FileManager.SearchPath
 \__ <site-id>/
      \__ queue/
           \__ inventory.json
               tasks/
                \__ <task-uuid>
          images/
           \__ ...
 ```

 Notice that we are using the <site id> as a way to isolate files from each other.
 The file tree remains the same for all site ids.
 */
// sourcery: InjectRegister = "FileStorage"
public class FileManagerFileStorage: FileStorage {
    private let fileManager = FileManager.default
    private let siteId: String
    private let logger: Logger

    init(sdkConfig: SdkConfig, logger: Logger) {
        self.siteId = sdkConfig.siteId
        self.logger = logger
    }

    public func save(type: FileType, contents: Data, fileId: String?) -> Bool {
        do {
            guard let saveLocationUrl = try getUrl(type: type, fileId: fileId) else { return false }

            try contents.write(to: saveLocationUrl)

            return true
        } catch {
            logger.error(error.localizedDescription)
            return false
        }
    }

    public func get(type: FileType, fileId: String?) -> Data? {
        do {
            guard let saveLocationUrl = try getUrl(type: type, fileId: fileId) else { return nil }

            return try? Data(contentsOf: saveLocationUrl)
        } catch {
            logger.error(error.localizedDescription)
            return nil
        }
    }

    public func delete(type: FileType, fileId: String) -> Bool {
        do {
            guard let urlFileToDelete = try getUrl(type: type, fileId: fileId) else { return false }

            try fileManager.removeItem(at: urlFileToDelete)

            return true
        } catch {
            logger.error(error.localizedDescription)
            return false
        }
    }

    func getUrl(type: FileType, fileId: String?) throws -> URL? {
        guard var fileName = type.fileName ?? fileId else { return nil } // let the type be first to define file name
        fileName = fileName.setLastCharacters(type.fileExtension) // make sure file has extension.

        var saveLocationUrl = try fileManager.url(
            for: type.searchPath,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        // put *all* files into our own "io.customer" directory to isolate files.
        saveLocationUrl = saveLocationUrl.appendingPathComponent("io.customer", isDirectory: true)
        // isolate all directories by their siteId, first
        saveLocationUrl = saveLocationUrl.appendingPathComponent(siteId, isDirectory: true)

        // get the path and create the directories in case they are not yet made
        saveLocationUrl = type.getDirectoryPath(directoryUrl: saveLocationUrl)
        try fileManager.createDirectory(at: saveLocationUrl, withIntermediateDirectories: true, attributes: nil)

        // add file name to the directory path created thus far
        saveLocationUrl = saveLocationUrl.appendingPathComponent(fileName, isDirectory: false)

        return saveLocationUrl
    }
}
