/*
 *  MainViewController.swift
 *
 *  Copyright (C) 2018 Kenneth H. Cox
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

import Foundation
import UIKit
import PromiseKit
import PMKAlamofire
import SwiftUI

class MainViewController: UIViewController {
    
    //MARK: - fields

    @IBOutlet weak var accountButton: UIBarButtonItem!
    @IBOutlet weak var messagesButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var bottomButtonBar: UIStackView!
    @IBOutlet weak var fullCatalogButton: UIButton!
    @IBOutlet weak var libraryLocatorButton: UIButton!
    @IBOutlet weak var galileoButton: UIButton!


    var buttons: [(String, String, (() -> Void)?)] = []
    var didFetchEventsURL = false
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // deselect row when navigating back
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        
        self.fetchData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    //MARK: - Functions
    
    func setupButtons() {
        buttons = [
            ("Search", "ShowSearchSegue", nil),
            ("Items Checked Out", "ShowCheckoutsSegue", nil),
            ("Holds", "ShowHoldsSegue", nil),
            ("Fines", "ShowFinesSegue", nil),
            ("My Lists", "ShowBookBagsSegue", nil),
            ("Library Info", "ShowOrgDetailsSegue", nil),
        ]
// This was part of a failed experiment to integrate SwiftUI
//        if #available(iOS 14.0, *) {
//            buttons.append(("My Lists", "", {
//                guard let account = App.account else { return }
//                ActorService.fetchBookBags(account: account).done {
//                    let vc = UIHostingController(rootView: BookBagsView(bookBags: account.bookBags))
//                    self.navigationController?.pushViewController(vc, animated: true)
//                }.catch { error in
//                    self.presentGatewayAlert(forError: error)
//                }
//            }))
//        }
        if App.config.barcodeFormat != .Disabled {
            buttons.append(("Show Card", "ShowCardSegue", nil))
        }
//        buttons.append(("Place Hold", "", {
//            let record = MBRecord(id: 4674474, mvrObj: OSRFObject([
//                "doc_id": 4674474,
//                "tcn": 4674474,
//                "title": "Discipline is destiny : the power of self-control",
//                "author": "Holiday, Ryan"
//            ]))
//            record.attrs = ["icon_format": "book"]
//            if let vc = PlaceHoldViewController.make(record: record) {
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }))
//        buttons.append(("Prepared query", "", {
//            if let vc = UIStoryboard(name: "Results", bundle: nil).instantiateInitialViewController() as? ResultsViewController {
//                vc.searchParameters = SearchParameters(text: "Goblet of fire", searchClass: "keyword", searchFormat: nil, organizationShortName: nil, sort: nil)
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }))
    }

    func setupViews() {
        navigationItem.title = App.config.title
        tableView.dataSource = self
        tableView.delegate = self
        if App.config.enableMessages {
            messagesButton.target = self
            messagesButton.action = #selector(messagesButtonPressed(sender:))
        } else {
            //messagesButton.width = 0.01
            messagesButton.isEnabled = false
            messagesButton.isAccessibilityElement = false
        }
        accountButton.target = self
        accountButton.action = #selector(accountButtonPressed(sender:))
        Style.styleBarButton(accountButton)
        if App.config.enableMainSceneBottomToolbar {
            Style.styleButton(asPlain: fullCatalogButton)
            Style.styleButton(asPlain: libraryLocatorButton)
            Style.styleButton(asPlain: galileoButton)
        } else {
            bottomButtonBar.isHidden = true
            fullCatalogButton.isHidden = true
            libraryLocatorButton.isHidden = true
            galileoButton.isHidden = true
        }
    }
    
    func fetchData() {
        guard let authtoken = App.account?.authtoken,
              let userID = App.account?.userID else { return }

        if App.config.enableMessages {
            fetchMessages(authtoken: authtoken, userid: userID)
        }
        if App.config.enableEventsButton {
            fetchEventsURL()
        }
    }
    
    func fetchEventsURL() {
        if didFetchEventsURL { return }
        guard let orgID = App.account?.homeOrgID else { return }
        let promise = ActorService.fetchOrgTreeAndSettings(forOrgID: orgID)
        promise.done {
            self.didFetchEventsURL = true
            if let org = Organization.find(byId: orgID),
               let eventsURL = org.eventsURL,
               !eventsURL.isEmpty,
               let url = URL(string: eventsURL)
            {
                let index = self.buttons.index(before: self.buttons.endIndex)
                self.buttons.insert(("Events", "", {
                    UIApplication.shared.open(url)
                }), at: index)
                self.tableView.reloadData()
            }
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func fetchMessages(authtoken: String, userid: Int) {
        ActorService.fetchMessages(authtoken: authtoken, userID: userid).done { array in
            self.updateMessagesBadge(messageList: array)
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func updateMessagesBadge(messageList: [OSRFObject]) {
        let messages = PatronMessage.makeArray(messageList)
        let unreadCount = messages.filter { $0.isPatronVisible && !$0.isDeleted && !$0.isRead }.count
        messagesButton.setBadge(text: (unreadCount > 0) ? String(unreadCount) : nil)
    }
    
    @objc func accountButtonPressed(sender: UIBarButtonItem) {
        let haveMultipleAccounts = App.credentialManager.credentials.count > 1

        // Create an action sheet to present the account options
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        Style.styleAlertController(alertController)
        
        // Add an action for each stored account
        if haveMultipleAccounts {
            for credential in App.credentialManager.credentials {
                let action = UIAlertAction(title: credential.chooserLabel, style: .default) { action in
                    self.doSwitchAccount(toAccount: credential)
                }
                var imageName = "Account"
                if credential.username == App.account?.username {
                    action.isEnabled = false
                    imageName = "Account with Checkmark"
                }
                if let icon = loadAssetImage(named: imageName) {
                    action.setValue(icon, forKey: "image")
                }
                alertController.addAction(action)
            }
        }
        
        // Add remaining actions
        alertController.addAction(UIAlertAction(title: "Add account", style: .default) { action in
            self.doAddAccount()
        })
        alertController.addAction(UIAlertAction(title: "Logout", style: .destructive) { action in
            self.doLogout()
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad requires a popoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = sender
        }

        self.present(alertController, animated: true)
    }
    
    func doSwitchAccount(toAccount storedAccount: Credential) {
        App.switchCredential(credential: storedAccount)
        self.popToLogin()
    }
    
    func doAddAccount() {
        App.switchCredential(credential: nil)
        self.popToLogin()
    }
    
    func doLogout() {
        App.logout()
        self.popToLogin()
    }

    @IBAction func fullCatalogButtonPressed(_ sender: Any) {
        if let libraryURL = App.library?.url,
            let url = URL(string: libraryURL) {
             UIApplication.shared.open(url)
        }
    }
    
    @IBAction func libraryLocatorButtonPressed(_ sender: Any) {
        let uri = "http://pines.georgialibraries.org/pinesLocator/locator.html"
        if let url = URL(string: uri) {
            UIApplication.shared.open(url)
        }
    }

    @IBAction func galileoButtonPressed(_ sender: Any) {
        let uri = "https://www.galileo.usg.edu"
        if let url = URL(string: uri) {
            UIApplication.shared.open(url)
        }
    }

    @objc func messagesButtonPressed(sender: UIBarButtonItem) {
        if let vc = UIStoryboard(name: "Messages", bundle: nil).instantiateInitialViewController() as? MessagesViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func applicationDidBecomeActive() {
        fetchData()
    }

}

//MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttons.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return App.account?.displayName
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "mainCell", for: indexPath) as? MainTableViewCell else {
            fatalError("dequeued cell of wrong class!")
        }
        
        let tuple = buttons[indexPath.row]
        let label = tuple.0
        let segue = tuple.1
        
        var image: UIImage?
        if App.config.haveColorButtonImages {
            image = UIImage(named: label)?.withRenderingMode(.automatic)
        } else {
            image = UIImage(named: label)?.withRenderingMode(.alwaysTemplate)
            cell.tintColor = App.theme.mainButtonTintColor
        }
        cell.imageView?.image = image
        cell.textLabel?.text = R.getString(label)

        cell.title = label
        cell.segue = segue
        
        return cell
    }
}

//MARK: - UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tuple = buttons[indexPath.row]
        let segue = tuple.1
        if let actionFunc = tuple.2 {
            actionFunc()
        } else {
            self.performSegue(withIdentifier: segue, sender: nil)
        }
    }
}
