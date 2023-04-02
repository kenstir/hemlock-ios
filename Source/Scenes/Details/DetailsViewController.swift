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

class DetailsViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var headerLabel: UILabel!
    var pageHeaderVStack: UIStackView?
    var titleLabel: UILabel?
    var row: Int = 0
    var count: Int = 0
    var record: MBRecord?

    //MARK: - Lifecycle

    static func make(row: Int, count: Int, record: MBRecord) -> DetailsViewController? {
        if let vc = UIStoryboard(name: "Details", bundle: nil).instantiateInitialViewController() as? DetailsViewController {
            vc.row = row
            vc.count = count
            vc.record = record
            return vc
        }
        return nil
    }

//    init(row: Int, record: MBRecord) {
//        self.row = row
//        self.record = record
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    //MARK: - Functions

    func setupViews() {
        setupPageHeader()
    }

    private func setupPageHeader() {
        let naturalNumber = row + 1
        let str = "Showing Item \(naturalNumber) of \(count)"
        headerLabel.attributedText = Style.makeTableHeaderString(str, size: Style.calloutSize)
        headerLabel.backgroundColor = Style.systemGroupedBackground
//        Style.styleLabel(asTableHeader: headerLabel)
    }
}
