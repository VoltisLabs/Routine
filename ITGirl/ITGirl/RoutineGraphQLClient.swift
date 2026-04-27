import Foundation

/// Voltis Routine GraphQL API — `routine.voltislabs.uk/graphql`.
/// The client stays transport-only so the app can evolve with the real schema (likes, follows, feeds, etc.).
enum RoutineGraphQL {
    static var endpointURL: URL {
        if let raw = UserDefaults.standard.string(forKey: "itgirl.apiBaseURL"),
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let base = URL(string: raw),
           let resolved = URL(string: "graphql/", relativeTo: base)?.absoluteURL {
            return resolved
        }
#if DEBUG
        return URL(string: "http://127.0.0.1:8000/graphql/")!
#else
        return URL(string: "https://routine.voltislabs.uk/graphql/")!
#endif
    }
}

enum VoltisGraphQLError: LocalizedError {
    case invalidResponse
    case serverHTML(status: Int, snippet: String)
    case graphQL(String)
    case emptyBody

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unexpected response from the server."
        case let .serverHTML(status, snippet):
            return "Server returned HTML (status \(status)) instead of JSON. First bytes: \(snippet.prefix(200))…"
        case .graphQL(let message):
            return message
        case .emptyBody:
            return "Empty response body."
        }
    }
}

struct AuthSessionPayload: Codable, Sendable {
    let token: String
    let refreshToken: String
    let displayName: String
    let profilePhotoURL: String?
}

final class VoltisGraphQLClient: @unchecked Sendable {
    static let shared = VoltisGraphQLClient()

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    /// Minimal ping; useful to verify reachability while the backend schema stabilises.
    func ping() async throws -> String {
        try await execute(query: "{ __typename }", variables: nil)
    }

    func publishRoutine(_ routine: Routine, bearerToken: String?) async throws {
        _ = try await executeJSON(
            query: """
            mutation ITGirlPublishRoutine($routine: JSON!) {
              publishRoutine(routine: $routine)
            }
            """,
            variables: ["routine": try routineJSONObject(routine)],
            bearerToken: bearerToken
        )
    }

    func signIn(username: String, password: String) async throws -> AuthSessionPayload {
        let raw = try await executeJSON(
            query: """
            mutation ITGirlLogin($username: String!, $password: String!) {
              login(username: $username, password: $password) {
                success
                errors
                token
                refreshToken
                user {
                  displayName
                  username
                  profilePictureUrl
                }
              }
            }
            """,
            variables: ["username": username, "password": password]
        )

        guard let login = raw["login"] as? [String: Any] else {
            throw VoltisGraphQLError.graphQL("Login response missing payload.")
        }
        if let success = login["success"] as? Bool, success == false {
            let errorText = String(describing: login["errors"] ?? "Unknown auth error.")
            throw VoltisGraphQLError.graphQL(errorText)
        }
        guard let token = login["token"] as? String else {
            throw VoltisGraphQLError.graphQL("Sign-in response missing token.")
        }
        let user = login["user"] as? [String: Any]
        return AuthSessionPayload(
            token: token,
            refreshToken: (login["refreshToken"] as? String) ?? "",
            displayName: (user?["displayName"] as? String) ?? (user?["username"] as? String) ?? "",
            profilePhotoURL: user?["profilePictureUrl"] as? String
        )
    }

    func signUp(firstName: String, lastName: String, username: String, email: String, password: String) async throws -> AuthSessionPayload {
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)

        let raw = try await executeJSON(
            query: """
            mutation ITGirlRegister(
              $displayName: String!,
              $email: String!,
              $username: String!,
              $firstName: String!,
              $lastName: String!,
              $password1: String!,
              $password2: String!
            ) {
              register(
                displayName: $displayName,
                email: $email,
                username: $username,
                firstName: $firstName,
                lastName: $lastName,
                password1: $password1,
                password2: $password2
              ) {
                success
                errors
                token
                refreshToken
              }
            }
            """,
            variables: [
                "displayName": displayName,
                "email": email,
                "username": normalizedUsername,
                "firstName": first,
                "lastName": last,
                "password1": password,
                "password2": password
            ]
        )

