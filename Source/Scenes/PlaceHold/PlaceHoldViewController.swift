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

    var record = BibRecord.dummyRecord
    var holdRecord: HoldRecord?
    var parts: [XHoldPart] = []
    var valueChangedHandler: (() -> Void)?

    var partLabels: [String] = []
    var orgLabels: [String] = []
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

    static func make(record: BibRecord, holdRecord: HoldRecord? = nil, valueChangedHandler: (() -> Void)? = nil) -> PlaceHoldViewController? {
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
        setupEmailRow()
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

    func setupEmailRow() {
        emailSwitch.addTarget(self, action: #selector(emailSwitchChanged(sender:)), for: .valueChanged)
    }

    func setupPhoneRow() {
        phoneSwitch.addTarget(self, action: #selector(phoneSwitchChanged(sender:)), for: .valueChanged)
        phoneTextField.keyboardType = .phonePad
        phoneTextField.delegate = self
        phoneTextField.addTarget(self, action: #selector(phoneTextChanged), for: [.editingDidEnd, .editingDidEndOnExit])
    }

    func setupSmsRow() {
        smsSwitch.addTarget(self, action: #selector(smsSwitchChanged(sender:)), for: .valueChanged)
        smsNumberTextField.keyboardType = .phonePad
        smsNumberTextField.delegate = self
        smsNumberTextField.addTarget(self, action: #selector(smsTextChanged), for: [.editingDidEnd, .editingDidEndOnExit])
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

        activityIndicator.startAnimating()

        do {
            async let prereq: Void = App.serviceConfig.loaderService.loadPlaceHoldPrerequisites()
            async let parts: Void = fetchPartsData(account: account)
            _ = try await (prereq, parts)
            self.didCompleteFetch = true
            self.onDataLoaded()
        } catch {
            self.presentGatewayAlert(forError: error)
        }

        activityIndicator.stopAnimating()

        let elapsed = -startOfFetch.timeIntervalSinceNow
        os_log("fetch.elapsed: %.3f", log: Gateway.log, type: .info, elapsed)
    }

    func fetchPartsData(account: Account) async throws {
        if !App.config.enablePartHolds || isEditHold {
            return
        }
        print("PlaceHold: \(record.title): fetching parts")

        self.parts = try await App.serviceConfig.circService.fetchHoldParts(targetId: record.id)
        if self.hasParts,
           App.config.enableTitleHoldOnItemWithParts,
           let pickupOrgID = account.pickupOrgID
        {
            print("PlaceHold: \(self.record.title): checking titleHoldIsPossible")
            do {
                let _ = try await App.serviceConfig.circService.fetchTitleHoldIsPossible(account: account, targetId: self.record.id, pickupOrgId: pickupOrgID)
                self.titleHoldIsPossible = true
            } catch {
                self.titleHoldIsPossible = false
            }
            print("PlaceHold: \(self.record.title): titleHoldIsPossible=\(Utils.toString(self.titleHoldIsPossible))")
        }
    }

    //MARK: - Options State Management

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
                                    AppState.bool(forKey: AppState.Boolean.holdNotifyByEmail),
                                    App.account?.defaultNotifyEmail) {
            emailSwitch.isOn = val
        }

        // Allow phone_notify to be set even if UX is not visible
        let phoneNumber = Utils.coalesce(holdRecord?.phoneNotify,
                                         AppState.sensitiveString(forKey: AppState.Str.holdPhoneNumber),
                                         App.account?.notifyPhone)
        phoneTextField.text = phoneNumber
        if let val = Utils.coalesce(holdRecord?.hasPhoneNotify,
                                    AppState.bool(forKey: AppState.Boolean.holdNotifyByPhone),
                                    App.account?.defaultNotifyPhone),
            let str = phoneNumber,
            !str.isEmpty
        {
            phoneSwitch.isOn = val
        }

        let smsNumber = Utils.coalesce(holdRecord?.smsNotify,
                                       AppState.sensitiveString(forKey: AppState.Str.holdSMSNumber),
                                       App.account?.smsNotify)
        smsNumberTextField.text = smsNumber
        if let val = Utils.coalesce(holdRecord?.hasSmsNotify,
                                    AppState.bool(forKey: AppState.Boolean.holdNotifyBySMS),
                                    App.account?.defaultNotifySMS),
            let str = smsNumber,
            !str.isEmpty
        {
            smsSwitch.isOn = val
        }
    }

    func loadCarrierData() {
        carrierLabels = SMSCarrier.getSpinnerLabels()
        carrierLabels.sort()
        carrierLabels.insert("---", at: 0)

        let defaultCarrierID = Utils.coalesce(holdRecord?.smsCarrier,
                                              AppState.integer(forKey: AppState.Integer.holdSMSCarrierID),
                                              App.account?.smsCarrier)

        let selectedCarrier = SMSCarrier.find(byID: defaultCarrierID)
        selectedCarrierName = selectedCarrier?.name ?? carrierLabels[0]
        carrierTextField.text = selectedCarrierName
        carrierTextField.isUserInteractionEnabled = true
    }

    func loadPartData() {
        let sentinelString = partRequired ? "---" : "- \(R.getString("Any part")) -"
        partLabels = [sentinelString]
        for part in parts {
            partLabels.append(part.label)
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

    @objc func emailSwitchChanged(sender: Any) {
        AppState.set(bool: emailSwitch.isOn, forKey: AppState.Boolean.holdNotifyByEmail)
    }

    @objc func phoneSwitchChanged(sender: Any) {
        enableViewsWhenReady()
        AppState.set(bool: phoneSwitch.isOn, forKey: AppState.Boolean.holdNotifyByPhone)
    }

    @objc func smsSwitchChanged(sender: Any) {
        enableViewsWhenReady()
        AppState.set(bool: smsSwitch.isOn, forKey: AppState.Boolean.holdNotifyBySMS)
    }

    @objc func phoneTextChanged(sender: UITextField) {
        if let phoneNumber = sender.text?.trim(), !phoneNumber.isEmpty {
            AppState.set(sensitiveString: phoneNumber, forKey: AppState.Str.holdPhoneNumber)
        }
    }

    @objc func smsTextChanged(sender: UITextField) {
        if let smsNumber = sender.text?.trim(), !smsNumber.isEmpty {
            AppState.set(sensitiveString: smsNumber, forKey: AppState.Str.holdSMSNumber)
        }
    }

    func saveSelectedCarrier(byName name: String) {
        if let carrier = SMSCarrier.find(byName: name) {
            AppState.set(integer: carrier.id, forKey: AppState.Integer.holdSMSCarrierID)
        }
    }

    //MARK: - Pickup Org Management

    func loadOrgData() {
        // The pickup org preference is handled differently from other preferences:
        // * it always defaults to the account setting
        // * changing it results in an JUST ONCE / ALWAYS alert
        // * ALWAYS saves it back to the account
        orgLabels = Organization.getSpinnerLabels()

        let defaultPickupOrgID = Utils.coalesce(holdRecord?.pickupOrgId,
                                                App.account?.pickupOrgID)

        selectedOrgIndex = Organization.visibleOrgs.firstIndex(where: { $0.id == defaultPickupOrgID }) ?? 0
        let label = orgLabels[selectedOrgIndex].trim()
        pickupTextField.text = label
        print("[prefs] Pickup org: default is \(label)")

        pickupTextField.isUserInteractionEnabled = true
    }

    func maybeChangePickupOrg(newIndex: Int, newLabel: String) {
        let newOrg = Organization.visibleOrgs[newIndex]
        print("[prefs] Pickup org: selected \(newOrg.name)")
        guard newIndex != selectedOrgIndex else { return }

        if newOrg.id == App.account?.pickupOrgID {
            print("[prefs] Pickup org: same as account setting")
            selectedOrgIndex = newIndex
            pickupTextField.text = newLabel
            return
        }

        let alertController = UIAlertController(title: "Change pickup location?", message: "Change pickup location to \(newOrg.name)?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("[prefs] Pickup org: cancel")
        })
        alertController.addAction(UIAlertAction(title: "Just once", style: .default) { _ in
            print("[prefs] Pickup org: just once")
            self.selectedOrgIndex = newIndex
            self.pickupTextField.text = newLabel
        })
        alertController.addAction(UIAlertAction(title: "Always", style: .default) { _ in
            print("[prefs] Pickup org: always")
            self.selectedOrgIndex = newIndex
            self.pickupTextField.text = newLabel
            Task { await self.saveSelectedPickupOrg(org: newOrg) }
        })

        // iPad requires a popoverPresentationController
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.pickupTextField
            popoverController.sourceRect = self.pickupTextField.bounds
        }
        self.present(alertController, animated: true)
    }

    @MainActor
    func saveSelectedPickupOrg(org: Organization) async {
        guard let account = App.account else { return }
        do {
            try await App.serviceConfig.userService.changePickupOrg(account: account, orgId: org.id)
        } catch {
            self.presentGatewayAlert(forError: error)
        }
    }

    //MARK: - Place/Update Hold

    func placeOrUpdateHold() {
        guard let account = App.account else
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
        let partID = parts.first(where: {$0.label == selectedPartLabel})?.id
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
            guard let phoneNumber = phoneTextField.text?.trim(), !phoneNumber.isEmpty else {
                self.showAlert(title: "Error", message: "Phone number cannot be empty")
                return
            }
            notifyPhoneNumber = phoneNumber
        }
        if smsSwitch.isOn {
            guard let smsNumber = smsNumberTextField.text?.trim(), !smsNumber.isEmpty else {
                self.showAlert(title: "Error", message: "SMS phone number cannot be empty")
                return
            }
            guard let carrier = SMSCarrier.find(byName: self.selectedCarrierName) else {
                self.showAlert(title: "Error", message: "Please select a valid carrier")
                return
            }
            notifySMSNumber = smsNumber
            notifyCarrierID = carrier.id
        }

        if let hold = holdRecord {
            Task { await doUpdateHold(account: account, holdRecord: hold, pickupOrg: pickupOrg, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, notifyCarrierID: notifyCarrierID) }
        } else {
            Task { await doPlaceHold(account: account, holdType: holdType, targetID: targetID, pickupOrg: pickupOrg, notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, notifyCarrierID: notifyCarrierID) }
        }
    }

    @MainActor
    func doPlaceHold(account: Account, holdType: String, targetID: Int, pickupOrg: Organization, notifyPhoneNumber: String?, notifySMSNumber: String?, notifyCarrierID: Int?) async {
        activityIndicator.startAnimating()

        let eventParams = placeHoldEventParams(selectedOrg: pickupOrg)
        do {
            let options = XHoldOptions(holdType: holdType, useOverride: App.config.enableHoldUseOverride, notifyByEmail: emailSwitch.isOn, phoneNotify: notifyPhoneNumber, smsNotify: notifySMSNumber, smsCarrierId: notifyCarrierID, pickupOrgId: pickupOrg.id)
            let _ = try await App.serviceConfig.circService.placeHold(account: account, targetId: targetID, withOptions: options)
            activityIndicator.stopAnimating()
            self.logPlaceHold(params: eventParams)
            self.valueChangedHandler?()
            self.navigationController?.view.makeToast("Hold successfully placed")
            self.navigationController?.popViewController(animated: true)
        } catch {
            activityIndicator.stopAnimating()
            self.logPlaceHold(withError: error, params: eventParams)
            self.presentGatewayAlert(forError: error)
        }
    }

    @MainActor
    func doUpdateHold(account: Account, holdRecord: HoldRecord, pickupOrg: Organization, notifyPhoneNumber: String?, notifySMSNumber: String?, notifyCarrierID: Int?) async {
        activityIndicator.startAnimating()

        let eventParams: [String: Any] = [Analytics.Param.holdSuspend: suspendSwitch.isOn]
        do {
            let options = XHoldUpdateOptions(notifyByEmail: emailSwitch.isOn, phoneNotify: notifyPhoneNumber, smsNotify: notifySMSNumber, smsCarrierId: notifyCarrierID, pickupOrgId: pickupOrg.id, expirationDate: expirationDate, suspended: suspendSwitch.isOn, thawDate: thawDate)
            let _ = try await App.serviceConfig.circService.updateHold(account: account, holdId: holdRecord.id, withOptions: options)
            activityIndicator.stopAnimating()
            self.logUpdateHold(params: eventParams)
            self.valueChangedHandler?()
            self.navigationController?.view.makeToast("Hold successfully updated")
            self.navigationController?.popViewController(animated: true)
        } catch {
            activityIndicator.stopAnimating()
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

    func makeOptionVC(title: String) -> OptionsViewController? {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return nil }
        vc.title = title
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
            guard let vc = makeOptionVC(title: "Pickup Location") else { return true }
            vc.option = PickOneOption(optionLabels: orgLabels, optionIsEnabled: Organization.getIsPickupLocation(), optionIsPrimary: Organization.getIsPrimary())
            vc.selectedIndex = selectedOrgIndex
            vc.selectionChangedHandler = { index, trimmedLabel in
                // postpone any possible alert until after OptionsVC is popped
                DispatchQueue.main.asyncAfter(deadline: .now() + OptionsViewController.postSelectionDelay + 0.050) {
                    self.maybeChangePickupOrg(newIndex: index, newLabel: trimmedLabel)
                }
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case carrierTextField:
            guard let vc = makeOptionVC(title: "SMS Carrier") else { return true }
            vc.option = PickOneOption(optionLabels: carrierLabels)
            vc.selectedIndex = carrierLabels.firstIndex(of: selectedCarrierName)
            vc.selectionChangedHandler = { index, trimmedLabel in
                self.selectedCarrierName = trimmedLabel
                self.carrierTextField.text = trimmedLabel
                self.saveSelectedCarrier(byName: trimmedLabel)
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case partTextField:
            guard let vc = makeOptionVC(title: "Select a part") else { return true }
            vc.option = PickOneOption(optionLabels: partLabels)
            vc.selectedIndex = partLabels.firstIndex(of: selectedPartLabel)
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
