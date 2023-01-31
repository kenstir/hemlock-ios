/*
 * Copyright (c) 2023 Kenneth H. Cox
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

class MessagesViewController : UITableViewController {

    weak var activityIndicator: UIActivityIndicatorView!
    
    var items: [PatronMessage] = []
    var didCompleteFetch = false
    let log = OSLog(subsystem: Bundle.appIdentifier, category: "Messages")
    
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
        
        self.setupHomeButton()
        navigationItem.rightBarButtonItems?.append(editButtonItem)
    }

    func fetchData() {
        guard let account = App.account,
              let authtoken = account.authtoken,
              let userID = account.userID else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired)
            return //TODO: add analytics
        }

        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        // fetch messages
        ActorService.fetchMessages(authtoken: authtoken, userID: userID).done { array in
            self.didCompleteFetch = true
            self.updateItems(messageList: array)
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.activityIndicator.stopAnimating()
            self.presentGatewayAlert(forError: error, title: "Error retrieving messages")
        }
    }

    func updateItems(messageList: [OSRFObject]) {
        let messages = PatronMessage.makeArray(messageList)
        items = messages.filter { $0.isPatronVisible && !$0.isDeleted }
        tableView.reloadData()
    }

    func markMessageDeleted(authtoken: String, message: PatronMessage) {
        ActorService.markMessageDeleted(authtoken: authtoken, messageID: message.id).done {
            self.fetchData()
        }.catch { error in
            self.presentGatewayAlert(forError: error, title: "Error deleting message")
        }
    }

    //MARK: - UITableViewController

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !didCompleteFetch {
            return ""
        } else if items.count == 0 {
            return "No messages"
        } else {
            return "\(items.count) messages"
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
        let alertController = UIAlertController(title: "Delete message?", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { action in
            self.markMessageDeleted(authtoken: authtoken, message: item)
        })
        self.present(alertController, animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "messagesCell", for: indexPath) as? MessagesTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        let item = items[indexPath.row]
        cell.title.text = item.title
        cell.date.text = item.createDateLabel
        cell.body.text = item.message.trim()

        if item.isRead {
            cell.title.font = UIFont.systemFont(ofSize: Style.headlineSize)
            cell.title.textColor = Style.secondaryLabelColor
        } else {
            cell.title.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.title.textColor = Style.labelColor
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        if let vc = UIStoryboard(name: "MessageDetails", bundle: nil).instantiateInitialViewController() as? MessageDetailsViewController {
            vc.message = item
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
