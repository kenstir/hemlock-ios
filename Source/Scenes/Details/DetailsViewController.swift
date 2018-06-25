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
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchData()
    }
    
    //MARK: - Functions
    
    func setupViews() {
    }
    
    func fetchData() {
        guard let authtoken = App.account?.authtoken,
            let userid = App.account?.userID else
        {
            showAlert(error: HemlockError.sessionExpired())
            return //TODO: add analytics
        }
        
        titleLabel.text = item?.title
        authorLabel.text = item?.author
        pubYearLabel.text = (item?.mvrObj?.getString("pubdate") ?? "")! + " " + (item?.mvrObj?.getString("publisher") ?? "")!
        let url = URL(string: "https://gapines.org/opac/extras/ac/jacket/medium/r/4461833")
        let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
        itemImage.image = UIImage(data: data!)
        debugPrint(item?.mvrObj?.dict)
        synopsisLabel.text = item?.mvrObj?.getString("synopsis")
        subjectLabel.text = item?.mvrObj?.getString("subject")
        debugPrint(subjectLabel.text)
        isbnLabel.text = "ISBN:  " + (item?.mvrObj?.getString("isbn") ?? "")
        /*
        // fetch the list of items
        let req = Gateway.makeRequest(service: API.actor, method: API.actorCheckedOut, args: [authtoken, userid])
        req.gatewayObjectResponse().done { obj in
            try self.fetchCircRecords(fromObject: obj)
            }.catch { error in
                self.showAlert(error: error)
        }
 */
    }
}

