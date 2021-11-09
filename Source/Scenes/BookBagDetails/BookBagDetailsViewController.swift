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
    var items: [BookBagItem] = []
//    var didCompleteFetch = false
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

        self.fetchData()
//        if let items = bookBag?.items {
//            self.items = items
//        }
    }

    //MARK: - Functions
    
    func setupViews() {
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        self.setupHomeButton()
        navigationItem.rightBarButtonItems?.append(editButtonItem)
    }
    
    func fetchData() {
//        guard let account = App.account else
//        {
//            presentGatewayAlert(forError: HemlockError.sessionExpired)
//            return //TODO: add analytics
//        }
        
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
        let promise = req.gatewayObjectResponse().done { obj in
            item.metabibRecord = MBRecord(id: item.targetId, mvrObj: obj)
        }
        return promise
    }
    
    func updateItems() {
        if let items = bookBag?.items {
            self.items = items
            tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return bookBag?.name
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Style.tableHeaderHeight
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        print("delete row \(indexPath.row)")
        print("stop here")
        self.showAlert(title: "TODO", message: "Not implemented yet")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookBagDetailsCell", for: indexPath) as? BookBagDetailsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        let item = items[indexPath.row]
        cell.title.text = item.metabibRecord?.title
        cell.author.text = item.metabibRecord?.author
        cell.format.text = item.metabibRecord?.iconFormatLabel

        return cell
    }
}
