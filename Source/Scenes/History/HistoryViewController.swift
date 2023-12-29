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
            self.fetchData()
        }
    }

    //MARK: - Functions

    func setupViews() {
        // create and style the activity indicator
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)

        self.setupHomeButton()
        //navigationItem.rightBarButtonItems?.append(editButtonItem)
    }

    func fetchData() {
        guard let account = App.account,
              let authtoken = account.authtoken else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }

        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        // fetch history
        ActorService.fetchCheckoutHistory(authtoken: authtoken).done { array in
            self.didCompleteFetch = true
            self.updateItems(objList: array)
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error, title: "Error retrieving messages")
        }
    }

    func updateItems(objList: [OSRFObject]) {
        items = HistoryRecord.makeArray(objList)
        tableView.reloadData()
    }

    func deleteHistoryItem(authtoken: String, userID: Int, id: Int) {
        self.showAlert(title: "WIP", message: "not implemented")
    }

    //MARK: - UITableViewController

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !didCompleteFetch {
            return ""
        } else if items.count == 0 {
            return "No history"
        } else {
            return "\(items.count) items"
        }
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

        let item = items[indexPath.row]
        cell.title.text = String(item.id)

        return cell
    }

//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let item = items[indexPath.row]
//        //TODO
//    }
}
