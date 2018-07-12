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
    
    @IBOutlet weak var holdsTable: UITableView!

    var items: [HoldRecord] = []
    var didCompleteFetch = false
    
    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        fetchData()
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
        var req: Alamofire.DataRequest
        if hold.holdType == "T" {
            req = Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [target])
            let promise = req.gatewayObjectResponse().done { obj in
                print("xxx \(String(describing: hold.target)) fetchTargetInfo done")
                hold.mvrObj = obj
            }
            return promise
        } else if hold.holdType == "M" {
            req = Gateway.makeRequest(service: API.search, method: API.metarecordModsRetrieve, args: [target])
            let promise = req.gatewayObjectResponse().done { obj in
                print("xxx \(String(describing: hold.target)) fetchTargetInfo done")
                hold.mvrObj = obj
            }
            return promise
        } else if hold.holdType == "P" {
            var param: [String: Any] = [:]
            param["cache"] = 1
            param["fields"] = ["label", "record"]
            param["query"] = ["id": target]
            req = Gateway.makeRequest(service: API.fielder, method: API.fielderBMPAtomic, args: [param])
            let promise = req.gatewayArrayResponse().then { (array: [OSRFObject]) -> Promise<(OSRFObject)> in
                var target = 0
                if let obj = array.first {
                    target = obj.getInt("record") ?? 0
                    hold.label = obj.getString("label")
                }
                return Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [target]).gatewayObjectResponse()
            }.done { (obj: OSRFObject) -> Void in
                print("xxx \(String(describing: hold.target)) fetchTargetInfo done")
                hold.mvrObj = obj
            }
            return promise
        } else {
            return Promise<Void>() //TODO: add analytics
        }
    }
    
    func fetchQueueStats(hold: HoldRecord, authtoken: String) throws -> Promise<Void> {
        guard let id = hold.ahrObj.getID("id") else {
            return Promise<Void>() //TODO: add analytics
        }
        let req = Gateway.makeRequest(service: API.circ, method: API.holdQueueStats, args: [authtoken, id])
        let promise = req.gatewayObjectResponse().done { obj in
            print("xxx \(String(describing: hold.target)) queueStats done")
            hold.qstatsObj = obj
        }
        return promise
    }

    func updateItems(holds: [HoldRecord]) {
        self.items = holds
        self.didCompleteFetch = true
        print("xxx \(items.count) records now, time to reloadData")
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

