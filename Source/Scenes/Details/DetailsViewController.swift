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

    @IBOutlet weak var headerRow: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var pubinfoLabel: UILabel!
    

    var pageHeaderVStack: UIStackView?
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

    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    //MARK: - Functions

    func setupViews() {
        setupPageHeader()
        setupDetails()
    }

    private func setupPageHeader() {
        let naturalNumber = row + 1
        let str = "Showing Item \(naturalNumber) of \(count)"
        headerLabel.text = str
        Style.styleLabel(asTableHeader: headerLabel)
        Style.styleView(asTableHeader: headerRow)
    }

    private func setupDetails() {
        titleLabel.text = record?.title
        author.text = record?.author
        formatLabel.text = record?.iconFormatLabel
        pubinfoLabel.text = record?.pubinfo
    }
}
