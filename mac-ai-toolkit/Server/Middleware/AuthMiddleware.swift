//
//  AuthMiddleware.swift
//  mac-ai-toolkit
//
//  API authentication middleware
//

import Foundation
import Vapor

struct AuthMiddleware: AsyncMiddleware {
    let authKey: String?

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Skip auth if no key is configured
        guard let expectedKey = authKey, !expectedKey.isEmpty else {
            return try await next.respond(to: request)
        }

        // Check for Authorization header
        guard let authHeader = request.headers.first(name: .authorization) else {
            throw Abort(.unauthorized, reason: "Missing Authorization header")
        }

        // Support both "Bearer <token>" and raw token
        let providedKey: String
        if authHeader.hasPrefix("Bearer ") {
            providedKey = String(authHeader.dropFirst(7))
        } else {
            providedKey = authHeader
        }

        // Validate key
        guard providedKey == expectedKey else {
            throw Abort(.unauthorized, reason: "Invalid API key")
        }

        return try await next.respond(to: request)
    }
}

// MARK: - Error Response

struct APIErrorResponse: Content {
    let error: APIError

    struct APIError: Content {
        let code: String
        let message: String
    }
}

extension Abort {
    static func apiError(code: String, message: String, status: HTTPResponseStatus = .badRequest) -> Abort {
        Abort(status, reason: message)
    }
}
