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
    func gatewayResponse(queue: DispatchQueue? = nil) -> Promise<(GatewayResponse)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
                Analytics.logResponse(tag: tag, data: response.result.value)
                if response.result.isSuccess,
                    let data = response.result.value
                {
                    seal.fulfill((GatewayResponse(data)))
                } else if response.result.isFailure,
                    let error = response.error {
                    seal.reject(error)
                } else {
                    seal.reject(GatewayError.failure("unknown error")) //todo: add analytics
                }
            }
        }
    }

    func gatewayArrayResponse(queue: DispatchQueue? = nil) -> Promise<([OSRFObject])>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
                Analytics.logResponse(tag: tag, data: response.result.value)
                if response.result.isSuccess,
                    let data = response.result.value
                {
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    } else if let array = resp.array {
                        seal.fulfill(array)
                    } else {
                        seal.reject(HemlockError.unexpectedNetworkResponse("expected array, received \(resp.description)"))
                    }
                } else if response.result.isFailure,
                    let error = response.error {
                    seal.reject(error)
                } else {
                    seal.reject(GatewayError.failure("unknown error")) //todo: add analytics
                }
            }
        }
    }

    func gatewayObjectResponse(queue: DispatchQueue? = nil) -> Promise<(OSRFObject)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
                Analytics.logResponse(tag: tag, data: response.result.value)
                if response.result.isSuccess,
                    let data = response.result.value
                {
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    } else if let obj = resp.obj {
                        seal.fulfill(obj)
                    } else {
                        seal.reject(HemlockError.unexpectedNetworkResponse("expected object, received \(resp.description)"))
                    }
                } else if response.result.isFailure,
                    let error = response.error {
                    seal.reject(error)
                } else {
                    seal.reject(GatewayError.failure("unknown error")) //todo: add analytics
                }
            }
        }
    }

    func gatewayOptionalObjectResponse(queue: DispatchQueue? = nil) -> Promise<(OSRFObject?)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
                Analytics.logResponse(tag: tag, data: response.result.value)
                if response.result.isSuccess,
                    let data = response.result.value
                {
                    let resp = GatewayResponse(data)
                    if let error = resp.error {
                        seal.reject(error)
                    }
                    seal.fulfill(resp.obj)
                } else if response.result.isFailure,
                    let error = response.error {
                    seal.reject(error)
                } else {
                    seal.reject(GatewayError.failure("unknown error")) //todo: add analytics
                }
            }
        }
    }
    
    func gatewayAuthtokenResponse(queue: DispatchQueue? = nil) -> Promise<(String)>
    {
        return Promise { seal in
            responseData(queue: queue) { response in
                let tag = response.request?.debugTag ?? Analytics.nullTag
                os_log("%@: resp.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, tag, response.timeline.totalDuration, Gateway.addElapsed(response.timeline.totalDuration))
                Analytics.logResponse(tag: tag, data: response.result.value)
                if response.result.isSuccess,
                    let data = response.result.value
                {
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
                } else if response.result.isFailure,
                    let error = response.error {
                    seal.reject(error)
                } else {
                    seal.reject(GatewayError.failure("unknown error")) //todo: add analytics
                }
            }
        }
    }
}
