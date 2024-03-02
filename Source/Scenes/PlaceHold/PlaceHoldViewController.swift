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
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var smsNumberTextField: UITextField!
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

    var partLabels: [String] = []
    var orgLabels: [String] = []
    var orgIsPickupLocation: [Bool] = []
    var orgIsPrimary: [Bool] = []
    var carrierLabels: [String] = []
    var selectedPartLabel = ""
    var selectedOrgIndex = 0
    var selectedCarrierName = ""
    var didCompleteFetch = false
    var expirationDate: Date? = nil
    var thawDate: Date? = nil

    var activityIndicator: UIActivityIndicatorView!

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
        super.viewDidLoad()
        self.title = isEditHold ? "Edit Hold" : "Place Hold"
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
    }

    //MARK: - Setup Functions

    func setupViews() {
        setupMetadataLabels()
        setupLabelAlignment()

        setupPartRow()
        setupPickupRow()
        setupPhoneRow()
        setupSmsRow()
        setupCarrierRow()
        setupExpirationRow()
        setupSuspendRow()
        setupThawRow()
        setupButtonRow()

        setupActivityIndicator()

        enableViewsWhenReady()
    }

    func setupMetadataLabels() {
        titleLabel.text = record.title
        authorLabel.text = record.author
        formatLabel.text = record.iconFormatLabel
    }

    func setupPartRow() {
        partTextField.addDisclosureIndicator()
        partTextField.delegate = self
    }

    func setupPickupRow() {
        pickupTextField.addDisclosureIndicator()
        pickupTextField.delegate = self
    }

    func setupCarrierRow() {
        carrierTextField.addDisclosureIndicator()
        carrierTextField.delegate = self
    }

    func setupPhoneRow() {
        phoneSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
        phoneTextField.keyboardType = .phonePad
        phoneTextField.delegate = self
    }

    func setupSmsRow() {
        smsSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
        smsNumberTextField.keyboardType = .phonePad
        smsNumberTextField.delegate = self
    }

    func setupSuspendRow() {
        suspendSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
    }

    func setupExpirationRow() {
        expirationDatePicker.addTarget(self, action: #selector(expirationChanged(sender:)), for: .valueChanged)
        expirationDatePicker.contentHorizontalAlignment = .left
    }

    func setupThawRow() {
        thawDatePicker.addTarget(self, action: #selector(thawChanged(sender:)), for: .valueChanged)
        thawDatePicker.contentHorizontalAlignment = .left
    }

    func setupButtonRow() {
        actionButton.setTitle(isEditHold ? "Update Hold" : "Place Hold", for: .normal)
        actionButton.addTarget(self, action: #selector(holdButtonPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asInverse: actionButton)
    }

    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }

    func enableViewsWhenReady() {
        partSelectStack.isHidden = !hasParts
//        partTextField.isEnabled = hasParts
        pickupTextField.isEnabled = didCompleteFetch
        phoneNotifyStack.isHidden = !App.config.enableHoldPhoneNotification
//        phoneTextField.isEnabled = App.config.enableHoldPhoneNotification
        smsNumberTextField.isEnabled = smsSwitch.isOn
        carrierTextField.isEnabled = didCompleteFetch
        thawDatePicker.isEnabled = suspendSwitch.isOn
        actionButton.isEnabled = didCompleteFetch
    }

    func setupLabelAlignment() {
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

    //MARK: - Functions

    func fetchData() {
    }

    @objc func expirationChanged(sender: UIDatePicker) {
        updateExpirationDate(sender.date)
    }

    func updateExpirationDate(_ date: Date) {
        expirationDate = date
//        expirationDatePicker.date = date
    }

    @objc func thawChanged(sender: UIDatePicker) {
        updateThawDate(sender.date)
    }

    func updateThawDate(_ date: Date) {
        thawDate = date
//        thawDatePicker.date = date
    }

    @objc func switchChanged(sender: Any) {
        enableViewsWhenReady()
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

//MARK: - UITextFieldDelegate
extension PlaceHoldViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField {
        case pickupTextField:
//            guard let vc = makeVC(title: "Pickup Location", options: orgLabels, selectedIndex: selectedOrgIndex) else { return true }
//            vc.selectionChangedHandler = { index, trimmedLabel in
//                self.selectedOrgIndex = index
//                self.pickupNode.textField?.text = trimmedLabel
//            }
//            vc.optionIsEnabled = self.orgIsPickupLocation
//            vc.optionIsPrimary = self.orgIsPrimary
//            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case carrierTextField:
//            guard let vc = makeVC(title: "SMS Carrier", options: carrierLabels, selectedOption: selectedCarrierName) else { return true }
//            vc.selectionChangedHandler = { index, trimmedLabel in
//                self.selectedCarrierName = trimmedLabel
//                self.carrierNode.textField?.text = trimmedLabel
//            }
//            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case partTextField:
//            guard let vc = makeVC(title: "Select a part", options: partLabels, selectedOption: selectedPartLabel) else { return true }
//            vc.selectionChangedHandler = { index, trimmedLabel in
//                self.selectedPartLabel = trimmedLabel
//                self.partNode.textField?.text = trimmedLabel
//            }
//            self.navigationController?.pushViewController(vc, animated: true)
            return false
        default:
            return true
        }
    }
}
