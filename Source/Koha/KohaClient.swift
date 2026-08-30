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
import OpenAPIURLSession
import OSLog

class KohaClient {

    //MARK: - fields

    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "Koha")
    //private static let lock = NSRecursiveLock()

    static var serverURL = "http://localhost:8081/api/v1"
    static let username = "koha"
    static let password = "koha"

    static var client: Client {
        return makeClient()
    }

    init() {
    }

    static func basicAuth(username: String, password: String) -> String {
        let credentials = "\(username):\(password)"
        guard let data = credentials.data(using: .utf8) else { return "" }
        let base64 = data.base64EncodedString()
        return "Basic \(base64)"
    }

    static func makeClient() -> Client {
        let auth = basicAuth(username: username, password: password)
        let client = Client(
            serverURL: URL(string: serverURL)!,
            transport: URLSessionTransport(),
            middlewares: [AuthMiddleware(authorizationHeaderFieldValue: auth)]
        )
        return client
    }
}
