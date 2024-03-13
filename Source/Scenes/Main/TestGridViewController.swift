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
    var bottomButtons: [ButtonAction] = []

    private let reuseIdentifier = "mainGridCell"
    private let mainSectionInsets = UIEdgeInsets(top: 32.0, left: 16.0, bottom: 32.0, right: 16.0)
    private let bottomSectionInsets = UIEdgeInsets(top: 32.0, left: 48.0, bottom: 32.0, right: 48.0)
    private let mainButtonsPerRow: CGFloat = 2

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
        }))
        mainButtons.append(ButtonAction(title: "Search Catalog", iconName: "search", handler: {
        }))
        mainButtons.append(ButtonAction(title: "Library Hours & Info", iconName: "info", handler: {}))
        mainButtons.append(ButtonAction(title: "Items Checked Out", iconName: "checkouts", handler: {}))
        mainButtons.append(ButtonAction(title: "Fines", iconName: "fines", handler: {}))
        mainButtons.append(ButtonAction(title: "Holds", iconName: "holds", handler: {}))
        mainButtons.append(ButtonAction(title: "My Lists", iconName: "lists", handler: {}))
        mainButtons.append(ButtonAction(title: "Events", iconName: "events", handler: {}))

        bottomButtons.append(ButtonAction(title: "Ebooks & Digital", iconName: "ebooks", handler: {}))
        bottomButtons.append(ButtonAction(title: "Meeting Rooms", iconName: "meeting rooms", handler: {}))
        bottomButtons.append(ButtonAction(title: "Museum Passes", iconName: "museum passes", handler: {}))
    }
}

//MARK: - UICollectionViewDataSource
extension TestGridViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (section == 0) ? mainButtons.count : bottomButtons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

        // TODO: Configure the cell
        cell.backgroundColor = (indexPath.section == 0) ? .systemGreen : .systemGray

        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension TestGridViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = (indexPath.section == 0) ? 2.0 : CGFloat(bottomButtons.count)
        let sectionInsets = (indexPath.section == 0) ? mainSectionInsets : bottomSectionInsets

        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sectionInsets = (section == 0) ? mainSectionInsets : bottomSectionInsets
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let sectionInsets = (section == 0) ? mainSectionInsets : bottomSectionInsets
        return sectionInsets.left
    }
}

//MARK: - UICollectionViewDelegate
extension TestGridViewController: UICollectionViewDelegate {

}
