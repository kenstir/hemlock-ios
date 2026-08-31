//
//  HemlockError.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

public enum HemlockError: Error {
    case unexpectedNetworkResponse(String)
    case serverError(String)
    case internalError(String)
    case shouldNotHappen(String)
    case sessionExpired
    case notImplemented
}

extension HemlockError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedNetworkResponse(let reason):
            return "Unexpected network response: \(reason)"
        case .serverError(let reason):
            return "Internal Server Error: \(reason)"
        case .internalError(let reason):
            return "Internal Error: \(reason)"
        case .shouldNotHappen(let reason):
            return reason
        case .sessionExpired:
            return "Session expired"
        case .notImplemented:
            return "Not implemented yet"
        }
    }
}

func isSessionExpired(error: Error) -> Bool {
    if let gatewayError = error as? GatewayError {
        switch gatewayError {
        case .event(let ilsevent, let textcode, _, _):
            return ((ilsevent as? Int) == 1001 || (textcode == "NO_SESSION"))
        default:
            return false
        }
    } else if let err = error as? HemlockError {
        switch err {
        case .sessionExpired:
            return true
        default:
            return false
        }
    }
    return false
}

// TODO: merge ServiceError into HemlockError
enum ServiceError: LocalizedError, Sendable {
    case noInternetConnection
    case cannotConnect(host: String?)
    case connectionLost
    case timedOut
    case cancelled
    case invalidResponse
    case decodingFailed
    case httpError(statusCode: Int)
    case unknown

    var errorDescription: String? {
        switch self {

        case .noInternetConnection:
            return "No internet connection is available."

        case .cannotConnect(let host):
            if let host {
                return "Can't connect to \(host)."
            } else {
                return "Can't connect to the server."
            }

        case .connectionLost:
            return "The connection to the server was lost. Please try again."

        case .timedOut:
            return "The server took too long to respond. Please try again."

        case .cancelled:
            return "The request was cancelled."

        case .invalidResponse:
            return "The server returned an invalid response."

        case .decodingFailed:
            return "The server returned data that could not be understood."

        case .httpError(let statusCode):
            return "The server returned an error (\(statusCode))."

        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
