import Foundation

class ElapsedTimer {
    private var title: String?
    private var startTime: CFAbsoluteTime?

    func start(title: String) {
        self.title = title
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func end() {
        guard let startTime = startTime, let title = title else {
            return
        }
        let timeElapsed = ((CFAbsoluteTimeGetCurrent() - startTime) * 1000).rounded() / 1000.0
        Logger.instance.info(message: "\(title) timer elapsed in \(timeElapsed) seconds")
        self.startTime = nil
    }
}
