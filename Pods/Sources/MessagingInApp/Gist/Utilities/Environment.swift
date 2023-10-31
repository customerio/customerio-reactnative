public enum GistEnvironment {
    case local
    case development
    case production
}

enum Settings {
    static var Environment: GistEnvironment = .production
    static var Network: NetworkSettings {
        switch Environment {
        case .development:
            return NetworkSettingsDevelopment()
        case .local:
            return NetworkSettingsLocal()
        case .production:
            return NetworkSettingsProduction()
        }
    }
}
