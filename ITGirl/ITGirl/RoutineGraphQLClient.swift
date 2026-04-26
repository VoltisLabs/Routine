import Foundation

/// Voltis Routine GraphQL API — `routine.voltislabs.uk/graphql`.
/// The client stays transport-only so the app can evolve with the real schema (likes, follows, feeds, etc.).
enum RoutineGraphQL {
    static let endpointURL = URL(string: "https://routine.voltislabs.uk/graphql")!
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

    /// Pushes a routine to Voltis after local publish/save. Tries a JSON payload first, then a JSON string, so either `publishRoutine(routine: JSON!)` or `itgirlSyncRoutine(routineJson: String!)` style backends can work without an app update.
    func syncRoutineForDiscover(_ routine: Routine) async throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(routine)

        let jsonObject = try JSONSerialization.jsonObject(with: data)
        do {
            return try await execute(
                query: """
                mutation ITGirlPublishRoutine($routine: JSON!) {
                  publishRoutine(routine: $routine)
                }
                """,
                variables: ["routine": jsonObject]
            )
        } catch {
            guard let voltis = error as? VoltisGraphQLError, case .graphQL = voltis else { throw error }
            let jsonString = String(data: data, encoding: .utf8) ?? "{}"
            return try await execute(
                query: """
                mutation ITGirlSyncRoutineString($routine: String!) {
                  itgirlSyncRoutine(routineJson: $routine)
                }
                """,
                variables: ["routine": jsonString]
            )
        }
    }

    func execute(query: String, variables: [String: Any]?) async throws -> String {
        var request = URLRequest(url: RoutineGraphQL.endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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
            return "GraphQL OK (\(http.statusCode)): \(dataField)"
        }

        return "HTTP \(http.statusCode), JSON keys: \(object?.keys.joined(separator: ", ") ?? "?")"
    }
}
