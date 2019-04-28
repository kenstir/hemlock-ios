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

class XPlaceHoldViewController: ASViewController<ASDisplayNode> {
    
    //MARK: - Properties

    let record: MBRecord
    let formats = Format.getSpinnerLabels()
    var orgLabels: [String] = []
    var carrierLabels: [String] = []
    var selectedOrgName = ""
    var selectedCarrierName = ""
    var startOfFetch = Date()

    weak var activityIndicator: UIActivityIndicatorView!
    var pickupTextField: UITextField? { return pickupNode.view as? UITextField }
    var phoneTextField: UITextField? { return phoneNode.view as? UITextField }
    var smsTextField: UITextField? { return smsNode.view as? UITextField }
    var carrierTextField: UITextField? { return carrierNode.view as? UITextField }
    var expirationTextField: UITextField? { return expirationNode.view as? UITextField }

    let containerNode = ASDisplayNode()
    let scrollNode = ASScrollNode()

    let titleNode = ASTextNode()
    let authorNode = ASTextNode()
    let formatNode = ASTextNode()
    let spacerNode = ASDisplayNode()
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
    let expirationDisclosure = XUtils.makeDisclosureNode()
    let placeHoldButton = ASButtonNode()

    //MARK: - Lifecycle
    
    init(record: MBRecord) {
        self.record = record

        super.init(node: containerNode)
        self.title = "Place Hold"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Setup
    
    func setupNodes() {
        Style.setupTitle(titleNode, str: record.title)
        Style.setupSubtitle(authorNode, str: record.author)
        Style.setupSubtitle(formatNode, str: record.format)
        
        setupPickupRow()
        setupEmailRow()
        setupPhoneRow()
        setupSmsRow()
        setupCarrierRow()
        setupExpirationRow()
        setupButtonRow()
        
        // See Footnote #1 - handling the keyboard
        setupContainerNode()
        setupScrollNode()
    }
    
    //MARK: - Lifecycle
    
    // NB: viewDidLoad on an ASViewController gets called during construction,
    // before there is any UI.  Do not fetchData here.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        setupNodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // See Footnote #2 - disable nav bar isTranslucent
        navigationController?.navigationBar.isTranslucent = false
        
        self.setupTapToDismissKeyboard(onScrollView: scrollNode.view)
        scrollNode.view.setupKeyboardAutoResizer()
    }

    //MARK: - Layout
    
    func setupPickupRow() {
        pickupLabel.attributedText = Style.makeString("Pickup location", ofSize: 14)
        pickupTextField?.borderStyle = .roundedRect
        pickupTextField?.delegate = self
    }

    func setupEmailRow() {
        emailLabel.attributedText = Style.makeString("Email notification", ofSize: 14)
    }
    
    func setupPhoneRow() {
        phoneLabel.attributedText = Style.makeString("Phone notification", ofSize: 14)
        phoneTextField?.placeholder = "Phone number"
        phoneTextField?.keyboardType = .phonePad
        phoneTextField?.borderStyle = .roundedRect
        phoneTextField?.delegate = self
    }

    func setupSmsRow() {
        smsLabel.attributedText = Style.makeString("SMS notification", ofSize: 14)
        smsTextField?.placeholder = "Phone number"
        smsTextField?.keyboardType = .phonePad
        smsTextField?.borderStyle = .roundedRect
        smsTextField?.delegate = self
    }

    func setupCarrierRow() {
        carrierLabel.attributedText = Style.makeString("SMS carrier", ofSize: 14)
        carrierTextField?.borderStyle = .roundedRect
        carrierTextField?.delegate = self
    }
    
    func setupExpirationRow() {
        expirationLabel.attributedText = Style.makeString("Expiration date", ofSize: 14)
        expirationTextField?.borderStyle = .roundedRect
        expirationTextField?.delegate = self
    }
    
