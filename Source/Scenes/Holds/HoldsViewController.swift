//
//  HoldsViewController.swift
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

import Foundation
import UIKit
import PromiseKit
import PMKAlamofire

class HoldsViewController: UIViewController {
    //MARK: - Properties
    
    var items: [HoldRecord] = []

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            showAlert(error: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        
        // fetch holds
        let req = Gateway.makeRequest(service: API.circ, method: API.holdsRetrieve, args: [authtoken, userid])
        req.gatewayArrayResponse().done { objects in
            try self.fetchHoldDetails(holds: HoldRecord.makeArray(objects))
        }.catch { error in
            self.showAlert(error: error)
        }
    }
    
    func fetchHoldDetails(holds: [HoldRecord]) throws {
        guard let authtoken = App.account?.authtoken else {
            throw HemlockError.sessionExpired()
        }
        var promises: [Promise<Void>] = []
        for hold in holds {
            promises.append(try fetchTargetInfo(hold: hold, authtoken: authtoken))
            promises.append(try fetchQueueStats(hold: hold, authtoken: authtoken))
        }
        print("xxx \(promises.count) promises made")

        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            self.updateItems(holds: holds)
        }.catch { error in
            self.showAlert(error: error)
        }
    }
    
    func fetchTargetInfo(hold: HoldRecord, authtoken: String) throws -> Promise<Void> {
        guard let target = hold.target else {
            return Promise<Void>() //TODO: add analytics
        }
        var method: String
        if hold.holdType == "T" {
            method = API.recordModsRetrieve
        } else if hold.holdType == "M" {
            method = API.metarecordModsRetrieve
        } else {
            return Promise<Void>() //TODO: add analytics
        }
        let req = Gateway.makeRequest(service: API.search, method: method, args: [target])
        let promise = req.gatewayObjectResponse().done { obj in
            print("xxx \(hold.target) fetchTargetInfo done")
            hold.mvrObj = obj
        }
        return promise
    }
    
    func fetchQueueStats(hold: HoldRecord, authtoken: String) throws -> Promise<Void> {
        guard let id = hold.ahrObj.getID("id") else {
            return Promise<Void>() //TODO: add analytics
        }
        let req = Gateway.makeRequest(service: API.circ, method: API.holdQueueStats, args: [authtoken, id])
        let promise = req.gatewayObjectResponse().done { obj in
            print("xxx \(hold.target) queueStats done")
            hold.qstatsObj = obj
        }
        return promise
    }

    func updateItems(holds: [HoldRecord]) {
        self.items = holds
        print("xxx \(items.count) records now, time to reloadData")
        for hold in holds {
            print("-----------------------")
            print("title:     \(hold.title)")
            print("author:    \(hold.author)")
            print("hold_type: \(hold.holdType)")
            print("status:    \(hold.status)")
            print("position:  \(hold.queuePosition)")
            print("of:        \(hold.totalHolds)")
            print("copies:    \(hold.potentialCopies)")
        }
    }
}
