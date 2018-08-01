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
    var searchParameters: SearchParameters?
    var canPlaceHold: Bool = true
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var pubYearLabel: UILabel!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var synopsisLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var isbnLabel: UILabel!
    
    @IBOutlet weak var copySummaryLabel: UILabel!
    @IBOutlet weak var placeHoldButton: UIButton!
    @IBOutlet weak var copyInfoButton: UIButton!
    
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
        formatLabel.text = item?.format
        authorLabel.text = item?.author
        formatLabel.text = item?.format

        let pubdate = item?.mvrObj?.getString("pubdate") ?? ""
        let publisher = item?.mvrObj?.getString("publisher") ?? ""
        pubYearLabel.text = pubdate + " " + publisher

        if let doc_id = item?.mvrObj?.getInt("doc_id"),
            let url = URL(string: AppSettings.url + "/opac/extras/ac/jacket/medium/r/" + String(doc_id)),
            let data = try? Data(contentsOf: url)
        {
            itemImage.image = UIImage(data: data)
        }

        synopsisLabel.text = item?.mvrObj?.getString("synopsis") ?? ""
        subjectLabel.text = item?.subject
        isbnLabel.text = item?.mvrObj?.getString("isbn") ?? ""

        Style.styleButton(asInverse: copyInfoButton)
        copyInfoButton.addTarget(self, action: #selector(viewCopyPressed(sender:)), for: .touchUpInside)
        
        Style.styleButton(asInverse: placeHoldButton)
        if canPlaceHold {
            placeHoldButton.addTarget(self, action: #selector(placeHoldPressed(sender:)), for: .touchUpInside)
        } else {
            placeHoldButton.isEnabled = false
        }

        self.setupHomeButton()

        updateCopySummary()
    }
    
    func updateCopySummary() {
        if !canPlaceHold {
            copySummaryLabel.text = ""
        } else if let copyCounts = item?.copyCounts,
            let copyCount = copyCounts.last,
            let orgName = Organization.find(byId: copyCount.orgID)?.name
        {
            copySummaryLabel.text = "\(copyCount.available) of \(copyCount.count) copies available at \(orgName)"
        } else {
            copySummaryLabel.text = "? of ? copies available"
        }
    }
    
    func fetchData() {
        guard let _ = App.account?.authtoken,
            let _ = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired())
            return //TODO: add analytics
        }

        if let orgID = Organization.find(byShortName: searchParameters?.organizationShortName)?.id,
            let recordID = self.item?.id
        {
            let promise = SearchService.fetchCopySummary(orgID: orgID, recordID: recordID)
            promise.done { array in
                self.item?.copyCounts = CopySummary.makeArray(fromArray: array)
                self.updateCopySummary()
            }.catch { error in
                self.presentGatewayAlert(forError: error)
            }
        }
    }

    @objc func viewCopyPressed(sender: Any) {
        self.showAlert(title: "Not implemented", message: "This feature is not yet available.")
    }

    @objc func placeHoldPressed(sender: Any) {
        self.performSegue(withIdentifier: "ShowPlaceHoldSegue", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination
        guard let detailsVC = vc as? PlaceHoldsViewController else
        {
            print("Uh oh!")
            return
        }
        detailsVC.record = item
    }
}
