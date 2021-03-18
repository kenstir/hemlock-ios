//
//  XPlaceHoldViewController.swift
//  X is for teXture
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

import AsyncDisplayKit
import PromiseKit
import PMKAlamofire
import os.log

class XPlaceHoldViewController: ASViewController<ASDisplayNode> {
    
    //MARK: - Properties

    let record: MBRecord
    let holdRecord: HoldRecord?
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
    var expirationPickerVisible = false
    var thawDate: Date? = nil
    var thawPickerVisible = false

    var activityIndicator: UIActivityIndicatorView!

    let containerNode = ASDisplayNode()
    let scrollNode = ASScrollNode()

    let titleNode = ASTextNode()
    let authorNode = ASTextNode()
    let formatNode = ASTextNode()
    //let spacerNode = ASDisplayNode()
    let partLabel = ASTextNode()
    let partNode = XUtils.makeTextFieldNode()
    let partDisclosure = XUtils.makeDisclosureNode()
    let pickupLabel = ASTextNode()
    let pickupNode = XUtils.makeTextFieldNode()
    let pickupDisclosure = XUtils.makeDisclosureNode()
    let emailLabel = ASTextNode()
    let emailSwitch = XUtils.makeSwitchNode()
    let phoneLabel = ASTextNode()
    let phoneSwitch = XUtils.makeSwitchNode()
    let phoneNode = XUtils.makeTextFieldNode()
    let smsLabel = ASTextNode()
    let smsSwitch = XUtils.makeSwitchNode()
    let smsNode = XUtils.makeTextFieldNode()
    let carrierLabel = ASTextNode()
    let carrierNode = XUtils.makeTextFieldNode()
    let carrierDisclosure = XUtils.makeDisclosureNode()
    let expirationLabel = ASTextNode()
    let expirationNode = XUtils.makeTextFieldNode()
    let expirationPickerNode = ASDisplayNode { () -> UIView in
        return UIDatePicker()
    }
    let suspendLabel = ASTextNode()
    let suspendSwitch = XUtils.makeSwitchNode()
    let thawLabel = ASTextNode()
    let thawNode = XUtils.makeTextFieldNode()
    let thawPickerNode = ASDisplayNode { () -> UIView in
        return UIDatePicker()
    }
    let actionButton = ASButtonNode()
    let labelSize = Style.subheadSize

    var isEditHold: Bool { return holdRecord != nil }
    var hasParts: Bool { return !parts.isEmpty }
    var titleHoldIsPossible: Bool? = nil
    var partRequired: Bool { return hasParts && titleHoldIsPossible != true }

    //MARK: - Lifecycle
    
    init(record: MBRecord, holdRecord: HoldRecord? = nil, valueChangedHandler: (() -> Void)? = nil) {
        self.record = record
        self.holdRecord = holdRecord
        self.valueChangedHandler = valueChangedHandler

        super.init(node: containerNode)
        self.title = isEditHold ? "Edit Hold" : "Place Hold"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - ViewController
    
    // NB: viewDidLoad on an ASViewController gets called during construction,
    // before there is any UI.  Do not fetchData here.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Style.systemBackground
        setupNodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // See Footnote #2 - disable nav bar isTranslucent
        navigationController?.navigationBar.isTranslucent = false
        
        self.setupTapToDismissKeyboard(onScrollView: scrollNode.view)
        scrollNode.view.setupKeyboardAutoResizer()
        
        fetchData()
    }

    //MARK: - setup
    
    func setupNodes() {
        Style.setupTitle(titleNode, str: holdRecord?.title ?? record.title)
        Style.setupSubtitle(authorNode, str: record.author)
        Style.setupSubtitle(formatNode, str: record.iconFormatLabel, ofSize: Style.calloutSize)
        
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
        
        // See Footnote #1 - handling the keyboard
        setupContainerNode()
        setupScrollNode()
        
        self.activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        Style.styleActivityIndicator(activityIndicator)
        self.node.view.addSubview(activityIndicator)
        
        enableNodesWhenReady()
    }
    
