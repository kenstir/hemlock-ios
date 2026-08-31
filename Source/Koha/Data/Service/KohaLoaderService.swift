//
//  Copyright (c) 2026 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import Foundation
import OpenAPIRuntime
import os.log

class KohaLoaderService: LoaderService {
    func loadStartupPrerequisites(options: LoaderServiceOptions) async throws {
        let start = Date()

        // KohaClient init

        // async: everything else can be done in parallel
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await self.loadLibraries() }

            try await group.waitForAll()
        }

        os_log("startup.elapsed: %.3f", log: Gateway.log, type: .info, -start.timeIntervalSinceNow)
    }

    private func loadLibraries() async throws {

//        let response = try await KohaClient.client.listLibraries(.init())
//        switch response {
//        case .ok(let okResponse):
//            switch okResponse.body {
//            case .json(let x):
//                print("json x:\(x)")
//            }
//        case .undocumented(statusCode: let statusCode, _):
//            print(".undocumented statusCode:\(statusCode)")
//        case .badRequest(let x):
//            print(".badRequest x:\(x)")
//        case .internalServerError(let x):
//            print(".internalServerError x:\(x)")
//        case .serviceUnavailable(let x):
//            print(".serviceUnavailable x:\(x)")
//        }

        do {
            let response = try await KohaClient.client.listLibraries(.init())
            let libraries = try response.ok.body.json
            print("\(libraries.count) libraries found")
            for library in libraries {
                print("library: \(library.libraryId) \(library.name)")
            }
            print("")
        } catch {
            throw HemlockError.make(fromClientError: error)
        }

        // TODO: make mt-safe, remove await
        await MainActor.run {
            print("loadLibraries: main thread loading")
        }
    }

    func loadPlaceHoldPrerequisites() async throws {
        throw HemlockError.notImplemented
    }
}

func mapError(_ error: Error) -> HemlockError {
    if let clientError = error as? ClientError {

        if let response = clientError.response {
            os_log("error type:ClientError code:\(response.status.code) reason:\(response.status.reasonPhrase)")
            let code = response.status.code
            if code >= 500 {
                return .serverError(response.status.reasonPhrase)
            } else if code >= 400 && code < 500 {
                return .internalError(response.status.reasonPhrase)
            }
        }

        let underlying = clientError.underlyingError
        if underlying is DecodingError {
            os_log("error type:DecodingError desc:\(underlying.localizedDescription)")
            return .internalError("Error decoding response: \(underlying.localizedDescription)")
        }

        os_log("error type:ClientError desc:\(underlying.localizedDescription)")
        return .unexpectedNetworkResponse(underlying.localizedDescription)
    }

    os_log("error type:unknown desc:\(error.localizedDescription)")
    return .unexpectedNetworkResponse(error.localizedDescription)

}

extension HemlockError {
    public static func make(fromClientError error: Error) -> HemlockError {
        return mapError(error)
    }
}
