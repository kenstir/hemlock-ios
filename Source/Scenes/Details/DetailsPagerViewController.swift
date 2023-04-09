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
    let index: Int
    let record: MBRecord
    init(index: Int, record: MBRecord) {
        self.index = index
        self.record = record
    }
}

class DetailsPagerViewController: UIPageViewController {

    //MARK: - Properties

    var pages: [Page] = []
    var currentIndex = 0
    var displayOptions: RecordDisplayOptions = RecordDisplayOptions(enablePlaceHold: true, orgShortName: nil)

    private var pageControl: UIPageControl? {
        view.subviews.first { $0 is UIPageControl } as? UIPageControl
    }

    //MARK: - Lifecycle

    static func make(items: [MBRecord], selectedItem: Int, displayOptions: RecordDisplayOptions) -> DetailsPagerViewController? {
        if let vc = UIStoryboard(name: "DetailsPager", bundle: nil).instantiateInitialViewController() as? DetailsPagerViewController {
            for (row, item) in items.enumerated() {
                vc.pages.append(Page(index: row, record: item))
            }
            vc.currentIndex = selectedItem
            vc.displayOptions = displayOptions
            return vc
        }
        return nil
    }

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Item Details"

        // Set our backgroundColor here the for the pageControl to inherit.
        self.view.backgroundColor = App.theme.barBackgroundColor
        setupPager()
    }

    func setupPager() {
        let pageViewController = self
        pageViewController.dataSource = self
        pageViewController.delegate = self

        // load the initial details VC
        if let vc = DetailsViewController.make(row: currentIndex, count: pages.count, record: pages[currentIndex].record) {
            pageViewController.setViewControllers([vc], direction: .forward, animated: true)
        }
    }
}

//MARK: - UIPageViewControllerDataSource

extension DetailsPagerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? DetailsViewController else { return nil }
        let row = currentVC.row - 1
        if row < 0 {
            return nil
        }
        return DetailsViewController.make(row: row, count: pages.count, record: pages[row].record)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? DetailsViewController else { return nil }
        let row = currentVC.row + 1
        if row > pages.count - 1 {
            return nil
        }
        return DetailsViewController.make(row: row, count: pages.count, record: pages[row].record)
    }
}

//MARK: - UIPageViewControllerDelegate

extension DetailsPagerViewController: UIPageViewControllerDelegate {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
}
