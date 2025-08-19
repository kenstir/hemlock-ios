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

        self.setupTapToDismissKeyboard(onScrollView: scrollView)
        scrollView.setupKeyboardAutoResizer()

        Task { await self.fetchData() }
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
        suspendSwitch.addTarget(self, action: #selector(suspendSwitchChanged(sender:)), for: .valueChanged)
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

        // these fields aren't available until we fetch
        pickupTextField.isEnabled = didCompleteFetch
        carrierTextField.isEnabled = didCompleteFetch
        actionButton.isEnabled = didCompleteFetch

        // phone number row is shown only when configured
        phoneNotifyStack.isHidden = !App.config.enableHoldPhoneNotification

        // for a simpler UX, suspend/thaw are hidden when placing a hold
        expirationStack.isHidden = !isEditHold
        suspendStack.isHidden = !isEditHold
        thawStack.isHidden = !isEditHold

        // phone numbers are enabled based on their switches
        phoneTextField.isEnabled = phoneSwitch.isOn
        smsNumberTextField.isEnabled = smsSwitch.isOn

        // The suspend switch has a bunch of effects.
        // When disabling a date picker, we also set the alpha because it doesn't allow
        // a nil or empty date and showing the current date in full alpha is confusing.
        expirationDatePicker.isEnabled = !suspendSwitch.isOn
        expirationDatePicker.alpha = suspendSwitch.isOn ? 0.25 : 1.0
        thawDatePicker.isEnabled = suspendSwitch.isOn
        thawDatePicker.alpha = suspendSwitch.isOn ? 1.0 : 0.25
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

    //MARK: - Async Functions

    @MainActor
    func fetchData() async {
        guard !didCompleteFetch else { return }
        guard let account = App.account else { return }

        let startOfFetch = Date()

        centerSubview(activityIndicator)
        activityIndicator.startAnimating()

        do {
            try await App.serviceConfig.loaderService.loadPlaceHoldPrerequisites()
            try await fetchPartsData(account: account)
            self.didCompleteFetch = true
            self.onDataLoaded()
        } catch {
            self.presentGatewayAlert(forError: error, title: "Error fetching prerequisites")
        }

        activityIndicator.stopAnimating()

        let elapsed = -startOfFetch.timeIntervalSinceNow
        os_log("fetch.elapsed: %.3f (%", log: Gateway.log, type: .info, elapsed, Gateway.addElapsed(elapsed))
    }

    func fetchPartsData(account: Account) async throws {
        if !App.config.enablePartHolds || isEditHold {
            return
        }
        print("PlaceHold: \(record.title): fetching parts")

        let parts = try await SearchService.fetchHoldParts(recordID: record.id)
        self.parts = parts
        if self.hasParts,
           App.config.enableTitleHoldOnItemWithParts,
           let authtoken = account.authtoken,
           let userID = account.userID,
           let pickupOrgID = account.pickupOrgID
        {
            print("PlaceHold: \(self.record.title): checking titleHoldIsPossible")
            do {
                let _ = try await CircService.titleHoldIsPossible(authtoken: authtoken, userID: userID, targetID: self.record.id, pickupOrgID: pickupOrgID)
                self.titleHoldIsPossible = true
            } catch {
                self.titleHoldIsPossible = false
            }
            print("PlaceHold: \(self.record.title): titleHoldIsPossible=\(Utils.toString(self.titleHoldIsPossible))")
        }
    }

    func toInt(_ str: String?) -> Int? {
        if let s = str {
            return Int(s)
        }
        return nil
    }

    // init that can't happen until fetchData completes
    func onDataLoaded() {
        loadNotifyData()
        loadPartData()
        loadOrgData()
        loadCarrierData()
        loadExpirationData()
        enableViewsWhenReady()
        Organization.dumpOrgStats()
    }

    func loadNotifyData() {
        if let val = Utils.coalesce(holdRecord?.hasEmailNotify,
                                    App.account?.defaultNotifyEmail) {
            emailSwitch.isOn = val
        }

        // Allow phone_notify to be set even if UX is not visible
        let phoneNumber = Utils.coalesce(holdRecord?.phoneNotify,
                                         App.account?.notifyPhone,
                                         App.valet.string(forKey: "PhoneNumber"))
        phoneTextField.text = phoneNumber
        if let val = Utils.coalesce(holdRecord?.hasPhoneNotify,
                                    App.account?.defaultNotifyPhone),
            let str = phoneNumber,
            !str.isEmpty
        {
            phoneSwitch.isOn = val
        }

        let smsNumber = Utils.coalesce(holdRecord?.smsNotify,
                                       App.account?.smsNotify,
                                       App.valet.string(forKey: "SMSNumber"))
        smsNumberTextField.text = smsNumber
        if let val = Utils.coalesce(holdRecord?.hasSmsNotify,
                                    App.account?.defaultNotifySMS),
            let str = smsNumber,
            !str.isEmpty
        {
            smsSwitch.isOn = val
        }
    }

    func loadOrgData() {
        orgLabels = Organization.getSpinnerLabels()
        orgIsPickupLocation = Organization.getIsPickupLocation()
        orgIsPrimary = Organization.getIsPrimary()

        var selectOrgIndex = 0
        let defaultPickupLocation = Utils.coalesce(holdRecord?.pickupOrgId,
                                                   App.account?.pickupOrgID)
        for index in 0..<Organization.visibleOrgs.count {
            let org = Organization.visibleOrgs[index]
            if org.id == defaultPickupLocation {
                selectOrgIndex = index
            }
        }

        selectedOrgIndex = selectOrgIndex
        pickupTextField.text = orgLabels[selectOrgIndex].trim()
        pickupTextField.isUserInteractionEnabled = true
    }

    func loadCarrierData() {
        carrierLabels = SMSCarrier.getSpinnerLabels()
        carrierLabels.sort()
        carrierLabels.insert("---", at: 0)

        var selectCarrierName: String?
        var selectCarrierIndex = 0
        if let defaultCarrierID = Utils.coalesce(holdRecord?.smsCarrier,
                                                 App.account?.smsCarrier,
                                                 toInt(App.valet.string(forKey: "SMSCarrier"))),
            let defaultCarrier = SMSCarrier.find(byID: defaultCarrierID) {
            selectCarrierName = defaultCarrier.name
        }
        for index in 0..<carrierLabels.count {
            let carrier = carrierLabels[index]
            if carrier == selectCarrierName {
                selectCarrierIndex = index
            }
        }

        selectedCarrierName = carrierLabels[selectCarrierIndex]
        carrierTextField.text = selectedCarrierName
        carrierTextField.isUserInteractionEnabled = true
    }

    func loadPartData() {
        let sentinelString = partRequired ? "---" : "- \(R.getString("Any part")) -"
        partLabels = [sentinelString]
        for partObj in parts {
            if let label = partObj.getString("label"), let _ = partObj.getInt("id") {
                partLabels.append(label)
            }
        }

        selectedPartLabel = partLabels[0]
        partTextField.text = selectedPartLabel
        partTextField.isUserInteractionEnabled = true
    }

    func defaultExpirationDate() -> Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }

    func defaultThawDate() -> Date {
        return Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    }

    func loadExpirationData() {
        // Unlike the other load* methods, this does not need to wait for fetchData to complete.
        // Leaving it hear for now for consistency.
        suspendSwitch.isOn = holdRecord?.isSuspended ?? false
        if let date = holdRecord?.expireDate {
            expirationDate = date
            expirationDatePicker.date = date
        } else {
            expirationDatePicker.date = defaultExpirationDate()
        }
        if let date = holdRecord?.thawDate {
            thawDate = date
            thawDatePicker.date = date
        } else {
            thawDatePicker.date = defaultThawDate()
        }
    }

    @objc func expirationChanged(sender: UIDatePicker) {
        expirationDate = sender.date
    }

    @objc func thawChanged(sender: UIDatePicker) {
        thawDate = sender.date
    }

    @objc func holdButtonPressed(sender: Any) {
        placeOrUpdateHold()
    }

    @objc func suspendSwitchChanged(sender: UISwitch) {
        enableViewsWhenReady()
        // Hold objects can have null dates, but date pickers can't.
        // Since thawDate is displayed, make sure it's not null.
        if suspendSwitch.isOn {
            thawDate = thawDatePicker.date
        }
    }

    @objc func switchChanged(sender: Any) {
        enableViewsWhenReady()
    }

    func placeOrUpdateHold() {
        guard let authtoken = App.account?.authtoken,
            let userID = App.account?.userID else
        {
            self.presentGatewayAlert(forError: HemlockError.sessionExpired)
            return
        }
        let pickupOrg = Organization.visibleOrgs[selectedOrgIndex]
        if !pickupOrg.isPickupLocation {
            self.showAlert(title: "Not a pickup location", message: "You cannot pick up items at \(pickupOrg.name)")
            return
        }
        var holdType: String
        var targetID: Int
        let partID = parts.first(where: {$0.getString("label") == selectedPartLabel})?.getInt("id")
        if partRequired || partID != nil {
            holdType = API.holdTypePart
            guard let id = partID else {
                self.showAlert(title: "No part selected", message: "You must select a part before placing a hold on this item")
                return
            }
            targetID = id
        } else {
            holdType = API.holdTypeTitle
            targetID = record.id
        }

        var notifyPhoneNumber: String? = nil
        var notifySMSNumber: String? = nil
        var notifyCarrierID: Int? = nil
        if phoneSwitch.isOn {
            guard let phoneNotify = phoneTextField.text?.trim(), !phoneNotify.isEmpty else {
                self.showAlert(title: "Error", message: "Phone number field cannot be empty")
                return
            }
            notifyPhoneNumber = phoneNotify
            if App.config.enableHoldPhoneNotification {
                App.valet.set(string: phoneNotify, forKey: "PhoneNumber")
            }
        }
        if smsSwitch.isOn {
            guard let smsNotify = smsNumberTextField.text?.trim(), !smsNotify.isEmpty else {
                self.showAlert(title: "Error", message: "SMS phone number field cannot be empty")
                return
            }
            guard let carrier = SMSCarrier.find(byName: self.selectedCarrierName) else {
                self.showAlert(title: "Error", message: "Please select a valid carrier")
                return
            }
            App.valet.set(string: String(carrier.id), forKey: "SMSCarrier")
            notifySMSNumber = smsNotify
            App.valet.set(string: smsNotify, forKey: "SMSNumber")
            notifyCarrierID = carrier.id
        }

        if let hold = holdRecord {
            doUpdateHold(authtoken: authtoken, holdRecord: hold, pickupOrg: pickupOrg, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, notifyCarrierID: notifyCarrierID)
        } else {
            doPlaceHold(authtoken: authtoken, userID: userID, holdType: holdType, targetID: targetID, pickupOrg: pickupOrg, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, notifyCarrierID: notifyCarrierID)
        }
    }

    func doPlaceHold(authtoken: String, userID: Int, holdType: String, targetID: Int, pickupOrg: Organization, notifyPhoneNumber: String?, notifySMSNumber: String?, notifyCarrierID: Int?) {
        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()

        let eventParams = placeHoldEventParams(selectedOrg: pickupOrg)

        let promise = CircService.placeHold(authtoken: authtoken, userID: userID, holdType: holdType, targetID: targetID, pickupOrgID: pickupOrg.id, notifyByEmail: emailSwitch.isOn, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, smsCarrierID: notifyCarrierID, expirationDate: expirationDate, useOverride: App.config.enableHoldUseOverride)
        promise.done { obj in
            if let _ = obj.getInt("result") {
                // case 1: result is an Int - hold successful
                self.logPlaceHold(params: eventParams)
                self.valueChangedHandler?();
                self.navigationController?.view.makeToast("Hold successfully placed")
                self.navigationController?.popViewController(animated: true)
                return
            } else if let resultObj = obj.getAny("result") as? OSRFObject,
                let eventObj = resultObj.getAny("last_event") as? OSRFObject
            {
                // case 2: result is an object with last_event - hold failed
                throw self.makeHoldError(fromEventObj: eventObj)
            } else if let resultArray = obj.getAny("result") as? [OSRFObject],
                let eventObj = resultArray.first
            {
                // case 3: result is an array of ilsevent objects - hold failed
                throw self.makeHoldError(fromEventObj: eventObj)
            } else {
                throw HemlockError.unexpectedNetworkResponse(String(describing: obj.dict))
            }
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.logPlaceHold(withError: error, params: eventParams)
            self.presentGatewayAlert(forError: error)
        }
    }

    func doUpdateHold(authtoken: String, holdRecord: HoldRecord, pickupOrg: Organization, notifyPhoneNumber: String?, notifySMSNumber: String?, notifyCarrierID: Int?) {
        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()

        let eventParams: [String: Any] = [Analytics.Param.holdSuspend: suspendSwitch.isOn]

        let promise = CircService.updateHold(authtoken: authtoken, holdRecord: holdRecord, pickupOrgID: pickupOrg.id, notifyByEmail: emailSwitch.isOn, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, smsCarrierID: notifyCarrierID, expirationDate: expirationDate, suspendHold: suspendSwitch.isOn, thawDate: thawDate)
        promise.done { resp in
            if let _ = resp.str {
                // case 1: result is String - update successful
                self.logUpdateHold(params: eventParams)
                self.valueChangedHandler?();
                self.navigationController?.view.makeToast("Hold successfully updated")
                self.navigationController?.popViewController(animated: true)
                return
            } else if let err = resp.error {
                throw err
            } else {
                throw HemlockError.serverError("expected string, received \(resp.description)")
            }
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.logUpdateHold(withError: error, params: eventParams)
            self.presentGatewayAlert(forError: error)
        }
    }

    private func placeHoldEventParams(selectedOrg: Organization) -> [String: Any] {
        var notifyTypes: [String] = []
        if emailSwitch.isOn { notifyTypes.append("email") }
        if phoneSwitch.isOn { notifyTypes.append("phone") }
        if smsSwitch.isOn { notifyTypes.append("sms") }

        let defaultOrg = Organization.find(byId: App.account?.pickupOrgID)
        let homeOrg = Organization.find(byId: App.account?.homeOrgID)

        return [
            Analytics.Param.holdNotify: notifyTypes.joined(separator: "|"),
            Analytics.Param.holdPickupKey: Analytics.orgDimension(selectedOrg: selectedOrg, defaultOrg: defaultOrg, homeOrg: homeOrg)
        ]
    }

    private func logPlaceHold(withError error: Error? = nil, params: [String: Any]) {
        var eventParams: [String: Any] = params
        if let err = error {
            eventParams[Analytics.Param.result] = err.localizedDescription
        } else {
            eventParams[Analytics.Param.result] = Analytics.Value.ok
        }
        Analytics.logEvent(event: Analytics.Event.placeHold, parameters: eventParams)
    }

    private func logUpdateHold(withError error: Error? = nil, params: [String: Any]) {
        var eventParams: [String: Any] = params
        if let err = error {
            eventParams[Analytics.Param.result] = err.localizedDescription
        } else {
            eventParams[Analytics.Param.result] = Analytics.Value.ok
        }
        Analytics.logEvent(event: Analytics.Event.updateHold, parameters: eventParams)
    }

    func makeHoldError(fromEventObj obj: OSRFObject) -> Error {
        if let ilsevent = obj.getInt("ilsevent"),
            let textcode = obj.getString("textcode"),
            let desc = obj.getString("desc")
        {
            let failpart = obj.getObject("payload")?.getString("fail_part")
            return GatewayError.event(ilsevent: ilsevent, textcode: textcode, desc: desc, failpart: failpart)
        }
        return HemlockError.unexpectedNetworkResponse(String(describing: obj))
    }

    func makeVC(title: String, options: [String], selectedOption: String) -> OptionsViewController? {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return nil }
        vc.title = title
        vc.optionLabels = options
        vc.selectedLabel = selectedOption
        return vc
    }

    func makeVC(title: String, options: [String], selectedIndex: Int) -> OptionsViewController? {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return nil }
        vc.title = title
        vc.optionLabels = options
        vc.selectedPath = IndexPath(row: selectedIndex, section: 0)
        return vc
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
            guard let vc = makeVC(title: "Pickup Location", options: orgLabels, selectedIndex: selectedOrgIndex) else { return true }
            vc.selectionChangedHandler = { index, trimmedLabel in
                self.selectedOrgIndex = index
                self.pickupTextField.text = trimmedLabel
            }
            vc.optionIsEnabled = self.orgIsPickupLocation
            vc.optionIsPrimary = self.orgIsPrimary
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case carrierTextField:
            guard let vc = makeVC(title: "SMS Carrier", options: carrierLabels, selectedOption: selectedCarrierName) else { return true }
            vc.selectionChangedHandler = { index, trimmedLabel in
                self.selectedCarrierName = trimmedLabel
                self.carrierTextField.text = trimmedLabel
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case partTextField:
            guard let vc = makeVC(title: "Select a part", options: partLabels, selectedOption: selectedPartLabel) else { return true }
            vc.selectionChangedHandler = { index, trimmedLabel in
                self.selectedPartLabel = trimmedLabel
                self.partTextField.text = trimmedLabel
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        default:
            return true
        }
    }
}
