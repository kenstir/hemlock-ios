import Foundation
import OpenAPIRuntime

/// Create a usable Error from the one thrown by the generated client
enum ClientErrorMapper {

    static func map(_ error: Error) -> ServiceError {

        // Our error was already mapped.
        if let apiError = error as? ServiceError {
            return apiError
        }

        // Swift OpenAPI Generator runtime error.
        if let clientError = error as? ClientError {
            return map(clientError)
        }

        // A plain URLSession error.
        if let urlError = error as? URLError {
            return map(urlError, host: nil)
        }

        // A decoding error outside ClientError.
        if error is DecodingError {
            return .decodingFailed
        }

        return .unknown
    }

    private static func map(_ error: ClientError) -> ServiceError {

        let host = error.baseURL?.host

        // If an HTTP response was received, we know the connection
        // itself succeeded.
        if let response = error.response {

            let statusCode = response.status.code

            if !(200...299).contains(statusCode) {
                return .httpError(statusCode: statusCode)
            }
        }

        // This is the important part.
        //
        // ClientError exposes the actual error which caused the failure.
        let underlying = error.underlyingError

        if let urlError = findURLError(in: underlying) {
            return map(urlError, host: host)
        }

        if findDecodingError(in: underlying) {
            return .decodingFailed
        }

        return .unknown
    }

    private static func map(_ error: URLError, host: String?) -> ServiceError {

        switch error.code {

        case .notConnectedToInternet:
            return .noInternetConnection

        case .cannotConnectToHost,
             .cannotFindHost:
            return .cannotConnect(host: host)

        case .networkConnectionLost:
            return .connectionLost

        case .timedOut:
            return .timedOut

        case .cancelled:
            return .cancelled

        default:
            return .unknown
        }
    }
}

private func findURLError(
    in error: Error
) -> URLError? {

    if let urlError = error as? URLError {
        return urlError
    }

    let nsError = error as NSError

    // Sometimes the error itself is represented as NSError.
    if nsError.domain == NSURLErrorDomain,
       let code = URLError.Code(rawValue: nsError.code) {

        return URLError(
            code,
            userInfo: nsError.userInfo
        )
    }

    // Walk NSUnderlyingErrorKey recursively.
    if let underlying =
        nsError.userInfo[NSUnderlyingErrorKey] as? Error {

        return findURLError(in: underlying)
    }

    return nil
}

private func findDecodingError(
    in error: Error
) -> Bool {

    if error is DecodingError {
        return true
    }

    let nsError = error as NSError

    if let underlying =
        nsError.userInfo[NSUnderlyingErrorKey] as? Error {

        return findDecodingError(in: underlying)
    }

    return false
}
