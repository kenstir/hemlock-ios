/*
 *  Copyright (C) 2024 Kenneth H. Cox
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

import UIKit
import os.log

@available(iOS 14.0, *)
class MainGridViewController: MainBaseViewController {

    //MARK: - fields

    @IBOutlet weak var accountButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!

    var mainButtons: [ButtonAction] = []
    var secondaryButtons: [ButtonAction] = []
    var buttonItems: [[ButtonAction]] = []
    var didFetchHomeOrgSettings = false

    private let reuseIdentifier = "mainGridCell"
    private let sectionInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    private let mainButtonsPerRow: CGFloat = 2
    private let secondaryButtonsPerRow: CGFloat = 3
    private let log = OSLog(subsystem: Bundle.appIdentifier, category: "Main")

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - UI Setup

    func setupViews() {
        navigationItem.title = App.config.title
        collectionView.dataSource = self
        collectionView.delegate = self
        accountButton.target = self
        accountButton.action = #selector(accountButtonPressed(sender:))
        Style.styleBarButton(accountButton)
    }

    //MARK: - Async Functions

    func fetchData() {
        if App.config.enableEventsButton {
            fetchHomeOrgSettings()
        } else {
            loadButtons(forOrg: nil)
        }
    }

    func fetchHomeOrgSettings() {
        if didFetchHomeOrgSettings { return }
        guard let orgID = App.account?.homeOrgID else { return }
        let promise = ActorService.fetchOrgTreeAndSettings(forOrgID: orgID)
        promise.done {
            self.didFetchHomeOrgSettings = true
            let org = Organization.find(byId: orgID)
            self.loadButtons(forOrg: org)
            self.collectionView.reloadData()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func loadButtons(forOrg org: Organization?) {
//        let defaultButtonUrl: String? = "https://google.com" // cause all buttons to show up in debug
        let defaultButtonUrl: String? = nil

        // main buttons
        mainButtons.append(ButtonAction(title: "Digital Library Card", iconName: "library card", handler: {
            self.pushVC(fromStoryboard: "ShowCard")
        }))
        mainButtons.append(ButtonAction(title: "Search Catalog", iconName: "search", handler: {
            self.pushVC(fromStoryboard: "Search")
        }))
        mainButtons.append(ButtonAction(title: "Library Hours & Info", iconName: "info", handler: {
            self.pushVC(fromStoryboard: "OrgDetails")
        }))
        mainButtons.append(ButtonAction(title: "Items Checked Out", iconName: "checkouts", handler: {
            self.pushVC(fromStoryboard: "Checkouts")
        }))
        mainButtons.append(ButtonAction(title: "Fines", iconName: "fines", handler: {
            self.pushVC(fromStoryboard: "Fines")
        }))
        mainButtons.append(ButtonAction(title: "Holds", iconName: "holds", handler: {
            self.pushVC(fromStoryboard: "Holds")
        }))
        mainButtons.append(ButtonAction(title: "My Lists", iconName: "lists", handler: {
            self.pushVC(fromStoryboard: "BookBags")
        }))
        if let url = org?.eventsURL ?? defaultButtonUrl {
            mainButtons.append(ButtonAction(title: "Events", iconName: "events", handler: {
                self.launchURL(url: url)
            }))
        }

        // secondary buttons
        if let url = org?.eresourcesURL ?? defaultButtonUrl {
            secondaryButtons.append(ButtonAction(title: "Ebooks & Digital", iconName: "ebooks", handler: {
                self.launchURL(url: url)
            }))
        }
        if let url = org?.meetingRoomsURL ?? defaultButtonUrl {
            secondaryButtons.append(ButtonAction(title: "Meeting Rooms", iconName: "meeting rooms", handler: {
                self.launchURL(url: url)
            }))
        }
        if let url = org?.museumPassesURL ?? defaultButtonUrl {
            secondaryButtons.append(ButtonAction(title: "Museum Passes", iconName: "museum passes", handler: {
                self.launchURL(url: url)
            }))
        }

        // combine them to simplify delegate funcs
        buttonItems = [mainButtons, secondaryButtons]
    }

    //MARK: - Callback Functions

    @objc override func applicationDidBecomeActive() {
        os_log("didBecomeActive", log: log)
    }
}

//MARK: - UICollectionViewDataSource
@available(iOS 14.0, *)
extension MainGridViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return buttonItems.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttonItems[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? MainGridViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        // format the cell like a uitableviewcell
        cell.backgroundConfiguration = .listGroupedCell()

        let item = buttonItems[indexPath.section][indexPath.row]
        cell.title.text = item.title
        cell.title.numberOfLines = (indexPath.section == 0) ? 1 : 2
        cell.title.font = (indexPath.section == 0) ? UIFont.preferredFont(forTextStyle: .body) : UIFont.preferredFont(forTextStyle: .callout)
        cell.image.image = loadAssetImage(named: item.iconName)

        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
@available(iOS 14.0, *)
extension MainGridViewController: UICollectionViewDelegateFlowLayout {
    private func buttonSize(forSection section: Int) -> CGSize {
        let itemsPerRow: CGFloat = (section == 0) ? mainButtonsPerRow : secondaryButtonsPerRow
        let aspectRatio: CGFloat = (section == 0) ? (1.6 / 1.0) : (1.0 / 1.0)

        // calculate the size of the buttons
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem / aspectRatio)
    }

    /// NB: Calculate the size based on how many itemsPerRow we WANT to show
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return buttonSize(forSection: indexPath.section)
    }

    /// NB: Calculate the insets base on how many items we are ACTUALLY showing
    /// In the case of secondary buttons this might be fewer than secondaryButtonsPerRow.
    /// That is, we want to size the secondary buttons as if there are 3 per row,
    /// but we want to center them even if there is only 1 visible.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return sectionInsets
        }

        let itemSize = buttonSize(forSection: section)

        let numItems = CGFloat(secondaryButtons.count)
        let usedItemsWidth = itemSize.width * numItems + sectionInsets.left * (numItems - 1)
        let unusedWidth = view.frame.width - usedItemsWidth
        let insets = UIEdgeInsets(top: sectionInsets.top, left: unusedWidth / 2.0, bottom: sectionInsets.bottom, right: unusedWidth / 2.0)
        return insets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

//MARK: - UICollectionViewDelegate
@available(iOS 14.0, *)
extension MainGridViewController: UICollectionViewDelegate {
    private func deselectAllItems(_ collectionView: UICollectionView) {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return }
        for indexPath in selectedItems { collectionView.deselectItem(at: indexPath, animated: true) }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deselectAllItems(collectionView)
        let item = buttonItems[indexPath.section][indexPath.row]
        item.handler()
    }
}
