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

struct CheckoutsList {
    let title: String
    var items: [CircRecord] = []
    init(_ title: String) {
        self.title = title
    }
}

class CheckoutsViewController: UITableViewController {
    
    //MARK: - fields
    var lists = [CheckoutsList("checked out"), CheckoutsList("overdue")]
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
            self.fetchItemDetails(obj.getListOfIDs("out"), obj.getListOfIDs("overdue"))
        }
    }
    
    func fetchItemDetails(_ outIds: [Int], _ overdueIds: [Int]) {
        var out: [CircRecord] = []
        var overdue: [CircRecord] = []
        for id in outIds { out.append(CircRecord(id: id)) }
        for id in overdueIds { overdue.append(CircRecord(id: id)) }

        // update items lists, but wait to call reloadData
        lists[0].items = out
        lists[1].items = overdue

        guard let authtoken = AppSettings.account?.authtoken else
        {
            self.showAlert(title: "Internal Error", message: "Not logged in")
            return
        }
        
        itemsToFetch = out.count + overdue.count
        
        let allRecords = out + overdue
        for circ in allRecords {
            let request = Gateway.makeRequest(service: API.circ, method: API.circRetrieve, args: [authtoken, circ.id!])
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
                
                circ.obj = obj

                self.maybeReloadTable()
            }
        }
    }
            
    func maybeReloadTable() {
        if self.itemsToFetch == 0 {
            tableView.reloadData()
        }
    }

//    func updateItemsCheckedOut(_ out: [CircRecord], _ overdue: [CircRecord]) {
//        lists[0].items = out
//        lists[1].items = overdue
//        tableView.reloadData()
//    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
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
        cell.title.text = item.obj?.getString("title")
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
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
