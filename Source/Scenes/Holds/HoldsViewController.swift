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
import os.log

class HoldsViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var holdsTable: UITableView!
    weak var activityIndicator: UIActivityIndicatorView!

    var items: [HoldRecord] = []
    var didCompleteFetch = false
    let log = OSLog(subsystem: Bundle.appIdentifier, category: "Holds")

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !didCompleteFetch {
            Task { await fetchData() }
        }
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

    @MainActor
    func fetchData() async {
        guard let account = App.account else { return }

        let startOfFetch = Date()

        activityIndicator.startAnimating()

        do {
            items = try await App.serviceConfig.circService.fetchHolds(account: account)
            try await loadHoldDetails(account: account)

            self.didCompleteFetch = true
            self.updateItems()
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()

        let elapsed = -startOfFetch.timeIntervalSinceNow
        os_log("fetch.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
    }

    func loadHoldDetails(account: Account) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for hold in self.items {
                group.addTask {
                    try await App.serviceConfig.circService.loadHoldDetails(account: account, hold: hold)
                }
            }
            try await group.waitForAll()
        }
    }

    func updateItems() {
        self.didCompleteFetch = true
        os_log("updateItems %d items", log: self.log, type: .info, items.count)
        holdsTable.reloadData()
    }

    func showDetails(_ indexPath: IndexPath) {
        guard let hold = getItem(indexPath) else { return }
        let displayOptions = RecordDisplayOptions(enablePlaceHold: false, orgShortName: nil)
        if let record = hold.record,
           let vc = XUtils.makeDetailsPager(items: [record], selectedItem: 0, displayOptions: displayOptions) {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func editHold(_ indexPath: IndexPath) {
        guard let hold = getItem(indexPath) else { return }
        guard let record = hold.record else { return }
        guard let vc = PlaceHoldViewController.make(record: record, holdRecord: hold, valueChangedHandler: { self.didCompleteFetch = false }) else { return }
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func cancelHoldPressed(_ indexPath: IndexPath) {
        guard let hold = getItem(indexPath) else { return }
        guard let account = App.account else { return }

        // confirm action
        let alertController = UIAlertController(title: "Cancel hold?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Keep Hold", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Cancel Hold", style: .default) { action in
            Task { await self.cancelHold(account: account, holdID: hold.id) }
        })
        self.present(alertController, animated: true)
    }

    @MainActor
    func cancelHold(account: Account, holdID: Int) async {
        do {
            let _ = try await App.serviceConfig.circService.cancelHold(account: account, holdId: holdID)
            self.logCancelHold()
            self.navigationController?.view.makeToast("Hold cancelled")
            self.didCompleteFetch = false
            await self.fetchData()
        } catch {
            self.logCancelHold(withError: error)
            self.presentGatewayAlert(forError: error)
        }
    }

    private func logCancelHold(withError error: Error? = nil) {
        var eventParams: [String: Any] = [:]
        if let err = error {
            eventParams[Analytics.Param.result] = err.localizedDescription
        } else {
            eventParams[Analytics.Param.result] = Analytics.Value.ok
        }
        Analytics.logEvent(event: Analytics.Event.cancelHold, parameters: eventParams)
    }

    func getItem(_ indexPath: IndexPath) -> HoldRecord? {
        guard indexPath.row >= 0 && indexPath.row < items.count else { return nil }
        return items[indexPath.row]
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "holdsCell", for: indexPath) as? HoldsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        guard let item = getItem(indexPath) else { return cell }

        cell.holdsTitleLabel.text = item.title
        cell.holdsAuthorLabel.text = item.author
        cell.holdsFormatLabel.text = item.format
        cell.holdsStatusLabel.text = item.status

        return cell
    }
}

extension HoldsViewController: UITableViewDelegate {

    //MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // build an action sheet to display the options
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)
        alertController.addAction(UIAlertAction(title: "Cancel Hold", style: .destructive) { action in
            self.cancelHoldPressed(indexPath)
        })
        alertController.addAction(UIAlertAction(title: "Edit Hold", style: .default) { action in
            self.editHold(indexPath)
        })
        alertController.addAction(UIAlertAction(title: "Show Details", style: .default) { action in
            self.showDetails(indexPath)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad requires a popoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            var view: UIView = self.view
            if let cell = tableView.cellForRow(at: indexPath) {
                view = cell.contentView
            }
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        self.present(alertController, animated: true) {
            // deselect row
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
