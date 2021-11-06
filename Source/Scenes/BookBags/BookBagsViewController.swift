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
        //tableView.dataSource = self
        //tableView.delegate = self
        
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        self.setupHomeButton()
        navigationItem.rightBarButtonItems?.append(editButtonItem)
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
            os_log("done with %d bookbags", log: self.log, type: .info, account.bookBags.count)
            self.updateItems()
        }.catch { error in
            self.presentGatewayAlert(forError: error, title: "Error fetching lists")
        }.finally {
            self.activityIndicator.stopAnimating()
            self.didCompleteFetch = true
        }
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
}
