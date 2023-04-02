/*
 * BookBagDetailsViewController.swift
 *
 * Copyright (C) 2021 Kenneth H. Cox
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import UIKit
import PromiseKit
import os.log

class BookBagDetailsViewController : UITableViewController {

    weak var activityIndicator: UIActivityIndicatorView!

    var bookBag: BookBag?
    var sortedItems: [BookBagItem] = []
    var sortBy: String = ""
    var sortDescending = false
    var sortOrderButton = UIBarButtonItem()

    static let log = OSLog(subsystem: Bundle.appIdentifier, category: "BookBags")
    
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
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        sortBy = App.valet.string(forKey: "sortBy") ?? "pubdate"
        sortDescending = ((App.valet.string(forKey: "sortDesc") ?? "t") == "t")

        self.setupHomeButton()
        navigationItem.rightBarButtonItems?.append(editButtonItem)
        let sortDirectionImage = loadAssetImage(named: (sortDescending ? "arrow_downward" : "arrow_upward"))
        sortOrderButton = UIBarButtonItem(image: sortDirectionImage, style: .plain, target: self, action: #selector(sortOrderButtonPressed(sender:)))
        navigationItem.rightBarButtonItems?.append(sortOrderButton)
        let sortByImage = loadAssetImage(named: "sort")
        let sortButton = UIBarButtonItem(image: sortByImage, style: .plain, target: self, action: #selector(sortButtonPressed(sender:)))
        navigationItem.rightBarButtonItems?.append(sortButton)
    }
    
    func fetchData() {
        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        // fetch the record details
        var promises: [Promise<Void>] = []
        if let items = bookBag?.items {
            for item in items {
                promises.append(fetchTargetDetails(forItem: item))
            }
        }
        
        // wait for them to be fulfilled
        firstly {
            when(fulfilled: promises)
        }.done {
            self.updateItems()
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    func fetchTargetDetails(forItem item: BookBagItem) -> Promise<Void> {
        let req = Gateway.makeRequest(service: API.search, method: API.recordModsRetrieve, args: [item.targetId], shouldCache: true)
        let promise = req.gatewayObjectResponse().then { (obj: OSRFObject) -> Promise<Void> in
            let record = MBRecord(id: item.targetId, mvrObj: obj)
            item.metabibRecord = record
            if App.config.needMARCRecord {
                return PCRUDService.fetchMARC(forRecord: record)
            } else {
                return Promise<Void>()
            }
        }.done {
        }
        return promise
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
        App.valet.set(string: sortBy, forKey: "sortBy")
        updateItems()
    }

    @objc func sortOrderButtonPressed(sender: UIBarButtonItem) {
        sortDescending = !sortDescending
        let sortDirectionImage = loadAssetImage(named: (sortDescending ? "arrow_downward" : "arrow_upward"))
        sortOrderButton.image = sortDirectionImage
        let val = (sortDescending ? "t" : "f")
        App.valet.set(string: val, forKey: "sortDesc")
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

    func authorSortComparator(_ a: BookBagItem, _ b: BookBagItem, descending: Bool) -> Bool {
        if (descending) {
            return a.metabibRecord?.author ?? "" > b.metabibRecord?.author ?? ""
        } else {
            return a.metabibRecord?.author ?? "" < b.metabibRecord?.author ?? ""
        }
    }

    func titleSortComparator(_ a: BookBagItem, _ b: BookBagItem, descending: Bool) -> Bool {
        let akey = a.metabibRecord?.titleSortKey ?? ""
        let bkey = b.metabibRecord?.titleSortKey ?? ""
        let order = descending ? ComparisonResult.orderedDescending : ComparisonResult.orderedAscending
        return akey.compare(bkey, locale: .current) == order
    }

    func pubdateSortComparator(_ a: BookBagItem, _ b: BookBagItem, descending: Bool) -> Bool {
        if (descending) {
            return Utils.pubdateSortKey(a.metabibRecord?.pubdate) ?? 0 > Utils.pubdateSortKey(b.metabibRecord?.pubdate) ?? 0
        } else {
            return Utils.pubdateSortKey(a.metabibRecord?.pubdate) ?? 0 < Utils.pubdateSortKey(b.metabibRecord?.pubdate) ?? 0
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
        guard let account = App.account,
              let authtoken = account.authtoken else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }

        let item = sortedItems[indexPath.row]
        ActorService.removeItemFromBookBag(authtoken: authtoken, bookBagItemId: item.id).done {
            self.bookBag?.items.removeAll(where: { $0.id == item.id })
            self.updateItems()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookBagDetailsCell", for: indexPath) as? BookBagDetailsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        let item = sortedItems[indexPath.row]
        cell.title.text = item.metabibRecord?.title
        cell.author.text = item.metabibRecord?.author
        cell.format.text = item.metabibRecord?.iconFormatLabel

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var records: [MBRecord] = []
        for item in sortedItems {
            if let record = item.metabibRecord {
                records.append(record)
            }
        }

        if records.count > 0 {
            let displayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)
            let vc = DetailsPagerViewController.make(items: records, selectedItem: indexPath.row, displayOptions: displayOptions)
            self.navigationController?.pushViewController(vc!, animated: true)
        } else {
            // deselect row
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
