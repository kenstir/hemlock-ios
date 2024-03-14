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

class TestGridViewController: UIViewController {

    //MARK: - fields

    @IBOutlet weak var collectionView: UICollectionView!

    var mainButtons: [ButtonAction] = []
    var secondaryButtons: [ButtonAction] = []
    var buttonItems: [[ButtonAction]] = []

    private let reuseIdentifier = "mainGridCell"
    private let sectionInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    private let mainButtonsPerRow: CGFloat = 2
    private let secondaryButtonsPerRow: CGFloat = 3

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    //MARK: - Functions

    func setupViews() {
        collectionView.dataSource = self
        collectionView.delegate = self
        setupButtons()
    }

    func setupButtons() {
        mainButtons.append(ButtonAction(title: "Digital Library Card", iconName: "library card", handler: {
            print("stop here")
        }))
        mainButtons.append(ButtonAction(title: "Search Catalog", iconName: "search", handler: {
            print("stop here")
        }))
        mainButtons.append(ButtonAction(title: "Library Hours & Info", iconName: "info", handler: {
            print("stop here")
        }))
        mainButtons.append(ButtonAction(title: "Items Checked Out", iconName: "checkouts", handler: {
            print("stop here")
        }))
        mainButtons.append(ButtonAction(title: "Fines", iconName: "fines", handler: {
            print("stop here")
        }))
        mainButtons.append(ButtonAction(title: "Holds", iconName: "holds", handler: {
            print("stop here")
        }))
        mainButtons.append(ButtonAction(title: "My Lists", iconName: "lists", handler: {
            print("stop here")
        }))
        mainButtons.append(ButtonAction(title: "Events", iconName: "events", handler: {
            print("stop here")
        }))

        secondaryButtons.append(ButtonAction(title: "Ebooks & Digital", iconName: "ebooks", handler: {
            print("stop here")
        }))
        secondaryButtons.append(ButtonAction(title: "Meeting Rooms", iconName: "meeting rooms", handler: {
            print("stop here")
        }))
        secondaryButtons.append(ButtonAction(title: "Museum Passes", iconName: "museum passes", handler: {
            print("stop here")
        }))

        buttonItems = [mainButtons, secondaryButtons]
    }
}

//MARK: - UICollectionViewDataSource
extension TestGridViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return buttonItems.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttonItems[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? TestGridViewCell else {
            fatalError("dequeued cell of wrong class!")
        }

        let item = buttonItems[indexPath.section][indexPath.row]
        cell.backgroundColor = Style.secondarySystemGroupedBackground
        cell.layer.cornerRadius = 5
        cell.title.text = item.title
        cell.image.image = loadAssetImage(named: item.iconName)

        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension TestGridViewController: UICollectionViewDelegateFlowLayout {
    /// NB: Calculate the size based on how many items per row we want to show: 2 for main buttons, 3 for secondary buttons
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let itemsPerRow: CGFloat = (indexPath.section == 0) ? mainButtonsPerRow : secondaryButtonsPerRow
        let aspectRatio: CGFloat = 1.6 / 1.0

        // calculate the size of the buttons
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem / aspectRatio)
    }

    /// NB: Calculate the insets base on how many items we are actually showing, which in the
    /// case of secondary buttons might be fewer than secondaryButtonsPerRow.
    /// That is, we want to size the secondary buttons as if there are 3 per row,
    /// but we want to center them even if there is only 1 visible.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return sectionInsets
        }

        let itemsPerRow: CGFloat = secondaryButtonsPerRow
        let aspectRatio: CGFloat = 1.6 / 1.0

        // calculate the size of the buttons
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

        let numItems = CGFloat(secondaryButtons.count)
        let usedItemsWidth = widthPerItem * numItems + sectionInsets.left * (numItems - 1)
        let unusedWidth = view.frame.width - usedItemsWidth
        let insets = UIEdgeInsets(top: sectionInsets.top, left: unusedWidth / 2.0, bottom: sectionInsets.bottom, right: unusedWidth / 2.0)
        return insets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

//MARK: - UICollectionViewDelegate
extension TestGridViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = buttonItems[indexPath.section][indexPath.row]
        print("item \(item.title) selected")
        item.handler()
    }
}
