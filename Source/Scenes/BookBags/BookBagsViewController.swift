/*
 * BookBagsViewController.swift
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

class BookBagsViewController : UITableViewController {

    weak var activityIndicator: UIActivityIndicatorView!

    var items: [BookBag] = []
    var didCompleteFetch = false
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
        
        if !didCompleteFetch {
            self.fetchData()
        }
    }

    //MARK: - Functions
    
    func setupViews() {
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        self.setupHomeButton()
        navigationItem.rightBarButtonItems?.append(editButtonItem)
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed(sender:)))
        navigationItem.rightBarButtonItems?.append(addButton)
    }
    
    func fetchData() {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }
        
        centerSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // fetch the list of bookbags
        ActorService.fetchBookBags(account: account).done {
            os_log("fetched %d bookbags", log: self.log, type: .info, account.bookBags.count)
            //self.updateItems()
            self.fetchBookBagContents(account: account)
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error, title: "Error fetching lists")
        }
    }
    
    func fetchBookBagContents(account: Account) {
        let queryForVisibleItems = true // TODO: parameterize per app?
        var promises: [Promise<Void>] = []
        for bookBag in account.bookBags {
            promises.append(ActorService.fetchBookBagContents(account: account, bookBag: bookBag, queryForVisibleItems: queryForVisibleItems))
        }
        os_log("%d promises made", log: self.log, type: .info, promises.count)

        firstly {
            when(resolved: promises)
        }.done { results in
            os_log("%d promises done", log: self.log, type: .info, promises.count)
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forResults: results)
            self.didCompleteFetch = true
            self.updateItems()
        }
    }
    
    @objc func addButtonPressed(sender: UIBarButtonItem) {
        print("stop here")
        self.showAlert(title: "TODO", message: "Not implemented yet")
    }

    func updateItems() {
        if let items = App.account?.bookBags {
            self.items = items
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        print("delete row \(indexPath.row)")
        print("stop here")
        self.showAlert(title: "TODO", message: "Not implemented yet")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookBagsCell", for: indexPath) as? BookBagsTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let item = items[indexPath.row]
        cell.title.text = item.name
        cell.subtitle.text = item.description
        cell.detail.text = "\(item.items.count) items"

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        if let vc = UIStoryboard(name: "BookBagDetails", bundle: nil).instantiateInitialViewController() as? BookBagDetailsViewController {
            vc.bookBag = item
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
