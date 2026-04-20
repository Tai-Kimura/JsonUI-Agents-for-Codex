// Swift ViewModel Pattern (SwiftUI)
class LoginViewModel: ObservableObject {
    @Published var data = LoginData()

    init() {
        // Wire up event handlers from data section
        data.onLoginTap = { [weak self] in self?.onLoginTap() }
        data.onRegisterTap = { [weak self] in self?.onRegisterTap() }
    }

    // Event handler implementations
    func onLoginTap() {
        guard validateInput() else { return }
        // TODO: Call login API
    }

    func onRegisterTap() {
        // TODO: Navigate to register
    }

    private func validateInput() -> Bool {
        if data.email.isEmpty {
            data.errorMessage = StringManager.Login.errorEmailRequired()
            return false
        }
        return true
    }
}
