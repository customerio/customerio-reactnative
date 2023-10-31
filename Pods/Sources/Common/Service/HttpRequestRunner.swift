import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 Exists to be able to mock http requests so we can test our HttpClient's response handling logic.
 */
protocol HttpRequestRunner: AutoMockable {
    func request(
        params: HttpRequestParams,
        session: URLSession,
        onComplete: @escaping (Data?, HTTPURLResponse?, Error?) -> Void
    )
    func downloadFile(url: URL, fileType: DownloadFileType, session: URLSession, onComplete: @escaping (URL?) -> Void)
}

// sourcery: InjectRegister = "HttpRequestRunner"
class UrlRequestHttpRequestRunner: HttpRequestRunner {
    /**
     Note: When mocking request, open JSON file, convert to `Data`.
     */
    func request(
        params: HttpRequestParams,
        session: URLSession,
        onComplete: @escaping (Data?, HTTPURLResponse?, Error?) -> Void
    ) {
        var request = URLRequest(url: params.url)
        request.httpMethod = params.method
        request.httpBody = params.body
        params.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        session.dataTask(with: request) { data, response, error in
            /*
             /// uncomment when running HTTP tests on local machine for debugging
             print("----------------- HTTP logs start -----------------")
             print("\(request.httpMethod) - \(request.url?.absoluteString)")
             print("Request body: \(request.httpBody?.string)")
             print(data?.string)
             print(error?.localizedDescription)
             print("----------------- HTTP logs end   -----------------")
             */
            onComplete(data, response as? HTTPURLResponse, error)
        }.resume()
    }

    public func downloadFile(
        url: URL,
        fileType: DownloadFileType,
        session: URLSession,
        onComplete: @escaping (URL?) -> Void
    ) {
        let directoryURL = fileType.directoryToSaveFiles(fileManager: FileManager.default)

        session.downloadTask(with: url) { tempLocation, response, _ in
            guard let tempLocation = tempLocation, let uniqueFileName = response?.suggestedFilename else {
                return onComplete(nil)
            }

            let destinationURL = directoryURL
                .appendingPathComponent(uniqueFileName)

            do {
                // confirm that directories all created because we may have created a new sub-directory
                try FileManager.default.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                try FileManager.default.moveItem(at: tempLocation, to: destinationURL)
            } catch {
                // XXX: log error when error handling for the customer enabled

                return onComplete(nil)
            }

            onComplete(destinationURL)
        }.resume()
    }
}
