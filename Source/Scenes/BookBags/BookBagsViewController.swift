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

        Task { await self.fetchData() }
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

    @MainActor
    func fetchData() async {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }
        
        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        do {
            try await App.serviceConfig.userService.loadPatronLists(account: account)
            os_log("fetched %d bookbags", log: self.log, type: .info, account.bookBags.count)

            try await withThrowingTaskGroup(of: Void.self) { group in
                for bookBag in account.bookBags {
                    group.addTask {
                        try await App.serviceConfig.userService.loadPatronListItems(account: account, patronList: bookBag)
                    }
                }
                try await group.waitForAll()
            }

            self.didCompleteFetch = true
            self.updateItems()
        } catch {
            self.presentGatewayAlert(forError: error, title: "Error fetching lists")
        }

        activityIndicator.stopAnimating()
    }

    @objc func addButtonPressed(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Create list", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = "List name"
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Create", style: .default) { action in
            if let listName = alertController.textFields?[0].text?.trim(),
               !listName.isEmpty {
                self.createBookBag(name: listName)
            }
        })
        self.present(alertController, animated: true)
    }
    
    func createBookBag(name: String) {
        guard let account = App.account,
              let authtoken = account.authtoken,
              let userID = account.userID else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }
        
        ActorService.createBookBag(authtoken: authtoken, userID: userID, name: name).done {
            self.navigationController?.view.makeToast("List created")
            Task { await self.fetchData() }
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func deleteBookBag(authtoken: String, bookBagId: Int, indexPath: IndexPath) {
        ActorService.deleteBookBag(authtoken: authtoken, bookBagId: bookBagId).done {
            App.account?.bookBags.remove(at: indexPath.row)
            self.updateItems()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !didCompleteFetch {
            return ""
        } else if items.count == 0 {
            return "No lists"
        } else {
            return "\(items.count) lists"
        }
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
            return
        }

        let item = items[indexPath.row]

        // confirm action
        let alertController = UIAlertController(title: "Delete list?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { action in
            self.deleteBookBag(authtoken: authtoken, bookBagId: item.id, indexPath: indexPath)
        })
        self.present(alertController, animated: true)
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
