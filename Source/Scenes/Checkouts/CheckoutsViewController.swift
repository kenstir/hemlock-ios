//
//  MainViewController.swift
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

struct CheckoutsViewButtonData {
    let title: String
    init(_ title: String) {
        self.title = title
    }
}

class Checkouts {
    let title: String
    var items: [CircRecord] = []
    init(_ title: String) {
        self.title = title
    }
}

class CheckoutsViewController: UITableViewController {
    
    //MARK: - fields
    let lists = [Checkouts("checked out"), Checkouts("overdue")]
    lazy var out = lists[0]
    lazy var overdue = lists[1]
    var itemsToFetch = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //tableView.tableHeaderView?.backgroundColor = UIColor.cyan
        //tableView.tableFooterView?.backgroundColor = UIColor.cyan
        
        fetchItemsCheckedOut()
    }
    
    //MARK: - functions
    
    func fetchItemsCheckedOut() {
        guard let authtoken = AppSettings.account?.authtoken,
            let id = AppSettings.account?.userID else
        {
            self.showAlert(title: "Internal Error", message: "Not logged in")
            return
        }
        let request = Gateway.makeRequest(service: API.actor, method: API.actorCheckedOut, args: [authtoken, id])
        request.responseData { response in
            // todo factor out common response handling
            guard response.result.isSuccess,
                let data = response.result.value else
            {
                let msg = response.description
                self.showAlert(title: "Request failed", message: msg)
                return
            }
            let resp = GatewayResponse(data)
            guard !resp.failed,
                let obj = resp.obj else
            {
                self.showAlert(title: "Request failed", message: resp.errorMessage)
                return
            }

            // update items lists now, but wait to call reloadData
            self.out.items = self.makeCircRecords(obj.getIntList("out"))
            self.overdue.items = self.makeCircRecords(obj.getIntList("overdue"))

            self.fetchCircRecords()
        }
    }
    
    func makeCircRecords(_ ids: [Int]) -> [CircRecord] {
        var ret: [CircRecord] = []
        for id in ids {
            ret.append(CircRecord(id: id))
        }
        return ret
    }
    
    func fetchCircRecords() {
        guard let authtoken = AppSettings.account?.authtoken else {
            self.showAlert(title: "Internal Error", message: "Not logged in")
            return
        }
        
        itemsToFetch = out.items.count + overdue.items.count
        
        let allRecords = out.items + overdue.items
        for circ in allRecords {
            let request = Gateway.makeRequest(service: API.circ, method: API.circRetrieve, args: [authtoken, circ.id])
            request.responseData { response in
                self.itemsToFetch -= 1

                // todo factor out common response handling
                guard response.result.isSuccess,
                    let data = response.result.value else
                {
                    self.maybeReloadTable()
                    return
                }
                let resp = GatewayResponse(data)
                guard !resp.failed,
                    let obj = resp.obj else
                {
                    self.maybeReloadTable()
                    return
                }
                
                debugPrint(obj)
                circ.circObj = obj

                self.fetchMVR(circ)
            }
        }
    }
    
    func fetchMVR(_ circ: CircRecord) {
        guard let id = circ.circObj?.getInt("target_copy") else {
            return // todo assert
        }
        
        let request = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [id])
        request.responseData { response in
            
            // todo factor out common response handling
            guard response.result.isSuccess,
                let data = response.result.value else
            {
                self.maybeReloadTable()
                return
            }
            let resp = GatewayResponse(data)
            guard !resp.failed,
                let obj = resp.obj else
            {
                self.maybeReloadTable()
                return
            }
            
            debugPrint(obj)
            circ.mvrObj = obj
            self.maybeReloadTable()
        }
    }

    func maybeReloadTable() {
        if self.itemsToFetch == 0 {
            tableView.reloadData()
        }
    }

    //MARK: - UITableViewController
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return lists.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if lists[section].items.count == 0 {
            return "No items " + lists[section].title
        } else {
            return lists[section].title
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 34
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CheckoutsTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CheckoutsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let item = lists[indexPath.section].items[indexPath.row]
        let id = item.id
        let title = item.mvrObj?.getString("title")
        print("cell index \(indexPath) id \(id) title \(title)")
        cell.title.text = title
        
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let tuple = buttons[indexPath.row]
//        let segue = tuple.1
//        self.performSegue(withIdentifier: segue, sender: nil)
    }
    
    @IBAction func buttonPressed(sender: UIButton) {
//        AppSettings.account?.logout()
//        self.performSegue(withIdentifier: "ShowLoginSegue", sender: nil)
    }
}
