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
    /*
    func gatewayResponseAsyncFirstAttempt(queue: DispatchQueue = .main) async throws -> GatewayResponse {
        return try await withCheckedThrowingContinuation { continuation in
            responseData(queue: queue) { response in
                switch response.result {
                case .success(let data):
                    let cached = self.wasCached(response.metrics)
                    Analytics.logResponse(tag: response.request?.debugTag, data: data, cached: cached)
                    continuation.resume(returning: GatewayResponse(data))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    */

    func gatewayResponseAsync() async throws -> GatewayResponse {
        let resp = await serializingData().response
        let data = try resp.result.get()
        let cached = self.wasCached(resp.metrics)
        Analytics.logResponse(tag: self.request?.debugTag, data: data, cached: cached, elapsedMs: self.elapsedInMs(resp.metrics))
        return GatewayResponse(data)
    }

    func gatewayDataResponseAsync() async throws -> Data {
        let resp = await serializingData().response
        let data = try resp.result.get()
        let cached = self.wasCached(resp.metrics)
        Analytics.logResponse(tag: self.request?.debugTag, data: data, cached: cached, elapsedMs: self.elapsedInMs(resp.metrics))
        return data
    }

    func wasCached(_ metrics: URLSessionTaskMetrics?) -> Bool {
        // Get the last transaction metric (the "final" one)
        if let finalMetric = metrics?.transactionMetrics.last {
            if finalMetric.resourceFetchType == .localCache {
                return true
            }
        }
        return false
    }

    func elapsedInMs(_ metrics: URLSessionTaskMetrics?) -> Int? {
        if let elapsed = metrics?.taskInterval.duration {
            return Int((elapsed * 1000.0).rounded())
        }
        return nil
    }

    /* Decided against using JSONResponseSerializer because it is not easier, and also it is deprecated.
    func gatewayObjectResponseAsyncUsingDeprecatedResponseSerializer() async throws -> OSRFObject {
        let resp = serializingResponse(using: JSONResponseSerializer())
        print("resp: \(type(of: resp)): \(resp)")
        let value = try await resp.value
        print("value: \(type(of: value)): \(value)")
        let dict = value as? JSONDictionary
        print("dict: \(type(of: dict)): \(dict)")
        return OSRFObject()
    }
     */
}
