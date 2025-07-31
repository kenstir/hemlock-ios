//
//  Copyright (c) 2025 Kenneth H. Cox
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

import Alamofire
import Foundation
import os.log

extension Alamofire.DataRequest {
    func gatewayResponseAsync(queue: DispatchQueue = .main) async throws -> GatewayResponse {
        return try await withCheckedThrowingContinuation { continuation in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                switch response.result {
                case .success(let data):
                    Analytics.logResponse(tag: tag, data: data)
                    continuation.resume(returning: GatewayResponse(data))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
