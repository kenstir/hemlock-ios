/*
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
import os.log

struct ButtonAction {
    let title: String
    let iconName: String
    let handler: (() -> Void)
}

class MainListViewController: MainBaseViewController {

    //MARK: - fields

    @IBOutlet weak var accountButton: UIBarButtonItem!
    @IBOutlet weak var messagesButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var bottomButtonBar: UIStackView!
    @IBOutlet weak var fullCatalogButton: UIButton!
    @IBOutlet weak var libraryLocatorButton: UIButton!
    @IBOutlet weak var galileoButton: UIButton!

    var buttons: [ButtonAction] = []
    var didFetchHomeOrgSettings = false
    let log = OSLog(subsystem: Bundle.appIdentifier, category: "Main")

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

        Task { await self.fetchData() }
    }

    //MARK: - Functions
    
    func setupButtons() {
        buttons.append(ButtonAction(title: "Search", iconName: "search", handler: {
            self.pushVC(fromStoryboard: "Search")
        }))
        buttons.append(ButtonAction(title: "Items Checked Out", iconName: "checkouts", handler: {
            self.pushVC(fromStoryboard: "Checkouts")
        }))
        buttons.append(ButtonAction(title: "Holds", iconName: "holds", handler: {
            self.pushVC(fromStoryboard: "Holds")
        }))
        buttons.append(ButtonAction(title: "Fines", iconName: "fines", handler: {
            self.pushVC(fromStoryboard: "Fines")
        }))
        buttons.append(ButtonAction(title: "My Lists", iconName: "lists", handler: {
            self.pushVC(fromStoryboard: "BookBags")
        }))
        buttons.append(ButtonAction(title: "Library Info", iconName: "info", handler: {
            self.pushVC(fromStoryboard: "OrgDetails")
        }))
        if App.config.barcodeFormat != .Disabled {
            buttons.append(ButtonAction(title: "Show Card", iconName: "library card") {
//                let numbers = [0] // Test Crash
//                let _ = numbers[1] // Test Crash
                self.pushVC(fromStoryboard: "ShowCard")
            })
        }
        // This was part of a failed experiment to integrate SwiftUI
//        buttons.append(ButtonAction(title: "My Lists", iconName: "My Lists", handler: {
//            guard let account = App.account else { return }
//            let vc = UIHostingController(rootView: BookBagsView(bookBags: account.bookBags))
//            self.navigationController?.pushViewController(vc, animated: true)
//        }))
        // Shortcut to Place Hold
//        buttons.append(ButtonAction("Place Hold", "holds", {
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
        // Shortcut to Search Results
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
            messagesButton.isEnabled = false
            messagesButton.isAccessibilityElement = false
        }
        messagesButton.accessibilityLabel = "Messages"
        accountButton.target = self
        accountButton.action = #selector(accountButtonPressed(sender:))
        accountButton.accessibilityLabel = "Accounts"
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

    @MainActor
    func fetchData() async {
        guard let account = App.account else { return }

        if App.config.enableMessages {
            await fetchMessages(account: account)
        }
        if App.config.enableEventsButton {
            await fetchHomeOrgSettings()
        }
    }

    @MainActor
    func fetchHomeOrgSettings() async {
        if didFetchHomeOrgSettings { return }
        guard let orgID = App.account?.homeOrgID else { return }

        do {
            try await App.svc.org.loadOrgSettings(forOrgID: orgID)
            didFetchHomeOrgSettings = true
            onHomeOrgSettingsLoaded(homeOrgID: orgID)
        } catch {
            self.presentGatewayAlert(forError: error)
        }
    }

    func onHomeOrgSettingsLoaded(homeOrgID orgID: Int) {
        if let org = App.svc.consortium.find(byID: orgID),
           let eventsURL = org.eventsURL,
           !eventsURL.isEmpty,
           let url = URL(string: eventsURL)
        {
            let index = self.buttons.index(before: self.buttons.endIndex)
            self.buttons.insert(ButtonAction(title: "Events", iconName: "events", handler: {
                UIApplication.shared.open(url)
            }), at: index)
            self.tableView.reloadData()
        }
    }

    @MainActor
    func fetchMessages(account: Account) async {

        do {
            let messages = try await App.svc.user.fetchPatronMessages(account: account)
            self.updateMessagesBadge(messages: messages)
        } catch {
            self.presentGatewayAlert(forError: error)
        }
    }

    func updateMessagesBadge(messages: [PatronMessage]) {
        let unreadCount = messages.filter { $0.isPatronVisible && !$0.isDeleted && !$0.isRead }.count
        messagesButton.setBadge(text: (unreadCount > 0) ? String(unreadCount) : nil)
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
        self.pushVC(fromStoryboard: "Messages")
    }

    @objc override func applicationDidBecomeActive() {
        os_log("didBecomeActive: fetchData", log: log)
        Task { await fetchData() }
    }

}

//MARK: - UITableViewDataSource
extension MainListViewController: UITableViewDataSource {
    
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

        let action = buttons[indexPath.row]
        var image: UIImage?
        if App.config.haveColorButtonImages {
            image = UIImage(named: action.iconName)?.withRenderingMode(.automatic)
        } else {
            image = UIImage(named: action.iconName)?.withRenderingMode(.alwaysTemplate)
            cell.tintColor = App.theme.mainButtonTintColor
        }
        cell.imageView?.image = image
        cell.textLabel?.text = R.getString(action.title)

        cell.title = action.title

        return cell
    }
}

//MARK: - UITableViewDelegate
extension MainListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = buttons[indexPath.row]
        action.handler()
    }
}
