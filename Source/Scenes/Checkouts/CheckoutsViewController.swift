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
import os.log

class CheckoutsViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet weak var tableView: UITableView!
    
    weak var activityIndicator: UIActivityIndicatorView!

    var items: [CircRecord] = []
    var selectedItem: CircRecord?
    var didCompleteFetch = false
    let log = OSLog(subsystem: Bundle.appIdentifier, category: "Checkouts")

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
        
        if !didCompleteFetch {
            self.fetchData()
        }
    }

    //MARK: - Functions
    
    func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self
        setupActivityIndicator()
        self.setupHomeButton()
        if App.config.enableCheckoutHistory {
            let image = loadAssetImage(named: "history")
            let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(historyButtonPressed(sender:)))
            navigationItem.rightBarButtonItems?.append(button)
        }
    }

    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }

    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }
        
        centerSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // fetch the list of items
        let req = Gateway.makeRequest(service: API.actor, method: API.actorCheckedOut, args: [authtoken, userid], shouldCache: false)
        req.gatewayObjectResponse().done { obj in
            self.fetchCircRecords(authtoken: authtoken, fromObject: obj)
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error, title: "Error fetching checkouts")
        }
    }
    
    func fetchCircRecords(authtoken: String, fromObject obj: OSRFObject) {
        let ids = obj.getIDList("overdue") + obj.getIDList("out")
        var records: [CircRecord] = []
        var promises: [Promise<Void>] = []
        promises.append(PCRUDService.fetchCodedValueMaps())
        for id in ids {
            let record = CircRecord(id: id)
            records.append(record)
            promises.append(fetchCircDetails(authtoken: authtoken, forCircRecord: record))
        }
        os_log("%d promises made", log: self.log, type: .info, promises.count)

        firstly {
            when(resolved: promises)
        }.done { results in
            os_log("%d promises done", log: self.log, type: .info, promises.count)
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forResults: results)
            self.didCompleteFetch = true
            self.updateItems(withRecords: records)
        }
    }
    
    func fetchCircDetails(authtoken: String, forCircRecord circRecord: CircRecord) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.circ, method: API.circRetrieve, args: [authtoken, circRecord.id], shouldCache: false)
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            circRecord.circObj = obj
            os_log("id=%d t=%d circ done", log: self.log, type: .info, circRecord.id, circRecord.targetCopy)
            let req = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [circRecord.targetCopy], shouldCache: true)
            return req.gatewayObjectResponse()
        }.then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            print("xxx \(circRecord.id) modsFromCopy done")
            debugPrint(obj.dict)
            guard let id = obj.getInt("doc_id") else {
                throw HemlockError.unexpectedNetworkResponse("no doc_id for circ record \(circRecord.id)")
            }
            if id != -1 {
                circRecord.metabibRecord = MBRecord(id: id, mvrObj: obj)
                let req = Gateway.makeRequest(service: API.pcrud, method: API.retrieveMRA, args: [API.anonymousAuthToken, id], shouldCache: true)
                return req.gatewayObjectResponse()
            } else {
                return ServiceUtils.makeEmptyObjectPromise()
            }
        }.then { (obj: OSRFObject) -> Promise<(OSRFObject)> in
            os_log("id=%d t=%d mra done (%@)", log: self.log, type: .info, circRecord.id, circRecord.targetCopy, circRecord.title)
            if (obj.dict.count > 0) {
                circRecord.metabibRecord?.attrs = RecordAttributes.parseAttributes(fromMRAObject: obj)
                return ServiceUtils.makeEmptyObjectPromise()
            } else {
                // emptyPromise above, need to retrieve the acp
                let req = Gateway.makeRequest(service: API.search, method: API.assetCopyRetrieve, args: [circRecord.targetCopy], shouldCache: true)
                return req.gatewayObjectResponse()
            }
        }.done { obj in
            print("xxx \(circRecord.id) ACP done")
            if (obj.dict.count > 0) {
                circRecord.acpObj = obj
            }
        }
        return promise
    }

    func updateItems(withRecords records: [CircRecord]) {
        self.items = records
        sortList()
        print("xxx \(records.count) records now, time to reloadData")
        tableView.reloadData()
    }

    @objc func renewPressed(sender: UIButton) {
        let item = items[sender.tag]
        guard let authtoken = App.account?.authtoken,
            let userID = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }
        guard let targetCopy = item.circObj?.getID("target_copy") else {
            self.showAlert(title: "Error", error: HemlockError.shouldNotHappen("Circulation item has no target_copy"))
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

        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        let promise = CircService.renew(authtoken: authtoken, userID: userID, targetCopy: targetCopy)
        promise.done { obj in
            self.navigationController?.view.makeToast("Item renewed")
            self.fetchData()
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error)
        }
    }

    func sortList() {
        items.sort() {
            guard let a = $0.dueDate, let b = $1.dueDate else { return false }
            return a < b
        }
        tableView.reloadData()
    }

    func dueDateText(_ item: CircRecord) -> String {
        if item.isOverdue {
            return "Due \(item.dueDateLabel) (overdue)"
        }
        // These are commented out for now because they cause the text
        // to bleed under the Renew button.
//        if item.isDue && item.autoRenewals > 0 {
//            return "Due \(item.dueDateLabel) (but may auto-renew)"
//        }
//        if item.wasAutoRenewed && !item.isDue {
//            return "Due \(item.dueDateLabel) (item was auto-renewed)"
//        }
        return "Due \(item.dueDateLabel)"
    }

    @objc func historyButtonPressed(sender: Any) {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }

        if account.userSettingCircHistoryStart != nil {
            showHistoryVC()
            return
        }

        // prompt to enable history
        let alertController = UIAlertController(title: "Checkout history is not enabled.", message: "Your account does not have checkout history enabled.  If you enable it, items you check out from now on will appear in your history.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Enable checkout history", style: .default) { action in
            self.enableCheckoutHistory(account: account)
        })
        self.present(alertController, animated: true)
    }

    func enableCheckoutHistory(account: Account) {
        let promise = ActorService.enableCheckoutHistory(account: account)
        promise.done {
            self.showAlert(title: "Success", message: "Items you check out from now on will appear in your history.")
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func showHistoryVC() {
        if let vc = UIStoryboard(name: "History", bundle: nil).instantiateInitialViewController() as? HistoryViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
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
            return "\(items.count) items checked out"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "checkoutsCell", for: indexPath) as? CheckoutsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        let item = items[indexPath.row]

        cell.title.text = item.title
        cell.author.text = item.author
        cell.format.text = item.format
        cell.renewals.text = "Renewals left: " + String(item.renewalsRemaining)
        cell.dueDate.text = dueDateText(item)
        cell.dueDate.textColor = item.isDue ? App.theme.alertTextColor : Style.secondaryLabelColor

        // add an action to the renewButton
        cell.renewButton.tag = indexPath.row
        cell.renewButton.addTarget(self, action: #selector(renewPressed(sender:)), for: .touchUpInside)
        cell.renewButton.isEnabled = (item.renewalsRemaining > 0)
        Style.styleButton(asOutline: cell.renewButton)

        return cell
    }
}

//MARK: - UITableViewDelegate
extension CheckoutsViewController: UITableViewDelegate {

    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var records: [MBRecord] = []
        for item in items {
            if let record = item.metabibRecord {
                records.append(record)
            }
        }

        if records.count > 0 {
            let displayOptions = RecordDisplayOptions(enablePlaceHold: false, orgShortName: nil)
            if let vc = XUtils.makeDetailsPager(items: records, selectedItem: indexPath.row, displayOptions: displayOptions) {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            // deselect row
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
