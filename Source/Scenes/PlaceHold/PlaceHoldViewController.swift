//
//  Copyright (C) 2024 Kenneth H. Cox
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
import os.log

class PlaceHoldViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var partSelectStack: UIStackView!
    @IBOutlet weak var phoneNotifyStack: UIStackView!
    @IBOutlet weak var expirationStack: UIStackView!
    @IBOutlet weak var suspendStack: UIStackView!
    @IBOutlet weak var thawStack: UIStackView!

    @IBOutlet weak var partTextField: UITextField!
    @IBOutlet weak var pickupTextField: UITextField!
    @IBOutlet weak var pickupButton: UIButton!
    @IBOutlet weak var carrierTextField: UITextField!
    @IBOutlet weak var expirationDatePicker: UIDatePicker!
    @IBOutlet weak var thawDatePicker: UIDatePicker!

    @IBOutlet weak var emailSwitch: UISwitch!
    @IBOutlet weak var phoneSwitch: UISwitch!
    @IBOutlet weak var smsSwitch: UISwitch!
    @IBOutlet weak var suspendSwitch: UISwitch!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var formatLabel: UILabel!

    @IBOutlet weak var actionButton: UIButton!

    @IBOutlet var labels: [UILabel]!

    var record = MBRecord.dummyRecord
    var holdRecord: HoldRecord?
    var parts: [OSRFObject] = []
    var valueChangedHandler: (() -> Void)?

    var isEditHold: Bool { return holdRecord != nil }
    var hasParts: Bool { return !parts.isEmpty }
    var titleHoldIsPossible: Bool? = nil
    var partRequired: Bool { return hasParts && titleHoldIsPossible != true }

    //MARK: - Lifecycle

    static func make(record: MBRecord, holdRecord: HoldRecord? = nil, valueChangedHandler: (() -> Void)? = nil) -> PlaceHoldViewController? {
        if let vc = UIStoryboard(name: "NewPlaceHold", bundle: nil).instantiateInitialViewController() as? PlaceHoldViewController {
            vc.record = record
            vc.holdRecord = holdRecord
            vc.valueChangedHandler = valueChangedHandler
            return vc
        }
        return nil
    }

    //MARK: - UIViewController

    override func viewDidLoad() {
        print("=============================== viewDidLoad")
        super.viewDidLoad()
        for label in labels {
            print("label: \(label.text ?? "") \(label.frame.width)")
        }
        setupViews()
    }

    override func viewDidLayoutSubviews() {
        print("=============================== viewDidLayoutSubviews")
        for label in labels {
            print("label: \(label.text ?? "") \(label.frame.width)")
        }
        print("expirePicker: \(expirationDatePicker.frame.width)")
        print("thawPicker:   \(thawDatePicker.frame.width)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - Setup Functions

    func setupViews() {
        setupMetadataLabels()
        setupFormLabels()
        setupTextViews()
        setupPickers()

        actionButton.setTitle(isEditHold ? "Update Hold" : "Place Hold", for: .normal)
        actionButton.addTarget(self, action: #selector(holdButtonPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asInverse: actionButton)
    }

    func setupMetadataLabels() {
        titleLabel.text = record.title
        authorLabel.text = record.author
        formatLabel.text = record.iconFormatLabel
    }

    func setupFormLabels() {
        partSelectStack.isHidden = true
        phoneNotifyStack.isHidden = true

        // find the widest label whose superview (Hstack) is visible
        guard let widestLabel = labels.max(by: { ($1.superview?.isHidden == false) && $1.frame.width > $0.frame.width }) else { return }
        print("widest: \(widestLabel.text ?? "") \(widestLabel.frame.width)")

        // Set a minimum width constraint to *slightly bigger* than the widest label wants to be.
        // Setting an equalTo constraint resulted in all the labels being too thin and ellipsized.
        let minWidth = widestLabel.frame.width + 8.0
        for label in labels {
            print("label: \(label.text ?? "") new min width \(minWidth)")
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
        }
    }

    var iconImageView: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            let configuration = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            imageView.image = UIImage(systemName: "chevron.right", withConfiguration: configuration)
            imageView.tintColor = .lightGray
            imageView.contentMode = .scaleAspectFit
            NSLayoutConstraint(item: imageView,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: imageView,
                                         attribute: .width,
                               multiplier: 17.0/10.0,
                                         constant: 0).isActive = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
        }
        return imageView
    }()

    func setupTextViews() {
        partTextField.addDisclosureIndicator()
        pickupTextField.addDisclosureIndicator()
        carrierTextField.addDisclosureIndicator()
    }

    func setupPickers() {
        expirationDatePicker.contentHorizontalAlignment = .left
        thawDatePicker.contentHorizontalAlignment = .left
    }

    //MARK: - Functions

    func fetchData() {
    }

    @objc func holdButtonPressed(sender: Any) {
        placeOrUpdateHold()
    }

    func placeOrUpdateHold() {
//        guard let authtoken = App.account?.authtoken,
//              let userID = App.account?.userID else
//        {
//            self.presentGatewayAlert(forError: HemlockError.sessionExpired)
//            return
//        }
        self.showAlert(title: "not impl", message: "not ready yet")
    }
}
