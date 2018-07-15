//
//  DetailsViewController.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
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
import PromiseKit
import PMKAlamofire


class DetailsViewController: UIViewController {
    
    //MARK: - Properties

    var item: MBRecord?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var pubYearLabel: UILabel!
    @IBOutlet weak var publisherLabel: UILabel!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var synopsisLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var isbnLabel: UILabel!
    
    @IBOutlet weak var renewButton: UIButton!
    @IBOutlet weak var viewCopyButton: UIButton!
    @IBOutlet weak var addToListButton: UIButton!
    
    //MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - Functions
    
    func setupViews() {
        titleLabel.text = item?.title
        authorLabel.text = item?.author
        let pubdate = item?.mvrObj?.getString("pubdate") ?? ""
        let publisher = item?.mvrObj?.getString("publisher") ?? ""
        pubYearLabel.text = pubdate + " " + publisher
        if let doc_id = item?.mvrObj?.getInt("doc_id"),
            let url = URL(string: AppSettings.url + "/opac/extras/ac/jacket/medium/r/" + String(doc_id)),
            let data = try? Data(contentsOf: url)
        {
            itemImage.image = UIImage(data: data)
        }
        synopsisLabel.text = "Synopsis: " + (item?.mvrObj?.getString("synopsis") ?? "")
        subjectLabel.text = item?.subject
        isbnLabel.text = "ISBN:  " + (item?.mvrObj?.getString("isbn") ?? "")

        Style.styleButton(asPlain: viewCopyButton)
        viewCopyButton.addTarget(self, action: #selector(viewCopyPressed(sender:)), for: .touchUpInside)
        renewButton.isHidden = true
        addToListButton.isHidden = true
    }
    
    func fetchData() {
        guard let _ = App.account?.authtoken,
            let _ = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        //TODO: fetch copy info
    }

    @objc func viewCopyPressed(sender: Any) {
        self.showAlert(title: "Not implemented", message: "This feature is not yet available.")
    }
}

