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

class BookBagDetailsViewController : UITableViewController {

    weak var activityIndicator: UIActivityIndicatorView!

    var bookBag: PatronList?
    var sortedItems: [ListItem] = []
    var sortBy: String = ""
    var sortDescending = false
    var sortOrderButton = UIBarButtonItem()

    let log = OSLog(subsystem: Bundle.appIdentifier, category: "BookBags")
    
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

        Task { await self.fetchData() }
    }

    //MARK: - Functions
    
    func setupViews() {
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        sortBy = AppState.string(forKey: AppState.Str.listSortBy) ?? "pubdate"
        sortDescending = AppState.bool(forKey: AppState.Boolean.listSortDesc) ?? true

        self.setupHomeButton()
        navigationItem.rightBarButtonItems?.append(editButtonItem)
        let sortDirectionImage = loadAssetImage(named: (sortDescending ? "arrow_downward" : "arrow_upward"))
        sortOrderButton = UIBarButtonItem(image: sortDirectionImage, style: .plain, target: self, action: #selector(sortOrderButtonPressed(sender:)))
        navigationItem.rightBarButtonItems?.append(sortOrderButton)
        let sortByImage = loadAssetImage(named: "sort")
        let sortButton = UIBarButtonItem(image: sortByImage, style: .plain, target: self, action: #selector(sortButtonPressed(sender:)))
        navigationItem.rightBarButtonItems?.append(sortButton)
    }

    @MainActor
    func fetchData() async {
        guard let account = App.account, let bookBag = self.bookBag else { return }

        activityIndicator.startAnimating()

        do {
            try await App.serviceConfig.userService.loadPatronListItems(account: account, patronList: bookBag)
            os_log("fetched %d items", log: self.log, type: .info, bookBag.items.count)

            try await withThrowingTaskGroup(of: Void.self) { group in
                for item in bookBag.items {
                    group.addTask {
                        try await self.loadItemDetails(forItem: item)
                    }
                }
                try await group.waitForAll()
            }

            self.updateItems()
        } catch {
            self.presentGatewayAlert(forError: error, title: "Error fetching lists")
        }

        activityIndicator.stopAnimating()
    }

    func loadItemDetails(forItem item: ListItem) async throws -> Void {
        try await App.serviceConfig.biblioService.loadRecordDetails(forRecord: item.record, needMARC: App.config.needMARCRecord)
    }

    @objc func sortButtonPressed(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Sort by", message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)
        alertController.addAction(UIAlertAction(title: "Author", style: .default) { action in
            self.setPreferredSortOrder("authorsort")
        })
        alertController.addAction(UIAlertAction(title: "Publication Date", style: .default) { action in
            self.setPreferredSortOrder("pubdate")
        })
        alertController.addAction(UIAlertAction(title: "Title", style: .default) { action in
            self.setPreferredSortOrder("titlesort")
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad requires a popoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            let view: UIView = sender.value(forKey: "view") as? UIView ?? self.view
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        self.present(alertController, animated: true)
    }
    
    func setPreferredSortOrder(_ sortBy: String) {
        self.sortBy = sortBy
        AppState.set(string: sortBy, forKey: AppState.Str.listSortBy)
        updateItems()
    }

    @objc func sortOrderButtonPressed(sender: UIBarButtonItem) {
        sortDescending = !sortDescending
        let sortDirectionImage = loadAssetImage(named: (sortDescending ? "arrow_downward" : "arrow_upward"))
        sortOrderButton.image = sortDirectionImage
        AppState.set(bool: sortDescending, forKey: AppState.Boolean.listSortDesc)
        updateItems()
    }

    func updateItems() {
        guard let items = bookBag?.items else { return }
        if (sortBy == "authorsort") {
            self.sortedItems = items.sorted(by: { authorSortComparator($0, $1, descending: sortDescending) })
        } else if (sortBy == "titlesort") {
            self.sortedItems = items.sorted(by: { titleSortComparator($0, $1, descending: sortDescending) })
        } else {
            self.sortedItems = items.sorted(by: { pubdateSortComparator($0, $1, descending: sortDescending) })
        }
//        print("[sort] \(sortBy) \(sortDescending ? "desc" : "asc"):")
//        for item in sortedItems {
//            if let record = item.metabibRecord {
//                print("[sort] \"\(record.titleSortKey)\" t \"\(record.title)\" id \(record.id)")
//            }
//        }
        tableView.reloadData()
    }

    func authorSortComparator(_ a: ListItem, _ b: ListItem, descending: Bool) -> Bool {
        if (descending) {
            return a.record.author > b.record.author
        } else {
            return a.record.author < b.record.author
        }
    }

    func titleSortComparator(_ a: ListItem, _ b: ListItem, descending: Bool) -> Bool {
        let akey = a.record.titleSortKey
        let bkey = b.record.titleSortKey
        let order = descending ? ComparisonResult.orderedDescending : ComparisonResult.orderedAscending
        return akey.compare(bkey, locale: .current) == order
    }

    func pubdateSortComparator(_ a: ListItem, _ b: ListItem, descending: Bool) -> Bool {
        if (descending) {
            return Utils.pubdateSortKey(a.record.pubdate) ?? 0 > Utils.pubdateSortKey(b.record.pubdate) ?? 0
        } else {
            return Utils.pubdateSortKey(a.record.pubdate) ?? 0 < Utils.pubdateSortKey(b.record.pubdate) ?? 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedItems.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return bookBag?.name
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Style.tableHeaderHeight
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        guard let account = App.account, let bookBag = self.bookBag else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }

        let item = sortedItems[indexPath.row]
        Task { await self.deleteItem(account: account, bookBag: bookBag, item: item) }
    }

    @MainActor
    func deleteItem(account: Account, bookBag: PatronList, item: ListItem) async {
        do {
            try await App.serviceConfig.userService.removeItemFromPatronList(account: account, listId: bookBag.id, itemId: item.id)
            Analytics.logEvent(event: Analytics.Event.bookbagDeleteItem, parameters: [Analytics.Param.result: Analytics.Value.ok])
            self.bookBag?.items.removeAll(where: { $0.id == item.id })
            self.updateItems()
        } catch {
            Analytics.logEvent(event: Analytics.Event.bookbagDeleteItem, parameters: [Analytics.Param.result: error.localizedDescription])
            self.presentGatewayAlert(forError: error)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookBagDetailsCell", for: indexPath) as? BookBagDetailsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        let item = sortedItems[indexPath.row]
        cell.title.text = item.record.title
        cell.author.text = item.record.author
        cell.format.text = item.record.iconFormatLabel

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var records: [BibRecord] = []
        for item in sortedItems {
            records.append(item.record)
        }

        if records.count > 0 {
            let displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)
            if let vc = XUtils.makeDetailsPager(items: records, selectedItem: indexPath.row, displayOptions: displayOptions) {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            // deselect row
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
