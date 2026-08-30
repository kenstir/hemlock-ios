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

        let response = try await KohaClient.client.listLibraries(.init())

        // TODO: refactor me
        switch response {
        case .ok(let okResponse):
            switch okResponse.body {
            case .json(let x):
                print("json x:\(x)")
            }
        case .undocumented(statusCode: let statusCode, _):
            print(".undocumented statusCode:\(statusCode)")
        case .badRequest(let x):
            print(".badRequest x:\(x)")
        case .internalServerError(let x):
            print(".internalServerError x:\(x)")
        case .serviceUnavailable(let x):
            print(".serviceUnavailable x:\(x)")
        }

        let libraries = try response.ok.body.json
        print("\(libraries.count) libraries found")
        for library in libraries {
            print("library: \(library.libraryId) \(library.name)")
        }
        print("")

        // TODO: make mt-safe, remove await
        await MainActor.run {
            print("loadLibraries: main thread loading")
        }
    }

    func loadPlaceHoldPrerequisites() async throws {
        throw HemlockError.notImplemented
    }
}
