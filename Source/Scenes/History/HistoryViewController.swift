//
//  Copyright (c) 2025 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import UIKit
import os.log

class HistoryViewController: UITableViewController {

    //MARK: - Properties

    weak var activityIndicator: UIActivityIndicatorView!

    var items: [HistoryRecord] = []
    var didCompleteFetch = false
    var startOfFetch = Date()
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
        button.accessibilityLabel = "Disable checkout history"
        navigationItem.rightBarButtonItems?.append(button)
    }

    @MainActor
    func fetchData() async {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }

        activityIndicator.startAnimating()
        startOfFetch = Date()

        do {
            self.items = try await App.svc.circ.fetchCheckoutHistory(account: account)
            Analytics.logEvent(event: Analytics.Event.historyLoad, parameters: [Analytics.Param.numItems: items.count])
            Task {
                await prefetchCircDetails()
                await MainActor.run { self.reloadData() }
            }
            self.didCompleteFetch = true
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()

        let elapsed = -startOfFetch.timeIntervalSinceNow
        os_log("history fetch.elapsed: %.3f", log: self.log, type: .info, elapsed)
    }

    @MainActor
    func prefetchCircDetails() async {
        // For now, we prefetch ALL details.  We do this because when you tap on a
        // history item, it goes to the details pager which needs the metabib record.
        // And we need a modsFromCopy request to get that.
        //let maxRecordsToPreload = 10 // best estimate is 9 on screen + 1 partial
        //let preloadItems = items.prefix(maxRecordsToPreload)
        let preloadItems = items

        let circService = App.svc.circ
        await withTaskGroup(of: Void.self) { group in
            for item in preloadItems {
                group.addTask {
                    try? await circService.loadHistoryDetails(historyRecord: item)
                }
            }
            await group.waitForAll()
        }
        let elapsed = -startOfFetch.timeIntervalSinceNow
        os_log("%d history records loaded, elapsed: %.3f", log: self.log, type: .info, preloadItems.count, elapsed)
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
            return
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
            try await App.svc.user.disableCheckoutHistory(account: account)
            try await App.svc.user.clearCheckoutHistory(account: account)
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
        if let start = App.account?.circHistoryStart {
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
        print("\(Utils.tt) row=\(String(format: "%2d", indexPath.row)) cellForRowAt")
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! HistoryTableViewCell
        guard items.count > indexPath.row else { return cell }
        let item = items[indexPath.row]

        // load the data immediately if we have it
        if item.record != nil {
            setCellMetadata(cell, forItem: item)
        } else {
            // Clear reused cells immediately or else the titles change as you scroll fast
            setCellMetadata(cell, forItem: nil)

            // async load the metadata
            Task {
                try? await App.svc.circ.loadHistoryDetails(historyRecord: item)
                await MainActor.run { self.setCellMetadata(cell, forItem: item) }
            }
        }

/*
        // async load the image
        // We cannot load the image here, because the bib record ID needs to be fetched
        if let url = URL(string: App.config.url + "/opac/extras/ac/jacket/small/r/" + String(item.metabibRecord?.id ?? -1)) {
            cell.coverImage.pin_setImage(from: url)
        }
*/
        return cell
    }

    func setCellMetadata(_ cell: HistoryTableViewCell, forItem item: HistoryRecord?) {
        print("\(Utils.tt) setCellMetadata for \(item?.title ?? "")")
        cell.title.text = item?.title
        cell.author.text = item?.author
        cell.checkoutDate.text = "Checkout Date: \(item?.checkoutDateLabel ?? "")"
        cell.returnDate.text = "Returned Date: \(item?.returnedDateLabel ?? "")"
        // async load the image
        if let recordId = item?.record?.id,
            let url = URL(string: App.config.url + "/opac/extras/ac/jacket/small/r/" + String(recordId)) {
            cell.coverImage.pin_setImage(from: url)
        } else {
            let url: URL? = nil
            cell.coverImage.pin_setImage(from: url)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)
        let records = items.compactMap { $0.record }
        if let vc = XUtils.makeDetailsPager(items: records, selectedItem: indexPath.row, displayOptions: displayOptions) {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
