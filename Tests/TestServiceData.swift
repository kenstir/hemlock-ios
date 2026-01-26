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
@testable import Hemlock

struct TestServiceData {
    static let configFile = "TestUserData/testServiceData" // .json

    var httpbinServer = "https://httpbin.org"

    var error: String? = nil

    static func make(fromBundle bundle: Bundle) -> TestServiceData {
        var serviceData = TestServiceData()

        // read json file
        guard let path = bundle.path(forResource: TestServiceData.configFile, ofType: "json") else {
            return serviceData
        }
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data),
            let jsonObject = json as? [String: Any] else
        {
            fatalError("invalid JSON data in \(TestServiceData.configFile).json, see TestUserData/README.md")
        }
        if let httpbinServer = jsonObject["httpbinServer"] as? String {
            serviceData.httpbinServer = httpbinServer
        }
        return serviceData
    }

    func httpbinServerURL(path: String? = nil) -> String {
        return httpbinServer + (path ?? "/get")
    }

    func httpbinServerPostURL() -> String {
        return httpbinServerURL(path: "/post")
    }

}