    func enableNodesWhenReady() {
        partNode.textField?.isEnabled = hasParts
        pickupNode.textField?.isEnabled = didCompleteFetch
        phoneNode.textField?.isEnabled = isOn(phoneSwitch)
        smsNode.textField?.isEnabled = isOn(smsSwitch)
        carrierNode.textField?.isEnabled = didCompleteFetch
        thawNode.textField?.isEnabled = isOn(suspendSwitch)
        actionButton.isEnabled = didCompleteFetch
        actionButton.setNeedsDisplay()
    }
    
    func setupPartRow() {
        partLabel.attributedText = Style.makeString("Select a part", ofSize: labelSize)
        partNode.textField?.borderStyle = .roundedRect
        partNode.textField?.delegate = self
    }

    func setupPickupRow() {
        pickupLabel.attributedText = Style.makeString("Pickup location", ofSize: labelSize)
        pickupNode.textField?.borderStyle = .roundedRect
        pickupNode.textField?.delegate = self
    }

    func setupEmailRow() {
        emailLabel.attributedText = Style.makeString("Email notification", ofSize: labelSize)
    }
    
    func setupSuspendRow() {
        suspendLabel.attributedText = Style.makeString("Suspend hold", ofSize: labelSize)
        suspendSwitch.switchView?.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
    }
    
    func setupPhoneRow() {
        phoneLabel.attributedText = Style.makeString("Phone notification", ofSize: labelSize)
        phoneSwitch.switchView?.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
        phoneNode.textField?.placeholder = "Phone number"
        phoneNode.textField?.keyboardType = .phonePad
        phoneNode.textField?.borderStyle = .roundedRect
        phoneNode.textField?.delegate = self
    }

    func setupSmsRow() {
        smsLabel.attributedText = Style.makeString("SMS notification", ofSize: labelSize)
        smsSwitch.switchView?.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
        smsNode.textField?.placeholder = "Phone number"
        smsNode.textField?.keyboardType = .phonePad
        smsNode.textField?.borderStyle = .roundedRect
        smsNode.textField?.delegate = self
    }

    func setupCarrierRow() {
        carrierLabel.attributedText = Style.makeString("SMS carrier", ofSize: labelSize)
        carrierNode.textField?.borderStyle = .roundedRect
        carrierNode.textField?.delegate = self
    }
    
