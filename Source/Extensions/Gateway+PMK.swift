//
//  Alamofire+PMK.swift
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

@_exported import Alamofire
import Foundation
import PromiseKit
import PMKAlamofire
import os.log

extension Alamofire.DataRequest {
    func gatewayResponse(queue: DispatchQueue = .main) -> Promise<(GatewayResponse)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
//                let tag = response.request?.debugTag ?? Analytics.nullTag
                //AF5 TODO: fix request logging
//                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
//                Analytics.logResponse(tag: tag, data: response.result.value)
                switch response.result {
                case .success(let data):
                    seal.fulfill((GatewayResponse(data)))
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    func gatewayArrayResponse(queue: DispatchQueue = .main) -> Promise<([OSRFObject])>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                //AF5 TODO: fix request logging
//                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
//                Analytics.logResponse(tag: tag, data: response.result.value)
				switch response.result {
				case .success(let data):
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    } else if let array = resp.array {
                        seal.fulfill(array)
                    } else {
                        let extra = Bundle.isTestFlightOrDebug ? " (\(tag))" : ""
                        seal.reject(HemlockError.serverError("expected array, received \(resp.description)\(extra)"))
                    }
				case .failure(let error):
					seal.reject(error)
				}
            }
        }
    }

    func gatewayMaybeEmptyArrayResponse(queue: DispatchQueue = .main) -> Promise<([OSRFObject])>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                //AF5 TODO: fix request logging
//                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
//                Analytics.logResponse(tag: tag, data: response.result.value)
				switch response.result {
				case .success(let data):
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    } else if resp.type == .empty {
                        seal.fulfill([])
                    } else if let array = resp.array {
                        seal.fulfill(array)
                    } else {
                        let extra = Bundle.isTestFlightOrDebug ? " (\(tag))" : ""
                        seal.reject(HemlockError.serverError("expected array, received \(resp.description)\(extra)"))
                    }
				case .failure(let error):
					seal.reject(error)
				}
            }
        }
    }

    func gatewayObjectResponse(queue: DispatchQueue = .main) -> Promise<(OSRFObject)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                //AF5 TODO: fix request logging
//                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
//                Analytics.logResponse(tag: tag, data: response.result.value)
				switch response.result {
				case .success(let data):
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    } else if let obj = resp.obj {
                        seal.fulfill(obj)
                    } else {
                        let extra = Bundle.isTestFlightOrDebug ? " (\(tag))" : ""
                        seal.reject(HemlockError.serverError("expected object, received \(resp.description)\(extra)"))
                    }
				case .failure(let error):
					seal.reject(error)
				}
            }
        }
    }

    func gatewayOptionalObjectResponse(queue: DispatchQueue = .main) -> Promise<(OSRFObject?)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
//                let tag = response.request?.debugTag ?? Analytics.nullTag
                //AF5 TODO: fix request logging
//                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
//                Analytics.logResponse(tag: tag, data: response.result.value)
				switch response.result {
				case .success(let data):
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    }
                    seal.fulfill(resp.obj)
				case .failure(let error):
					seal.reject(error)
				}
            }
        }
    }

    /// for APIs like patronSettingsUpdate, that return "1" or an event on error
    func gatewayStringResponse(queue: DispatchQueue = .main) -> Promise<(String)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
//                let tag = response.request?.debugTag ?? Analytics.nullTag
                //AF5 TODO: fix request logging
//                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
//                Analytics.logResponse(tag: tag, data: response.result.value)
				switch response.result {
				case .success(let data):
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    } else if resp.obj != nil {
                        seal.fulfill("1")
                    } else if let str = resp.str {
                        seal.fulfill(str)
                    } else {
                        seal.reject(HemlockError.unexpectedNetworkResponse("expected auth response"))
                    }
				case .failure(let error):
					seal.reject(error)
				}
            }
        }
    }

    func gatewayAuthtokenResponse(queue: DispatchQueue = .main) -> Promise<(String)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
//                let tag = response.request?.debugTag ?? Analytics.nullTag
                //AF5 TODO: fix request logging
//                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
//                Analytics.logResponse(tag: tag, data: response.result.value)
				switch response.result {
				case .success(let data):
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    } else if let obj = resp.obj,
                        let payload = obj.getObject("payload"),
                        let authtoken = payload.getString("authtoken") {
                        seal.fulfill(authtoken)
                    } else {
                        seal.reject(HemlockError.unexpectedNetworkResponse("expected auth response"))
                    }
				case .failure(let error):
					seal.reject(error)
				}
            }
        }
    }
}
