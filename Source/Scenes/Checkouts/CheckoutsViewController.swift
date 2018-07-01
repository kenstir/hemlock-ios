//
//  CheckoutsViewController.swift
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

import UIKit
import PromiseKit
import PMKAlamofire


class CheckoutsViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var items: [CircRecord] = []
    var selectedItem: CircRecord?
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchData()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self
        
        // style the activity indicator
        Style.styleActivityIndicator(activityIndicator)
    }
    
    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            showAlert(error: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        
        activityIndicator.startAnimating()
        
        // fetch the list of items
        let req = Gateway.makeRequest(service: API.actor, method: API.actorCheckedOut, args: [authtoken, userid])
        req.gatewayObjectResponse().done { obj in
            try self.fetchCircRecords(fromObject: obj)
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.showAlert(error: error)
        }
    }
    
    func fetchCircRecords(fromObject obj: OSRFObject) throws {
        let ids = obj.getIDList("out") + obj.getIDList("overdue")
        var records: [CircRecord] = []
        var promises: [Promise<Void>] = []
        for id in ids {
            let record = CircRecord(id: id)
            records.append(record)
            let promise = try fetchCircDetails(forRecord: record)
            promises.append(promise)
        }
        print("xxx \(promises.count) promises made")
        
        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            self.activityIndicator.stopAnimating()
            self.updateItems(withRecords: records)
        }.catch { error in
            self.showAlert(error: error)
        }
    }
    
    func fetchCircDetails(forRecord record: CircRecord) throws -> Promise<Void> {
        guard let authtoken = App.account?.authtoken else {
            throw HemlockError.sessionExpired()
        }
        let req = Gateway.makeRequest(service: API.circ, method: API.circRetrieve, args: [authtoken, record.id])
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            print("xxx \(record.id) circ done")
            record.circObj = obj
            guard let target = obj.getInt("target_copy") else {
                // TODO: add anayltics or, just let it throw?
                throw PMKError.cancelled
            }
            let req = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [target])
            return req.gatewayObjectResponse()
        }.done { obj in
            print("xxx \(record.id) mvr done")
            record.mvrObj = obj
        }
        return promise
    }

    func updateItems(withRecords records: [CircRecord]) {
        self.items = records
        print("xxx \(records.count) records now, time to reloadData")
        tableView.reloadData()
    }

    @IBAction func buttonPressed(sender: UIButton) {
        let item = items[sender.tag]
        guard let authtoken = App.account?.authtoken,
            let userID = App.account?.userID,
            let targetCopy = item.circObj?.getID("target_copy") else
        {
            self.showAlert(error: HemlockError.sessionExpired())
            return
        }

        let title = item.title
        print("xxx renew button pressed - \(title)")
        let promise = CircService.renew(authtoken: authtoken, userID: userID, targetCopy: targetCopy)
        promise.done { obj in
            debugPrint(obj)
            print("xxx renew succeeded")
        }.catch { error in
            self.showAlert(error: error)
        }
    }
}

extension CheckoutsViewController: UITableViewDataSource {

    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Items checked out: \(items.count)"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CheckoutsTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CheckoutsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let item = items[indexPath.row]
        cell.title.text = item.title
        cell.author.text = item.author
        cell.dueDate.text = "Due " + item.dueDate
        
        // add an action to the renewButton
        cell.renewButton.tag = indexPath.row
        cell.renewButton.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
        if let renewals = item.circObj?.getInt("renewal_remaining"),
            renewals > 0
        {
            cell.renewButton.isEnabled = true
        } else {
            cell.renewButton.isEnabled = false
        }
        Style.styleButton(asOutline: cell.renewButton)//Style.styleButton(asPlain: cell.renewButton)

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination
        guard let detailsVC = vc as? DetailsViewController,
            let mvrObj = selectedItem?.mvrObj else
        {
            print("Uh oh!")
            return
        }
        let record = MBRecord(mvrObj: mvrObj)
        detailsVC.item = record
    }
}

extension CheckoutsViewController: UITableViewDelegate {

    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        selectedItem = item
        self.performSegue(withIdentifier: "ShowDetailsSegue", sender: nil)
    }
}
