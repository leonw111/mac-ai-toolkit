//
//  LoggingMiddleware.swift
//  mac-ai-toolkit
//
//  Request/Response logging middleware
//

import Foundation
import Vapor

struct LoggingMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let startTime = Date()

        // Log request
        request.logger.info("[\(request.method)] \(request.url.path)")

        do {
            let response = try await next.respond(to: request)

            // Log response
            let duration = Date().timeIntervalSince(startTime) * 1000
            request.logger.info("[\(response.status.code)] \(request.url.path) - \(String(format: "%.2f", duration))ms")

            return response
        } catch {
            // Log error
            let duration = Date().timeIntervalSince(startTime) * 1000
            request.logger.error("[\(request.method)] \(request.url.path) - Error: \(error.localizedDescription) - \(String(format: "%.2f", duration))ms")

            throw error
        }
    }
}
