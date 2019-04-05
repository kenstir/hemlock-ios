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
    weak var activityIndicator: UIActivityIndicatorView!

    var items: [HoldRecord] = []
    var didCompleteFetch = false
    let log = OSLog(subsystem: App.config.logSubsystem, category: "Holds")

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
        holdsTable.tableFooterView = UIView() // prevent ghost rows at end of table
        setupActivityIndicator()
        self.setupHomeButton()
    }
    
    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }

    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        
        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()
        
        // fetch holds
        let req = Gateway.makeRequest(service: API.circ, method: API.holdsRetrieve, args: [authtoken, userid])
        req.gatewayArrayResponse().done { objects in
            self.items = HoldRecord.makeArray(objects)
            try self.fetchHoldDetails()
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchHoldDetails() throws {
        guard let authtoken = App.account?.authtoken else {
            throw HemlockError.sessionExpired()
        }
        var promises: [Promise<Void>] = []
        for hold in self.items {
            promises.append(try fetchHoldTargetDetails(hold: hold, authtoken: authtoken))
            promises.append(try fetchHoldQueueStats(hold: hold, authtoken: authtoken))
        }
        os_log("%d promises made", log: self.log, type: .info, promises.count)

        firstly {
            when(resolved: promises)
        }.done { results in
            os_log("%d promises done", log: self.log, type: .info, promises.count)
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forResults: results)
            self.updateItems()
        }
    }
    
    func fetchHoldTargetDetails(hold: HoldRecord, authtoken: String) throws -> Promise<Void> {
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
        } else if hold.holdType == "C" {
            return fetchCopyHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
        } else if hold.holdType == "V" {
            return fetchVolumeHoldTargetDetails(hold: hold, holdTarget: holdTarget, authtoken: authtoken)
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
            guard let obj = array.first,
                let target = obj.getInt("record") else
            {
                throw HemlockError.unexpectedNetworkResponse("Failed to load fields for part hold")
            }
            hold.label = obj.getString("label")
            os_log("fetchTargetInfo target=%d holdType=P targetRecord=%d fielder done mods start", log: self.log, type: .info, holdTarget, target)
            return Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [target]).gatewayObjectResponse()
        }.done { (obj: OSRFObject) -> Void in
            os_log("fetchTargetInfo target=%d holdType=P mods done", log: self.log, type: .info, holdTarget)
            guard let id = obj.getInt("doc_id") else { throw HemlockError.unexpectedNetworkResponse("Failed to find doc_id for part hold") }
            hold.metabibRecord = MBRecord(id: id, mvrObj: obj)
        }
        return promise
    }
    
    func fetchCopyHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) -> Promise<Void> {
        os_log("fetchTargetInfo target=%d holdType=T asset start", log: self.log, type: .info, holdTarget)
        let req = Gateway.makeRequest(service: API.search, method: API.assetCopyRetrieve, args: [holdTarget])
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            guard let callNumber = obj.getID("call_number") else { throw HemlockError.unexpectedNetworkResponse("Failed to find call_number for copy hold") }
            os_log("fetchTargetInfo target=%d holdType=T call start", log: self.log, type: .info, holdTarget)
            return Gateway.makeRequest(service: API.search, method: API.assetCallNumberRetrieve, args: [callNumber]).gatewayObjectResponse()
        }.then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            guard let id = obj.getID("record") else { throw HemlockError.unexpectedNetworkResponse("Failed to find asset record for copy hold") }
            os_log("fetchTargetInfo target=%d holdType=T mods start", log: self.log, type: .info, holdTarget)
            //hold.partLabel = obj.getString("label")
            return Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [id]).gatewayObjectResponse()
        }.done { (obj: OSRFObject) -> Void in
            os_log("fetchTargetInfo target=%d holdType=P mods done", log: self.log, type: .info, holdTarget)
            guard let id = obj.getInt("doc_id") else { throw HemlockError.unexpectedNetworkResponse("Failed to find doc_id for copy hold") }
            hold.metabibRecord = MBRecord(id: id, mvrObj: obj)
        }
        return promise
    }
    
    func fetchVolumeHoldTargetDetails(hold: HoldRecord, holdTarget: Int, authtoken: String) -> Promise<Void> {
        os_log("fetchTargetInfo target=%d holdType=V call start", log: self.log, type: .info, holdTarget)
        let req = Gateway.makeRequest(service: API.search, method: API.assetCallNumberRetrieve, args: [holdTarget])
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            guard let id = obj.getID("record") else { throw HemlockError.unexpectedNetworkResponse("Failed to find asset record for volume hold")}
            os_log("fetchTargetInfo target=%d holdType=V mods start", log: self.log, type: .info, holdTarget)
            //hold.partLabel = obj.getString("label")
            return Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [id]).gatewayObjectResponse()
        }.done { (obj: OSRFObject) -> Void in
            os_log("fetchTargetInfo target=%d holdType=V mods done", log: self.log, type: .info, holdTarget)
            guard let id = obj.getInt("doc_id") else { throw HemlockError.unexpectedNetworkResponse("Failed to find doc_id for volume hold") }
            hold.metabibRecord = MBRecord(id: id, mvrObj: obj)
        }
        return promise
    }

    func fetchHoldQueueStats(hold: HoldRecord, authtoken: String) throws -> Promise<Void> {
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

    @objc func buttonPressed(sender: UIButton) {
        let hold = items[sender.tag]
        guard let authtoken = App.account?.authtoken else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
            return
        }
        guard let holdID = hold.id else {
            self.showAlert(title: "Internal Error", error: HemlockError.unexpectedNetworkResponse("Hold record has no ID"))
            //TODO: analytics
            return
        }

        // confirm action
        let alertController = UIAlertController(title: "Cancel hold?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Keep Hold", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Cancel Hold", style: .default) { action in
            self.cancelHold(authtoken: authtoken, holdID: holdID)
        })
        self.present(alertController, animated: true)
    }
    
    func cancelHold(authtoken: String, holdID: Int) {
        let promise = CircService.cancelHold(authtoken: authtoken, holdID: holdID)
        promise.done { resp, pmkresp in
            guard resp.type == GatewayResponseType.string,
                resp.str == "1" else
            {
                self.navigationController?.view.makeToast("Cancelling hold failed: \(String(describing: resp))")
                return
            }
            self.navigationController?.view.makeToast("Hold cancelled")
            self.fetchData()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
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
        cell.holdsFormatLabel.text = item.format
        cell.holdsStatusLabel.text = item.status
        let holdstotaltext = "\(item.totalHolds) holds on \(item.potentialCopies) copies"
        cell.holdsQueueLabel.text = holdstotaltext
        cell.holdsQueuePosition.text = "Queue position: \(item.queuePosition)"

        // add an action to the button
        cell.holdsCancelButton.tag = indexPath.row
        cell.holdsCancelButton.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asOutline: cell.holdsCancelButton)

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