    func setupButtonRow() {
        Style.styleButton(asInverse: placeHoldButton)
        Style.setButtonTitle(placeHoldButton, title: "Place Hold")
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

        // shared dimensions
        let rowMinHeight = ASDimensionMake(switchPreferredSize.height)
        let spacing: CGFloat = 4

        // pickup row
        pickupLabel.style.minWidth = labelMinWidth
        pickupNode.style.preferredSize = textFieldPreferredSize
        let pickupButtonSpec = XUtils.makeDisclosureOverlaySpec(pickupNode, overlay: pickupDisclosure)
        let pickupRowSpec = ASStackLayoutSpec.horizontal()
        pickupRowSpec.alignItems = .center
        pickupRowSpec.children = [pickupLabel, pickupButtonSpec]
        pickupRowSpec.spacing = spacing
        pickupRowSpec.style.minHeight = rowMinHeight
        pickupRowSpec.style.spacingBefore = 28

        // email row
        emailLabel.style.minWidth = labelMinWidth
        emailSwitch.style.preferredSize = switchPreferredSize
        let emailRowSpec = ASStackLayoutSpec.horizontal()
        emailRowSpec.alignItems = .center
        emailRowSpec.children = [emailLabel, emailSwitch]
        emailRowSpec.spacing = spacing

        // phone row
        phoneLabel.style.minWidth = labelMinWidth
        phoneSwitch.style.preferredSize = switchPreferredSize
        phoneNode.style.flexGrow = 1
        phoneNode.style.flexShrink = 1
        phoneNode.style.preferredSize = textFieldPreferredSize
        let phoneRowSpec = ASStackLayoutSpec.horizontal()
        phoneRowSpec.alignItems = .center
        phoneRowSpec.children = [phoneLabel, phoneSwitch, phoneNode]
        phoneRowSpec.spacing = spacing

        // sms row
        smsLabel.style.minWidth = labelMinWidth
        smsSwitch.style.preferredSize = switchPreferredSize
        smsNode.style.flexGrow = 1
        smsNode.style.flexShrink = 1
        smsNode.style.preferredSize = textFieldPreferredSize
        let smsRowSpec = ASStackLayoutSpec.horizontal()
        smsRowSpec.alignItems = .center
        smsRowSpec.children = [smsLabel, smsSwitch, smsNode]
        smsRowSpec.spacing = spacing
        smsRowSpec.style.minHeight = rowMinHeight

        // carrier row
        carrierLabel.style.minWidth = labelMinWidth
        carrierNode.style.preferredSize = textFieldPreferredSize
        let carrierButtonSpec = XUtils.makeDisclosureOverlaySpec(carrierNode, overlay: carrierDisclosure)
        let carrierRowSpec = ASStackLayoutSpec.horizontal()
        carrierRowSpec.alignItems = .center
        carrierRowSpec.children = [carrierLabel, carrierButtonSpec]
        carrierRowSpec.spacing = spacing
        carrierRowSpec.style.minHeight = rowMinHeight
        
        // expiration row
        expirationLabel.style.minWidth = labelMinWidth
        expirationNode.style.preferredSize = textFieldPreferredSize
        let expirationButtonSpec = XUtils.makeDisclosureOverlaySpec(expirationNode, overlay: expirationDisclosure)
        let expirationRowSpec = ASStackLayoutSpec.horizontal()
        expirationRowSpec.alignItems = .center
        expirationRowSpec.children = [expirationLabel, expirationButtonSpec]
        expirationRowSpec.spacing = spacing
        expirationRowSpec.style.minHeight = rowMinHeight

        // button row
        placeHoldButton.style.alignSelf = .center
        placeHoldButton.style.preferredSize = CGSize(width: 200, height: 33)
        placeHoldButton.style.spacingBefore = 28

        // page
        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.spacing = 4
        pageSpec.alignItems = .stretch
        pageSpec.children = [summarySpec, pickupRowSpec, emailRowSpec, smsRowSpec, carrierRowSpec, expirationRowSpec, placeHoldButton]
        if App.config.enableHoldPhoneNotification {
            pageSpec.children?.insert(phoneRowSpec, at: 3)
        }

        // inset entire page
        let spec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 4), child: pageSpec)
        print(spec.asciiArtString())
        return spec
     }
}

extension XPlaceHoldViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("xxx textFieldShouldReturn")
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("xxx textFieldShouldBeginEditing")
        switch textField {
        case phoneTextField:
            return true
        case smsTextField:
            return true
        default:
            return true
        }
    }
}
