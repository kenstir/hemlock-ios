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
import ToastSwiftFramework

class CheckoutsViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var items: [CircRecord] = []
    var selectedItem: CircRecord?
    var didCompleteFetch = false
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // deselect row when navigating back
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        self.fetchData()
    }

    //MARK: - Functions
    
    func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self
        
        // style the activity indicator
        Style.styleActivityIndicator(activityIndicator)
    }
    
    func showSessionExpiredAlert(_ error: Error, relogHandler: (() -> Void)?, cancelHandler: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: "Session timed out", message: "Do you want to login again?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            if let h = cancelHandler { h() }
        }
        let loginAction = UIAlertAction(title: "Login", style: .default) { action in
            if let h = relogHandler { h() }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(loginAction)
        self.present(alertController, animated: true)
    }

    func handleGatewayError(_ error: Error) {
        if isSessionExpired(error: error) {
            self.showSessionExpiredAlert(error, relogHandler: {
                print("******************************* relog")
            }, cancelHandler: {
                print("******************************* cancel")
            })
        } else {
            self.showAlert(error: error)
        }
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
            self.fetchCircRecords(authtoken: authtoken, fromObject: obj)
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.handleGatewayError(error)
        }
    }
    
    func fetchCircRecords(authtoken: String, fromObject obj: OSRFObject) {
        let ids = obj.getIDList("overdue") + obj.getIDList("out")
        var records: [CircRecord] = []
        var promises: [Promise<Void>] = []
        for id in ids {
            let record = CircRecord(id: id)
            records.append(record)
            promises.append(fetchCircDetails(authtoken: authtoken, forCircRecord: record))
        }
        print("xxx \(promises.count) promises made")
        
        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            self.activityIndicator.stopAnimating()
            self.updateItems(withRecords: records)
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.showAlert(error: error)
        }
    }
    
    func fetchCircDetails(authtoken: String, forCircRecord circRecord: CircRecord) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.circ, method: API.circRetrieve, args: [authtoken, circRecord.id])
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            print("xxx \(circRecord.id) circRetrieve done")
            circRecord.circObj = obj
            guard let target = obj.getInt("target_copy") else {
                // TODO: add anayltics or, just let it throw?
                throw PMKError.cancelled
            }
            let req = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [target])
            return req.gatewayObjectResponse()
        }.then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            print("xxx \(circRecord.id) modsFromCopy done")
            debugPrint(obj.dict)
            guard let id = obj.getInt("doc_id") else {
                throw HemlockError.unexpectedNetworkResponse("no doc_id for circ record \(circRecord.id)")
            }
            circRecord.metabibRecord = MBRecord(id: id, mvrObj: obj)
            let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveMRA, args: [API.anonymous, id])
            return req.gatewayObjectResponse()
        }.done { obj in
            debugPrint(obj.dict)
            print("xxx \(circRecord.id) format done")
            let searchFormat = Format.getSearchFormat(fromMRAObject: obj)
            circRecord.metabibRecord?.searchFormat = searchFormat
        }
        return promise
    }

    func updateItems(withRecords records: [CircRecord]) {
        self.didCompleteFetch = true
        self.items = records
        print("xxx \(records.count) records now, time to reloadData")
        tableView.reloadData()
    }

    @IBAction func buttonPressed(sender: UIButton) {
        let item = items[sender.tag]
        guard let authtoken = App.account?.authtoken,
            let userID = App.account?.userID else
        {
            self.showAlert(error: HemlockError.sessionExpired())
            return
        }
        guard let targetCopy = item.circObj?.getID("target_copy") else {
            self.showAlert(title: "Error", message: "Circulation item has no target_copy")
            return
        }

        // confirm renew action
        let alertController = UIAlertController(title: "Renew item?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Renew", style: .default) { action in
            self.renewItem(authtoken: authtoken, userID: userID, targetCopy: targetCopy)
        })
        self.present(alertController, animated: true)
    }
    
    func renewItem(authtoken: String, userID: Int, targetCopy: Int) {
        let promise = CircService.renew(authtoken: authtoken, userID: userID, targetCopy: targetCopy)
        promise.done { obj in
            print("xxx obj = ")
            debugPrint(obj)
            print("xxx MAKE TOAST NOW")
            self.navigationController?.view.makeToast("Item renewed")
            // refresh data
            self.fetchData()
        }.catch { error in
            self.showAlert(error: error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination
        guard let detailsVC = vc as? DetailsViewController,
            let metabibRecord = selectedItem?.metabibRecord else
        {
            print("Uh oh!")
            return
        }
        detailsVC.item = metabibRecord
    }
}

//MARK: - UITableViewDataSource
extension CheckoutsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !didCompleteFetch {
            return ""
        } else if items.count == 0 {
            return "No items checked out"
        } else {
            return "Items checked out: \(items.count)"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CheckoutsTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CheckoutsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let item = items[indexPath.row]
        cell.title.text = item.title
        cell.author.text = item.author
        cell.format.text = item.format
        cell.dueDate.text = "Due " + item.dueDate
        
        // add an action to the renewButton
        cell.renewButton.tag = indexPath.row
        cell.renewButton.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
        if let renewals = item.circObj?.getInt("renewal_remaining"), renewals > 0 {
            cell.renewButton.isEnabled = true
        } else {
            cell.renewButton.isEnabled = false
        }
        Style.styleButton(asOutline: cell.renewButton)

        return cell
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