        guard let register = raw["register"] as? [String: Any] else {
            throw VoltisGraphQLError.graphQL("Sign-up response missing payload.")
        }
        if let success = register["success"] as? Bool, success == false {
            let errorText = String(describing: register["errors"] ?? "Unknown registration error.")
            throw VoltisGraphQLError.graphQL(errorText)
        }
        guard let token = register["token"] as? String else {
            throw VoltisGraphQLError.graphQL("Sign-up response missing token.")
        }
        return AuthSessionPayload(
            token: token,
            refreshToken: (register["refreshToken"] as? String) ?? "",
            displayName: displayName,
            profilePhotoURL: nil
        )
    }

    func uploadProfilePhoto(_ imageData: Data, bearerToken: String?) async throws -> String {
        let base64 = imageData.base64EncodedString()
        let raw = try await executeJSON(
            query: """
            mutation ITGirlUploadProfilePhoto($imageBase64: String!) {
              uploadProfilePhoto(imageBase64: $imageBase64)
            }
            """,
            variables: ["imageBase64": base64],
            bearerToken: bearerToken
        )
        guard let url = raw["uploadProfilePhoto"] as? String else {
            throw VoltisGraphQLError.graphQL("Profile photo upload did not return a URL.")
        }
        return url
    }

    func createStripeCheckoutURL(for routine: Routine, bearerToken: String?) async throws -> URL {
        let raw = try await executeJSON(
            query: """
            mutation ITGirlCreateCheckoutSession($routineId: ID!, $unlockPriceCredits: Int!) {
              createCheckoutSession(routineId: $routineId, unlockPriceCredits: $unlockPriceCredits) {
                url
                checkoutUrl
                checkoutURL
              }
            }
            """,
            variables: [
            "routineId": routine.id.uuidString,
            "unlockPriceCredits": routine.effectiveUnlockPriceCredits
            ],
            bearerToken: bearerToken
        )
        if let url = Self.extractCheckoutURL(from: raw["createCheckoutSession"]) {
            return url
        }
        throw VoltisGraphQLError.graphQL("Checkout URL was missing from backend response.")
    }

    func refreshAuthToken(_ refreshToken: String) async throws -> String {
        let raw = try await executeJSON(
            query: """
            mutation ITGirlRefreshToken($refreshToken: String) {
              refreshToken(refreshToken: $refreshToken)
            }
            """,
            variables: ["refreshToken": refreshToken]
        )
        guard let token = raw["refreshToken"] as? String, !token.isEmpty else {
            throw VoltisGraphQLError.graphQL("Token refresh failed.")
        }
        return token
    }

    func execute(query: String, variables: [String: Any]?) async throws -> String {
        let dataField = try await executeJSON(query: query, variables: variables, bearerToken: nil)
        return "GraphQL OK: \(dataField)"
    }

    private func executeJSON(
        query: String,
        variables: [String: Any]?,
        bearerToken: String? = nil
    ) async throws -> [String: Any] {
        var request = URLRequest(url: RoutineGraphQL.endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: Any] = ["query": query]
        if let variables {
            body["variables"] = variables
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw VoltisGraphQLError.invalidResponse
        }

        let contentType = http.value(forHTTPHeaderField: "Content-Type") ?? ""
        if contentType.lowercased().contains("text/html") {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            throw VoltisGraphQLError.serverHTML(status: http.statusCode, snippet: snippet)
        }

        guard !data.isEmpty else {
            throw VoltisGraphQLError.emptyBody
        }

        let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

        if let errors = object?["errors"] as? [[String: Any]],
           let first = errors.first,
           let message = first["message"] as? String {
            throw VoltisGraphQLError.graphQL(message)
        }

        if let dataField = object?["data"] {
            return dataField as? [String: Any] ?? [:]
        }

        throw VoltisGraphQLError.invalidResponse
    }

    private func routineJSONObject(_ routine: Routine) throws -> Any {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(routine)
        return try JSONSerialization.jsonObject(with: data)
    }

    private static func extractCheckoutURL(from payload: Any?) -> URL? {
        if let urlString = payload as? String, let url = URL(string: urlString) {
            return url
        }
        if let object = payload as? [String: Any] {
            let candidates = [object["url"], object["checkoutUrl"], object["checkoutURL"]]
            for item in candidates {
                if let urlString = item as? String, let url = URL(string: urlString) {
                    return url
                }
            }
        }
        return nil
    }
}
