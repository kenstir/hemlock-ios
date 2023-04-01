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

class Page {
    let row: Int
    let record: MBRecord
    init(row: Int, record: MBRecord) {
        self.row = row
        self.record = record
    }
}

class DetailsPagerViewController: UIViewController {

    //MARK: - Properties

    var pages: [Page] = []
    var currentIndex = 0
    var displayOptions: RecordDisplayOptions

    private var pager: UIPageViewController?

    //MARK: - Lifecycle

    init(items: [MBRecord], selectedItem: Int, displayOptions: RecordDisplayOptions) {
        for (row, item) in items.enumerated() {
            self.pages.append(Page(row: row, record: item))
        }
        self.currentIndex = selectedItem
        self.displayOptions = displayOptions
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPager()
    }

    func setupPager() {
        pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        self.pager?.dataSource = self
        self.pager?.delegate = self

        let vc = DetailsViewController(row: currentIndex, record: pages[currentIndex].record)
        pager?.setViewControllers([vc], direction: .forward, animated: true)

        pager?.didMove(toParent: self)
    }
}

extension DetailsPagerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? DetailsViewController else { return nil }
        let row = currentVC.row - 1
        if row < 0 {
            return nil
        }
        return DetailsViewController(row: row, record: pages[row].record)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? DetailsViewController else { return nil }
        let row = currentVC.row + 1
        if row > pages.count - 1 {
            return nil
        }
        return DetailsViewController(row: row, record: pages[row].record)
    }
}

extension DetailsPagerViewController: UIPageViewControllerDelegate {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
}
