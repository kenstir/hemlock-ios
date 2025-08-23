//
//  Copyright (C) 2023 Kenneth H. Cox
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
import os.log

class HistoryViewController: UITableViewController {

    //MARK: - Properties

    weak var activityIndicator: UIActivityIndicatorView!

    var items: [HistoryRecord] = []
    var didCompleteFetch = false
    let log = OSLog(subsystem: Bundle.appIdentifier, category: "History")

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
            Task { await self.fetchData() }
        }
    }

    //MARK: - Functions

    func setupViews() {
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        self.setupHomeButton()

        let image = loadAssetImage(named: "baseline_history_toggle_off_white_24pt")
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(historyButtonPressed(sender:)))
        navigationItem.rightBarButtonItems?.append(button)
    }

    @MainActor
    func fetchData() async {
        guard let account = App.account,
              let authtoken = account.authtoken else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }

        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        do {
            let objList = try await ActorService.fetchCheckoutHistory(authtoken: authtoken)
            self.items = HistoryRecord.makeArray(objList)
            self.fetchCircDetails()
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()
    }

    func fetchCircDetails() {
        var promises: [Promise<Void>] = []
        for item in items {
            let targetCopy = item.targetCopy
            assert(targetCopy != -1, "no target copy")
            let req = Gateway.makeRequest(service: API.search, method: API.modsFromCopy, args: [targetCopy], shouldCache: true)
            let promise = req.gatewayObjectResponse().done { obj in
                let id = obj.getInt("doc_id") ?? -1
                item.metabibRecord = MBRecord(id: id, mvrObj: obj)
                os_log("id=%d t=%d mods done (%@)", log: self.log, type: .info, item.id, item.targetCopy, item.title)
            }
            promises.append(promise)
        }
        let start = Date()
        os_log("%d promises made", log: self.log, type: .info, promises.count)

        firstly {
            when(resolved: promises)
        }.done { results in
            let elapsed = -start.timeIntervalSinceNow
            os_log("%d promises done, elapsed: %.3f", log: self.log, type: .info, promises.count, elapsed)
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forResults: results)
            self.didCompleteFetch = true
            self.reloadData()
        }
    }

    func reloadData() {
        tableView.reloadData()
    }

    func deleteHistoryItem(authtoken: String, userID: Int, id: Int) {
        self.showAlert(title: "WIP", message: "not implemented")
    }

    @objc func historyButtonPressed(sender: Any) {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }

        // prompt to disable history
        let alertController = UIAlertController(title: "Disable checkout history?", message: "Disabling checkout history will permanently remove all items from your history.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Disable history", style: .destructive) { action in
            Task { await self.disableCheckoutHistory(account: account) }
        })
        self.present(alertController, animated: true)
    }

    @MainActor
    func disableCheckoutHistory(account: Account) async {
        do {
            try await App.serviceConfig.userService.disableCheckoutHistory(account: account)
            try await App.serviceConfig.userService.clearCheckoutHistory(account: account)
            self.navigationController?.popViewController(animated: true)
        } catch {
            self.presentGatewayAlert(forError: error)
        }
    }

    //MARK: - UITableViewController

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !didCompleteFetch {
            return ""
        }
        var message = ""
        if items.count == 0 {
            message = "No items checked out"
        } else {
            message = "\(items.count) items checked out"
        }
        if let start = App.account?.userSettingCircHistoryStart {
            message += " since \(start)"
        }
        return message
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Style.tableHeaderHeight
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        guard let account = App.account,
              let authtoken = account.authtoken,
              let userID = account.userID else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }

        let item = items[indexPath.row]

        // confirm action
        let alertController = UIAlertController(title: "Delete history item?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deleteHistoryItem(authtoken: authtoken, userID: userID, id: item.id)
        })
        self.present(alertController, animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as? HistoryTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        //TODO: async loading a la ResultsViewController

        let item = items[indexPath.row]
        cell.title.text = item.title
        cell.author.text = item.author
        cell.checkoutDate.text = "Checkout Date: \(item.checkoutDateLabel)"
        cell.returnDate.text = "Returned Date: \(item.returnedDateLabel)"

        // async load the image
        if let url = URL(string: App.config.url + "/opac/extras/ac/jacket/small/r/" + String(item.metabibRecord?.id ?? 0)) {
            cell.coverImage.pin_setImage(from: url)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)
        var records: [MBRecord] = []
        for item in items {
            if let record = item.metabibRecord {
                records.append(record)
            }
        }
        if let vc = XUtils.makeDetailsPager(items: records, selectedItem: indexPath.row, displayOptions: displayOptions) {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
