// Repository Pattern - Protocol and Implementation in same file for testability

// MARK: - Protocol (Header)
protocol UserRepositoryProtocol {
    func fetchUser(id: String) async throws -> User
    func saveUser(_ user: User) async throws
}

// MARK: - Implementation
class UserRepository: UserRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchUser(id: String) async throws -> User {
        return try await apiClient.request(UserEndpoint.fetch(id: id))
    }

    func saveUser(_ user: User) async throws {
        try await apiClient.request(UserEndpoint.save(user: user))
    }
}

// MARK: - Usage in ViewModel
class ProfileViewModel: ObservableObject {
    @Published var data = ProfileData()

    private let userRepository: UserRepositoryProtocol

    // Dependency Injection - allows mock injection for testing
    init(userRepository: UserRepositoryProtocol = UserRepository()) {
        self.userRepository = userRepository
    }

    func loadUser() async {
        do {
            let user = try await userRepository.fetchUser(id: "123")
            data.userName = user.name
        } catch {
            data.errorMessage = StringManager.Profile.errorLoadFailed()
        }
    }
}
