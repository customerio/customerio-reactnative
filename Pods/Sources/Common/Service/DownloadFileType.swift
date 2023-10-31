import Foundation

public enum DownloadFileType {
    case richPushImage

    func directoryToSaveFiles(fileManager: FileManager) -> URL {
        var baseDirectory: URL = fileManager.temporaryDirectory

        switch self {
        case .richPushImage: baseDirectory = fileManager.temporaryDirectory
        }

        return baseDirectory.appendingPathComponent("cio_sdk", isDirectory: true)
    }
}
