//
//  HTTPClientError.swift
//  Sportcharts
//
//  Created by Pablo Dias on 28/03/26.
//

import Foundation

enum HTTPClientError: LocalizedError {
    case invalidURL
    case badStatusCode(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .badStatusCode(let code):
            return "Server returned status code \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

final class HTTPClient {

    static let shared = HTTPClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseURL = "https://api.openf1.org"

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetch<T: Decodable>(_ endpoint: some OpenF1Requestable) async throws -> T {
        guard let url = makeURL(for: endpoint) else {
            throw HTTPClientError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw HTTPClientError.badStatusCode(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HTTPClientError.decodingError(error)
        }
    }

    private func makeURL(for endpoint: some OpenF1Requestable) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.path = endpoint.path
        components?.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems
        return components?.url
    }
}
