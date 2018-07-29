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
import os.log

class HoldsViewController: UIViewController {
    
    //MARK: - Properties
    
    @IBOutlet weak var holdsTable: UITableView!

    var items: [HoldRecord] = []
    var didCompleteFetch = false
    let log = OSLog(subsystem: AppSettings.logSubsystem, category: "Holds")

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - Functions
    
    func setupViews() {
        holdsTable.delegate = self
        holdsTable.dataSource = self
        holdsTable.tableFooterView = UIView() // prevent display of ghost rows at end of table
    }

    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        
        // fetch holds
        let req = Gateway.makeRequest(service: API.circ, method: API.holdsRetrieve, args: [authtoken, userid])
        req.gatewayArrayResponse().done { objects in
            self.items = HoldRecord.makeArray(objects)
            try self.fetchHoldDetails()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchHoldDetails() throws {
        guard let authtoken = App.account?.authtoken else {
            throw HemlockError.sessionExpired()
        }
        var promises: [Promise<Void>] = []
        for hold in self.items {
            promises.append(try fetchTargetDetails(hold: hold, authtoken: authtoken))
            promises.append(try fetchQueueStats(hold: hold, authtoken: authtoken))
        }
        os_log("%d promises made", log: self.log, type: .info, promises.count)

        firstly {
            when(fulfilled: promises)
        }.done {
            os_log("%d promises done", log: self.log, type: .info, promises.count)
            self.updateItems()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchTargetDetails(hold: HoldRecord, authtoken: String) throws -> Promise<Void> {
        guard let holdTarget = hold.target,
            let holdType = hold.holdType else {
            return Promise<Void>() //TODO: add analytics
        }
        if holdType == "T" {
            return fetchTitleHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else if hold.holdType == "M" {
            return fetchMetarecordHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else if hold.holdType == "P" {
            return fetchPartHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else {
            os_log("fetchTargetInfo target=%d holdType=%@ NOT HANDLED", log: log, type: .info, holdTarget, holdType)
            return Promise<Void>() //TODO: add analytics
        }
    }

    func fetchTitleHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) -> Promise<Void> {
        os_log("fetchTargetInfo target=%d holdType=T mods start", log: self.log, type: .info, holdTarget)
        let req = Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [holdTarget])
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<Void> in
            os_log("fetchTargetInfo target=%d holdType=T mods done", log: self.log, type: .info, holdTarget)
            let record = MBRecord(id: holdTarget, mvrObj: obj)
            hold.metabibRecord = record
            return PCRUDService.fetchSearchFormat(authtoken: authtoken, forRecord: record)
        }
        return promise
    }

    func fetchMetarecordHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) -> Promise<Void> {
        os_log("fetchTargetInfo target=%d holdType=M mods start", log: self.log, type: .info, holdTarget)
        let req = Gateway.makeRequest(service: API.search, method: API.metarecordModsRetrieve, args: [holdTarget])
        let promise = req.gatewayObjectResponse().done { obj in
            os_log("fetchTargetInfo target=%d holdType=M mods done", log: self.log, type: .info, holdTarget)
            hold.metabibRecord = MBRecord(id: holdTarget, mvrObj: obj)
        }
        return promise
    }

    func fetchPartHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) -> Promise<Void> {
        os_log("fetchTargetInfo target=%d holdType=P fielder start", log: self.log, type: .info, holdTarget)
            var param: [String: Any] = [:]
        param["cache"] = 1
        param["fields"] = ["label", "record"]
        param["query"] = ["id": holdTarget]
        let req = Gateway.makeRequest(service: API.fielder, method: API.fielderBMPAtomic, args: [param])
        let promise = req.gatewayArrayResponse().then { (array: [OSRFObject]) -> Promise<(OSRFObject)> in
            var target = 0
            if let obj = array.first {
                target = obj.getInt("record") ?? 0
                hold.label = obj.getString("label")
            }
            os_log("fetchTargetInfo target=%d holdType=P targetRecord=%d fielder done mods start", log: self.log, type: .info, holdTarget, target)
            return Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [target]).gatewayObjectResponse()
        }.done { (obj: OSRFObject) -> Void in
            os_log("fetchTargetInfo target=%d holdType=P mods done", log: self.log, type: .info, holdTarget)
            if let id = obj.getInt("doc_id") {
                hold.metabibRecord = MBRecord(id: id, mvrObj: obj)
            }
        }
        return promise
    }
    
    func fetchQueueStats(hold: HoldRecord, authtoken: String) throws -> Promise<Void> {
        guard let id = hold.ahrObj.getID("id") else {
            return Promise<Void>() //TODO: add analytics
        }
        let holdTarget = hold.target ?? 0
        os_log("fetchQueueStats target=%d start", log: self.log, type: .info, holdTarget)
        let req = Gateway.makeRequest(service: API.circ, method: API.holdQueueStats, args: [authtoken, id])
        let promise = req.gatewayObjectResponse().done { obj in
            os_log("fetchQueueStats target=%d done", log: self.log, type: .info, holdTarget)
            hold.qstatsObj = obj
        }
        return promise
    }

    func updateItems() {
        self.didCompleteFetch = true
        os_log("updateItems %d items", log: self.log, type: .info, items.count)
        holdsTable.reloadData()
    }
}

extension HoldsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !didCompleteFetch {
            return ""
        } else if items.count == 0 {
            return "No items on hold"
        } else {
            return "Items on hold: \(items.count)"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? HoldsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let item = items[indexPath.row]
        cell.holdsTitleLabel.text = item.title
        cell.holdsAuthorLabel.text = item.author
        cell.holdsStatusLabel.text = item.status
        let holdstotaltext = "\(item.totalHolds) holds on \(item.potentialCopies) copies"
        cell.holdsQueueLabel.text = holdstotaltext
        cell.holdsQueuePosition.text = "Queue position: \(item.queuePosition)"

        return cell
    }
}

extension HoldsViewController: UITableViewDelegate {
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let item = items[indexPath.row]
//        selectedItem = item
//        self.performSegue(withIdentifier: "ShowDetailsSegue", sender: nil)
    }
}

