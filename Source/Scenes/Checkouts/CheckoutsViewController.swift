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
            Task { await self.fetchData() }
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

    @MainActor
    func fetchData() async {
        guard let account = App.account else { return }

        centerSubview(activityIndicator)
        activityIndicator.startAnimating()
        let startOfFetch = Date()

        do {
            let checkouts = try await App.serviceConfig.circService.fetchCheckouts(account: account)

            try await withThrowingTaskGroup(of: Void.self) { group in
                for circRecord in checkouts {
                    group.addTask {
                        try await App.serviceConfig.circService.loadCheckoutDetails(account: account, circRecord: circRecord)
                    }
                }
                try await group.waitForAll()
            }
            let elapsed = -startOfFetch.timeIntervalSinceNow
            os_log("%d circ records loaded, elapsed: %.3f", log: self.log, type: .info, checkouts.count, elapsed)

            self.didCompleteFetch = true
            self.updateItems(withRecords: checkouts)
        } catch {
            presentGatewayAlert(forError: error, title: "Error fetching checkouts")
        }

        activityIndicator.stopAnimating()
    }
    
    func updateItems(withRecords records: [CircRecord]) {
        self.items = records
        sortList()
        print("xxx \(records.count) records now, time to reloadData")
        tableView.reloadData()
    }

    @objc func renewPressed(sender: UIButton) {
        let item = items[sender.tag]
        guard let account = App.account else {
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
            Task { await self.renewItem(account: account, targetCopy: targetCopy) }
        })
        self.present(alertController, animated: true)
    }

    @MainActor
    func renewItem(account: Account, targetCopy: Int) async {

        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        do {
            let _ = try await App.serviceConfig.circService.renewCheckout(account: account, targetCopy: targetCopy)

            self.navigationController?.view.makeToast("Item renewed")
            Task { await self.fetchData() }
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()
    }

    func sortList() {
        items.sort() {
            guard let a = $0.dueDate, let b = $1.dueDate else { return false }
            return a < b
        }
        //redundant tableView.reloadData()
    }

    func dueDateText(_ item: CircRecord) -> NSAttributedString {
        let baseText = "Due \(item.dueDateLabel) "
        var captionText = ""
        var foregroundColor = Style.secondaryLabelColor
        var wantBold = false
        var attrs: [NSAttributedString.Key: Any] = [:]
        if item.isOverdue {
            captionText = "(overdue)"
            foregroundColor = App.theme.alertTextColor
            wantBold = true
        }
        else if item.isDueSoon {
            if item.autoRenewals > 0 {
                captionText = "(may auto-renew)"
            }
            foregroundColor = App.theme.warningTextColor
            wantBold = true
        }
        else if item.wasAutoRenewed {
            captionText = "(item was auto-renewed)"
        }
        if wantBold,
           let boldFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote).withSymbolicTraits(.traitBold) {
            attrs[.font] = UIFont(descriptor: boldFontDescriptor, size: 0.0)
        } else {
            attrs[.font] = UIFont.preferredFont(forTextStyle: .footnote)
        }
        attrs[.foregroundColor] = foregroundColor
        let str = NSMutableAttributedString(string: baseText + captionText, attributes: attrs)
        if captionText.count > 0 {
            str.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .caption1), range: NSRange(location: baseText.count, length: captionText.count))
        }
        return str
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
            Task { await self.enableCheckoutHistory(account: account) }
        })
        self.present(alertController, animated: true)
    }

    @MainActor
    func enableCheckoutHistory(account: Account) async {
        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        do {
            try await App.serviceConfig.userService.enableCheckoutHistory(account: account)
            self.showAlert(title: "Success", message: "Items you check out from now on will appear in your history.")
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()
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
        cell.dueDate.attributedText = dueDateText(item)

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
