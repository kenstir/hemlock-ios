//
//  SearchViewController.swift
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

struct SearchParameters {
    let text: String
    let searchClass: String
    let searchFormat: String?
    let organizationShortName: String?
}

class SearchViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var scopeControl: UISegmentedControl!
    @IBOutlet weak var formatPicker: McTextField!
    @IBOutlet weak var locationPicker: McTextField!
    @IBOutlet weak var searchButton: UIButton!
    
    weak var activityIndicator: UIActivityIndicatorView!
    
    let scopes = App.searchScopes
    let formats = Format.getSpinnerLabels()
    var orgLabels: [String] = []
    var didCompleteFetch = false

    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        searchButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !didCompleteFetch {
            fetchData()
        }
    }
    
    //MARK: - Functions
    
    func fetchData() {
        guard let account = App.account else
        {
            presentGatewayAlert(forError: HemlockError.sessionExpired())
            return //TODO: add analytics
        }

        var promises: [Promise<Void>] = []        
        promises.append(ActorService.fetchOrgTypesArray())
        promises.append(ActorService.fetchOrgTree())
        promises.append(ActorService.fetchUserSettings(account: account))
        promises.append(SearchService.fetchCopyStatusAll())

        self.activityIndicator.startAnimating()

        firstly {
            when(fulfilled: promises)
        }.done {
            self.setupLocationPicker()
            self.searchButton.isEnabled = true
            self.didCompleteFetch = true
        }.catch { error in
            self.presentGatewayAlert(forError: error)
        }.finally {
            self.activityIndicator.stopAnimating()
        }
    }
    
    func setupViews() {
        setupActivityIndicator()        
        self.setupHomeButton()
        setupSearchBar()
        setupScopeControl()
        setupFormatPicker()
        //setupLocationPicker() // has to wait until fetchData
        setupSearchButton()
    }
    
    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }
    
    func setupSearchBar() {
        Style.styleSearchBar(searchBar)
    }
    
    func setupScopeControl() {
        scopeControl.removeAllSegments()
        Style.styleSegmentedControl(scopeControl)
        for i in 0..<scopes.count {
            scopeControl.insertSegment(withTitle: scopes[i], at: i, animated: false)
        }
        scopeControl.selectedSegmentIndex = 0 //TODO: better initial value
    }
    
    func setupFormatPicker() {
        let mcInputView = McPicker(data: [formats])
        mcInputView.backgroundColor = .gray
        mcInputView.backgroundColorAlpha = 0.25
        mcInputView.fontSize = 20
        formatPicker.text = formats[0] //TODO: better initial value
        formatPicker.inputViewMcPicker = mcInputView
        formatPicker.doneHandler = { [weak formatPicker] (selections) in
            formatPicker?.text = selections[0]!
        }
        formatPicker.textFieldWillBeginEditingHandler = { (selections) in
            self.searchBar.resignFirstResponder()
        }
    }
    
    func setupLocationPicker() {
        self.orgLabels = Organization.getSpinnerLabels()
        var selectOrgIndex = 0
        let defaultSearchLocation = App.account?.searchOrgID
        for index in 0..<Organization.orgs.count {
            let org = Organization.orgs[index]
            if org.id == defaultSearchLocation {
                selectOrgIndex = index
            }
        }

        let mcInputView = McPicker(data: [orgLabels])
        Style.stylePicker(asOrgPicker: mcInputView)
        mcInputView.pickerSelectRowsForComponents = [0: [selectOrgIndex: true]]
        locationPicker.text = orgLabels[selectOrgIndex].trim()
        locationPicker.inputViewMcPicker = mcInputView
        locationPicker.doneHandler = { [weak locationPicker] (selections) in
            locationPicker?.text = selections[0]!.trim()
        }
        locationPicker.textFieldWillBeginEditingHandler = { (selections) in
            self.searchBar.resignFirstResponder()
        }
    }
    
    func setupSearchButton() {
        searchButton.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asInverse: searchButton)
    }
    
    @objc func buttonPressed(sender: UIButton) {
        doSearch()
    }

    func doSearch() {
        guard let searchText = searchBar.text?.trim(), searchText.count > 0 else {
            self.showAlert(title: "Nothing to search for", message: "Search words cannot be empty")
            return
        }
        guard let formatText = formatPicker.text,
            let searchOrg = Organization.getShortName(forName: locationPicker.text?.trim()) else
        {
            Analytics.logError(code: .shouldNotHappen, msg: "error during prepare", file: #file, line: #line)
            self.showAlert(title: "Internal error", message: "Internal error preparing for search")
            return
        }
        let searchClass = scopes[scopeControl.selectedSegmentIndex].lowercased()
        let searchFormat = Format.getSearchFormat(forSpinnerLabel: formatText)
        let params = SearchParameters(text: searchText, searchClass: searchClass, searchFormat: searchFormat, organizationShortName: searchOrg)
        let vc = XResultsViewController()
        vc.searchParameters = params
        print("--- searchParams \(String(describing: vc.searchParameters))")
        self.navigationController?.pushViewController(vc, animated: true)
    }

}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
        //called on every key press, do not search here
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        doSearch()
    }
}
