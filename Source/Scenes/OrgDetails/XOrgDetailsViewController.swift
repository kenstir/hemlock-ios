//
//  XOrgDetailsViewController.swift
//  X is for teXture
//
//  Copyright (C) 2020 Kenneth H. Cox
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

class XOrgDetailsViewController: ASViewController<ASDisplayNode> {
    
    //MARK: - Properties

    var org: Organization?
    var startOfFetch = Date()
    var didCompleteFetch = false
    
    // chooser data
    var selectedOrgName = ""
    var orgLabels: [String] = []
    var orgIsPickupLocation: [Bool] = []
    var orgIsPrimary: [Bool] = []

    var activityIndicator: UIActivityIndicatorView!

    let containerNode = ASDisplayNode()
    let scrollNode = ASScrollNode()

    let orgHeading = ASTextNode()
    let orgChooser = ASTextNode()
    let orgChooserDisclosure = XUtils.makeDisclosureNode()
    let hoursSubheading = ASTextNode()
    let spacerNode = ASDisplayNode()

    //MARK: - Lifecycle
    
    init() {
        super.init(node: containerNode)
        self.title = "Library Info"
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
        org = Organization.find(byId: App.account?.homeOrgID)
        
        setupTitle()
        Style.setupSubtitle(hoursSubheading, str: "Opening Hours")
        setupChooserRow()
        
        // See Footnote #1 - handling the keyboard
        setupContainerNode()
        setupScrollNode()
        
        self.activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        Style.styleActivityIndicator(activityIndicator)
        self.node.view.addSubview(activityIndicator)
        
        enableNodesWhenReady()
    }
    
    func enableNodesWhenReady() {
        orgChooser.textField?.delegate = self
        orgChooser.textField?.isEnabled = didCompleteFetch
        orgChooser.textField?.isUserInteractionEnabled = didCompleteFetch
    }
    
    func setupTitle() {
        Style.setupTitle(orgHeading, str: org?.name ?? "", ofSize: 20)
    }

    func setupChooserRow() {
        orgChooser.attributedText = Style.makeString("Location", ofSize: 14)
        orgChooser.textField?.borderStyle = .roundedRect
        orgChooser.textField?.delegate = self
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

        // heading
        let headingSpec = ASStackLayoutSpec.vertical()
        headingSpec.children = [orgHeading]

        // shared dimensions
        let spacing: CGFloat = 4

        // chooser row
        //orgChooser.style.preferredSize = 200
        let orgChooserButtonSpec = XUtils.makeDisclosureOverlaySpec(orgChooser, overlay: orgChooserDisclosure)
        let orgChooserRowSpec = ASStackLayoutSpec.horizontal()
        orgChooserRowSpec.alignItems = .center
        orgChooserRowSpec.children = [orgChooserButtonSpec]
        orgChooserRowSpec.spacing = spacing
        orgChooserRowSpec.style.spacingBefore = 28

        // page
        let pageSpec = ASStackLayoutSpec.vertical()
        pageSpec.spacing = 4
        pageSpec.alignItems = .stretch
        pageSpec.children = [orgChooserRowSpec, headingSpec]

        // inset entire page
        let spec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 4), child: pageSpec)
        print(spec.asciiArtString())
        return spec
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard !didCompleteFetch else { return }
        //guard let account = App.account else { return }

        self.startOfFetch = Date()

        var promises: [Promise<Void>] = []
        promises.append(ActorService.fetchOrgTypes())
        promises.append(ActorService.fetchOrgTreeAndSettings())
        print("xxx \(promises.count) promises made")

        centerSubview(activityIndicator)
        self.activityIndicator.startAnimating()
        
        firstly {
            when(fulfilled: promises)
        }.done {
            print("xxx \(promises.count) promises fulfilled")
            let elapsed = -self.startOfFetch.timeIntervalSinceNow
            os_log("fetch.elapsed: %.3f (%.3f)", log: Gateway.log, type: .info, elapsed, App.addElapsed(elapsed))
                self.didCompleteFetch = true
            self.onDataLoaded()
        }.ensure {
            self.activityIndicator.stopAnimating()
        }.catch { error in
            self.presentGatewayAlert(forError: error)
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
        loadOrgData()
        enableNodesWhenReady()
    }

    func loadOrgData() {
        orgLabels = Organization.getSpinnerLabels()
        orgIsPickupLocation = Organization.getIsPickupLocation()
        orgIsPrimary = Organization.getIsPrimary()

        var selectOrgIndex = 0
        let defaultOrgID = App.account?.homeOrgID
        for index in 0..<Organization.visibleOrgs.count {
            let org = Organization.visibleOrgs[index]
            if org.id == defaultOrgID {
                selectOrgIndex = index
            }
        }
        
        selectedOrgName = orgLabels[selectOrgIndex].trim()
        self.org = Organization.find(byName: selectedOrgName)
        setupTitle()
    }

    //TODO: if used, factor out and share
    func makeRowSpec(rowMinHeight: ASDimension, spacing: CGFloat) -> ASStackLayoutSpec {
        let rowSpec = ASStackLayoutSpec.horizontal()
        rowSpec.alignItems = .center
        rowSpec.spacing = spacing
        rowSpec.style.minHeight = rowMinHeight
        return rowSpec
    }
    
    //TODO: if used, factor out and share
    func makeVC(title: String, options: [String], selectedOption: String, selectionChangedHandler: ((String) -> Void)? = nil) -> OptionsViewController? {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return nil }
        vc.title = title
        vc.options = options
        vc.selectedOption = selectedOption
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

//MARK: - TextFieldDelegate
extension XOrgDetailsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField {
        case orgChooser.textField:
            guard let vc = makeVC(title: "Pickup Location", options: orgLabels, selectedOption: selectedOrgName) else { return true }
            vc.selectionChangedHandler = { value in
                self.selectedOrgName = value
                self.org = Organization.find(byName: value)
            }
            vc.optionIsEnabled = self.orgIsPickupLocation
            vc.optionIsPrimary = self.orgIsPrimary
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        default:
            return true
        }
    }
}