    func setupExpirationRow() {
        expirationLabel.attributedText = Style.makeString("Expiration date", ofSize: labelSize)
        expirationNode.textField?.borderStyle = .roundedRect
        expirationNode.textField?.delegate = self
        expirationPickerNode.datePicker?.addTarget(self, action: #selector(expirationChanged(sender:)), for: .valueChanged)
        expirationPickerNode.datePicker?.datePickerMode = .date
    }
    
    func setupThawRow() {
        thawLabel.attributedText = Style.makeString("Activate hold on", ofSize: labelSize)
        thawNode.textField?.borderStyle = .roundedRect
        thawNode.textField?.delegate = self
        thawPickerNode.datePicker?.addTarget(self, action: #selector(thawChanged(sender:)), for: .valueChanged)
        thawPickerNode.datePicker?.datePickerMode = .date
    }
    
    func setupButtonRow() {
        Style.styleButton(asInverse: actionButton)
        Style.setButtonTitle(actionButton, title: isEditHold ? "Update Hold" : "Place Hold")
        actionButton.addTarget(self, action: #selector(holdButtonPressed(sender:)), forControlEvents: .touchUpInside)
    }

    func setupContainerNode() {
        containerNode.automaticallyManagesSubnodes = true
        containerNode.layoutSpecBlock = { node, constrainedSize in
            return ASWrapperLayoutSpec(layoutElement: self.scrollNode)
        }
    }

    func setupScrollNode() {
        scrollNode.automaticallyManagesSubnodes = true
        scrollNode.automaticallyManagesContentSize = true
        scrollNode.layoutSpecBlock = { node, constrainedSize in
            return self.pageLayoutSpec(constrainedSize)
        }
    }

    func pageLayoutSpec(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {

        // summary
        let summarySpec = ASStackLayoutSpec.vertical()
        summarySpec.children = [titleNode, authorNode, formatNode]
        
        // calculate size of widest label, so we can give them all the same width
        let label = App.config.enableHoldPhoneNotification ? phoneLabel : emailLabel
        let labelWidth = label.frame(forTextRange: NSMakeRange(0, label.attributedText?.length ?? 18)).size.width
        let labelMinWidth = ASDimensionMake(labelWidth)

        // TIP: set preferredSize on a wrapped UIView or it ends up being (0,0)
        let switchPreferredSize = CGSize(width: 51, height: 31) // from IB
        let textFieldPreferredSize = CGSize(width: 217, height: 31) // from IB
        let pickerPreferredSize = CGSize(width: 414, height: 162) // from IB

        // shared dimensions
        let rowMinHeight = ASDimensionMake(switchPreferredSize.height)
        let spacing: CGFloat = 4
        
        // part row
        partLabel.style.minWidth = labelMinWidth
        partNode.style.preferredSize = textFieldPreferredSize
        let partButtonSpec = XUtils.makeDisclosureOverlaySpec(partNode, overlay: partDisclosure)
        let partRowSpec = ASStackLayoutSpec.horizontal()
        partRowSpec.alignItems = .center
        partRowSpec.children = [partLabel, partButtonSpec]
        partRowSpec.spacing = spacing
        partRowSpec.style.minHeight = rowMinHeight
        partRowSpec.style.spacingBefore = 28

        // pickup row
        pickupLabel.style.minWidth = labelMinWidth
        pickupNode.style.preferredSize = textFieldPreferredSize
        let pickupButtonSpec = XUtils.makeDisclosureOverlaySpec(pickupNode, overlay: pickupDisclosure)
        let pickupRowSpec = ASStackLayoutSpec.horizontal()
        pickupRowSpec.alignItems = .center
        pickupRowSpec.children = [pickupLabel, pickupButtonSpec]
        pickupRowSpec.spacing = spacing
        pickupRowSpec.style.minHeight = rowMinHeight
        if !hasParts { pickupRowSpec.style.spacingBefore = 28 }

        // email row
        emailLabel.style.minWidth = labelMinWidth
        emailSwitch.style.preferredSize = switchPreferredSize
        let emailRowSpec = makeRowSpec(rowMinHeight: rowMinHeight, spacing: spacing)
        emailRowSpec.children = [emailLabel, emailSwitch]

        // phone row
        phoneLabel.style.minWidth = labelMinWidth
        phoneSwitch.style.preferredSize = switchPreferredSize
        phoneNode.style.flexGrow = 1
        phoneNode.style.flexShrink = 1
        phoneNode.style.preferredSize = textFieldPreferredSize
        let phoneRowSpec = makeRowSpec(rowMinHeight: rowMinHeight, spacing: spacing)
        phoneRowSpec.children = [phoneLabel, phoneSwitch, phoneNode]

        // sms row
        smsLabel.style.minWidth = labelMinWidth
        smsSwitch.style.preferredSize = switchPreferredSize
        smsNode.style.flexGrow = 1
        smsNode.style.flexShrink = 1
        smsNode.style.preferredSize = textFieldPreferredSize
        let smsRowSpec = makeRowSpec(rowMinHeight: rowMinHeight, spacing: spacing)
        smsRowSpec.children = [smsLabel, smsSwitch, smsNode]

        // carrier row
        carrierLabel.style.minWidth = labelMinWidth
        carrierNode.style.preferredSize = textFieldPreferredSize
        let carrierButtonSpec = XUtils.makeDisclosureOverlaySpec(carrierNode, overlay: carrierDisclosure)
        let carrierRowSpec = makeRowSpec(rowMinHeight: rowMinHeight, spacing: spacing)
        carrierRowSpec.children = [carrierLabel, carrierButtonSpec]
        
        // expiration row
        expirationLabel.style.minWidth = labelMinWidth
        expirationNode.style.flexGrow = 1
        expirationNode.style.flexShrink = 1
        expirationNode.style.preferredSize = textFieldPreferredSize
        let expirationRowSpec = makeRowSpec(rowMinHeight: rowMinHeight, spacing: spacing)
        expirationRowSpec.children = [expirationLabel, expirationNode]
        
        // expiration picker row
        expirationPickerNode.style.preferredSize = pickerPreferredSize
        
        // suspend row
        suspendLabel.style.minWidth = labelMinWidth
        suspendSwitch.style.preferredSize = switchPreferredSize
        let suspendRowSpec = makeRowSpec(rowMinHeight: rowMinHeight, spacing: spacing)
        suspendRowSpec.children = [suspendLabel, suspendSwitch]
        
        // thaw row
        thawLabel.style.minWidth = labelMinWidth
        thawNode.style.flexGrow = 1
        thawNode.style.flexShrink = 1
        thawNode.style.preferredSize = textFieldPreferredSize
        let thawRowSpec = makeRowSpec(rowMinHeight: rowMinHeight, spacing: spacing)
        thawRowSpec.children = [thawLabel, thawNode]

        // thaw picker row
        thawPickerNode.style.preferredSize = pickerPreferredSize

        // button row
        actionButton.style.alignSelf = .center
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 48, bottom: 4, right: 48)
        actionButton.style.spacingBefore = 28

        // page
        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.spacing = 4
        pageSpec.alignItems = .stretch
        pageSpec.children = [summarySpec]
        if hasParts { pageSpec.children?.append(partRowSpec) }
        pageSpec.children?.append(contentsOf: [pickupRowSpec, emailRowSpec])
        if App.config.enableHoldPhoneNotification { pageSpec.children?.append(phoneRowSpec) }
        pageSpec.children?.append(contentsOf: [smsRowSpec, carrierRowSpec, expirationRowSpec])
        if expirationPickerVisible { pageSpec.children?.append(ASWrapperLayoutSpec(layoutElement: expirationPickerNode)) }
        if isEditHold { pageSpec.children?.append(contentsOf: [suspendRowSpec, thawRowSpec]) }
        if thawPickerVisible { pageSpec.children?.append(ASWrapperLayoutSpec(layoutElement: thawPickerNode)) }
        pageSpec.children?.append(actionButton)
        
        // inset entire page
        let spec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 4), child: pageSpec)
        print(spec.asciiArtString())
        return spec
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard !didCompleteFetch else { return }
        guard let account = App.account else { return }

        let startOfFetch = Date()
        
        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchUserSettings(account: account))
        promises.append(ActorService.fetchOrgTypes())
        promises.append(ActorService.fetchOrgTreeAndSettings())
        promises.append(PCRUDService.fetchCodedValueMaps())
        promises.append(PCRUDService.fetchSMSCarriers())
        promises.append(fetchPartsData(account: account))
        print("xxx \(promises.count) promises made")

        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()
        
        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            let elapsed = -startOfFetch.timeIntervalSinceNow
            os_log("fetch.elapsed: %.3f (%", log: Gateway.log, type: .info, elapsed, Gateway.addElapsed(elapsed))
            self.didCompleteFetch = true
            self.onDataLoaded()
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }
    }

    func fetchPartsData(account: Account) -> Promise<Void> {
        if !App.config.enablePartHolds || isEditHold {
            return Promise<Void>()
        }
        print("PlaceHold: \(record.title): fetching parts")
        let promise = SearchService.fetchHoldParts(recordID: record.id).then { (parts: [OSRFObject]) -> Promise<(GatewayResponse)> in
            self.parts = parts
            if self.hasParts,
                App.config.enableTitleHoldOnItemWithParts,
                let authtoken = account.authtoken,
                let userID = account.userID,
                let pickupOrgID = account.pickupOrgID
            {
                print("PlaceHold: \(self.record.title): checking titleHoldIsPossible")
                return CircService.titleHoldIsPossible(authtoken: authtoken, userID: userID, targetID: self.record.id, pickupOrgID: pickupOrgID)
            } else {
                return ServiceUtils.makeEmptyGatewayResponsePromise()
            }
        }.done { resp in
            self.titleHoldIsPossible = !resp.failed
            print("PlaceHold: \(self.record.title): titleHoldIsPossible=\(Utils.toString(self.titleHoldIsPossible))")
        }
        return promise
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
        enableNodesWhenReady()
    }
    
    func loadNotifyData() {
        if let val = Utils.coalesce(holdRecord?.hasEmailNotify,
                                    App.account?.defaultNotifyEmail) {
            emailSwitch.switchView?.isOn = val
        }

        // Allow phone_notify to be set even if UX is not visible
        let phoneNumber = Utils.coalesce(holdRecord?.phoneNotify,
                                         App.account?.notifyPhone,
                                         App.valet.string(forKey: "PhoneNumber"))
        phoneNode.textField?.text = phoneNumber
        if let val = Utils.coalesce(holdRecord?.hasPhoneNotify,
                                    App.account?.defaultNotifyPhone),
            let str = phoneNumber,
            !str.isEmpty
        {
            phoneSwitch.switchView?.isOn = val
        }

        let smsNumber = Utils.coalesce(holdRecord?.smsNotify,
                                    App.account?.smsNotify,
                                    App.valet.string(forKey: "SMSNumber"))
        smsNode.textField?.text = smsNumber
        if let val = Utils.coalesce(holdRecord?.hasSmsNotify,
                                    App.account?.defaultNotifySMS),
            let str = smsNumber,
            !str.isEmpty
        {
            smsSwitch.switchView?.isOn = val
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
        pickupNode.textField?.text = orgLabels[selectOrgIndex].trim()
        pickupNode.textField?.isUserInteractionEnabled = true
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
        carrierNode.textField?.text = selectedCarrierName
        carrierNode.textField?.isUserInteractionEnabled = true
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
        partNode.textField?.text = selectedPartLabel
        partNode.textField?.isUserInteractionEnabled = true

        // NB: call transitionLayout on the scrollNode (not partNode, which is not
        // a subnode with Automatic Subnode Management)
        scrollNode.transitionLayout(withAnimation: true, shouldMeasureAsync: false)
    }

    func loadExpirationData() {
        if let date = Utils.coalesce(holdRecord?.expireDate) {
            updateExpirationDate(date)
        }
        if let date = Utils.coalesce(holdRecord?.thawDate) {
            updateThawDate(date)
        }
        if let val = holdRecord?.isSuspended {
            suspendSwitch.switchView?.isOn = val
        }
    }

    @objc func expirationChanged(sender: UIDatePicker) {
        updateExpirationDate(sender.date)
    }
    
    func updateExpirationDate(_ date: Date) {
        expirationDate = date
        let expirationDateStr = OSRFObject.outputDateFormatter.string(from: date)
        expirationNode.textField?.text = expirationDateStr
    }
    
    @objc func thawChanged(sender: UIDatePicker) {
        updateThawDate(sender.date)
    }
    
    func updateThawDate(_ date: Date) {
        thawDate = date
        let dateStr = OSRFObject.outputDateFormatter.string(from: date)
        thawNode.textField?.text = dateStr
    }

    @objc func holdButtonPressed(sender: Any) {
        placeOrUpdateHold()
    }

    @objc func switchChanged(sender: Any) {
        enableNodesWhenReady()
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
        if isOn(phoneSwitch) {
            guard let phoneNotify = phoneNode.textField?.text?.trim(), !phoneNotify.isEmpty else {
                self.showAlert(title: "Error", message: "Phone number field cannot be empty")
                return
            }
            notifyPhoneNumber = phoneNotify
            if App.config.enableHoldPhoneNotification {
                App.valet.set(string: phoneNotify, forKey: "PhoneNumber")
            }
        }
        if isOn(smsSwitch) {
            guard let smsNotify = smsNode.textField?.text?.trim(), !smsNotify.isEmpty else {
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
        
        let promise = CircService.placeHold(authtoken: authtoken, userID: userID, holdType: holdType, targetID: targetID, pickupOrgID: pickupOrg.id, notifyByEmail: isOn(emailSwitch), notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, smsCarrierID: notifyCarrierID, expirationDate: expirationDate)
        promise.done { obj in
            if let _ = obj.getInt("result") {
                // case 1: result is an Int - hold successful
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
            self.presentGatewayAlert(forError: error)
        }
    }

    func doUpdateHold(authtoken: String, holdRecord: HoldRecord, pickupOrg: Organization, notifyPhoneNumber: String?, notifySMSNumber: String?, notifyCarrierID: Int?) {
        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()

        let promise = CircService.updateHold(authtoken: authtoken, holdRecord: holdRecord, pickupOrgID: pickupOrg.id, notifyByEmail: isOn(emailSwitch), notifyPhoneNumber: notifyPhoneNumber, notifySMSNumber: notifySMSNumber, smsCarrierID: notifyCarrierID, expirationDate: expirationDate, suspendHold: isOn(suspendSwitch), thawDate: thawDate)
        promise.done { resp in
            if let _ = resp.str {
                // case 1: result is String - update successful
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
            self.presentGatewayAlert(forError: error)
        }
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

    func isOn(_ node: ASDisplayNode) -> Bool {
        if let switchView = node.switchView, switchView.isOn == true {
            return true
        } else {
            return false
        }
    }

    func makeRowSpec(rowMinHeight: ASDimension, spacing: CGFloat) -> ASStackLayoutSpec {
        let rowSpec = ASStackLayoutSpec.horizontal()
        rowSpec.alignItems = .center
        rowSpec.spacing = spacing
        rowSpec.style.minHeight = rowMinHeight
        return rowSpec
    }
    
    func makeVC(title: String, options: [String], selectedOption: String, selectionChangedHandler: ((Int, String) -> Void)? = nil) -> OptionsViewController? {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return nil }
        vc.title = title
        vc.optionLabels = options
        vc.selectedLabel = selectedOption
        vc.selectionChangedHandler = selectionChangedHandler
        return vc
    }
    
    func makeVC(title: String, options: [String], selectedIndex: Int, selectionChangedHandler: ((Int, String) -> Void)? = nil) -> OptionsViewController? {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return nil }
        vc.title = title
        vc.optionLabels = options
        vc.selectedPath = IndexPath(row: selectedIndex, section: 0)
        vc.selectionChangedHandler = selectionChangedHandler
        return vc
    }

    func scrollToEnd() {
        let sv = self.scrollNode.view
//        print("sv.contentSize.height = \(sv.contentSize.height)")
//        print("sv.bounds.size.height = \(sv.bounds.size.height)")
//        print("sv.contentInset.bottom = \(sv.contentInset.bottom)")
//        print("sv.frame.size.height = \(sv.frame.size.height)")
        let bottomOffset = CGPoint(x: 0, y: sv.contentSize.height - sv.bounds.size.height + sv.contentInset.bottom)
//        print("sv.... -> bottomOffset = \(bottomOffset)")
        sv.setContentOffset(bottomOffset, animated: true)
    }
}

//MARK: - UITextFieldDelegate
extension XPlaceHoldViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField {
        case pickupNode.textField:
            guard let vc = makeVC(title: "Pickup Location", options: orgLabels, selectedIndex: selectedOrgIndex) else { return true }
            vc.selectionChangedHandler = { index, value in
                self.selectedOrgIndex = index
                self.pickupNode.textField?.text = value
            }
            vc.optionIsEnabled = self.orgIsPickupLocation
            vc.optionIsPrimary = self.orgIsPrimary
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case carrierNode.textField:
            guard let vc = makeVC(title: "SMS Carrier", options: carrierLabels, selectedOption: selectedCarrierName) else { return true }
            vc.selectionChangedHandler = { index, value in
                self.selectedCarrierName = value
                self.carrierNode.textField?.text = value
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case partNode.textField:
            guard let vc = makeVC(title: "Select a part", options: partLabels, selectedOption: selectedPartLabel) else { return true }
            vc.selectionChangedHandler = { index, value in
                self.selectedPartLabel = value
                self.partNode.textField?.text = value
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        case expirationNode.textField:
            expirationPickerVisible = !expirationPickerVisible
            if expirationPickerVisible { thawPickerVisible = false }
            self.scrollNode.transitionLayout(withAnimation: true, shouldMeasureAsync: true) {
                guard self.expirationPickerVisible else { return }
                // This is a Good Enough workaround for the fact that on a small screen, transitioning
                // the date picker into view can move the Place Hold button off screen.  This scrolls
                // slightly too high, but it brings the Place Hold button back on screen.  Doing a
                // scrollToEnd() without the delay does not work, because the scrollView.bounds.size.height is
                // not settled yet.  After a short delay it is closer but still not correct.
                firstly {
                    return after(seconds: 0.1)
                }.done {
                    self.scrollToEnd()
                }
            }
            return false
        case thawNode.textField:
            thawPickerVisible = !thawPickerVisible
            if thawPickerVisible { expirationPickerVisible = false }
            self.scrollNode.transitionLayout(withAnimation: true, shouldMeasureAsync: true) {
                guard self.thawPickerVisible else { return }
                firstly {
                    return after(seconds: 0.1)
                }.done {
                    self.scrollToEnd()
                }
            }
            return false
        default:
            return true
        }
    }
}
