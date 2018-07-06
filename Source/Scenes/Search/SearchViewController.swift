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
    
    let scopes = App.searchScopes
    let formats = Format.getSpinnerLabels()
    let organizations = App.organizations
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        setupSearchBar()
        setupScopeControl()
        setupFormatPicker()
        setupLocationPicker()
        setupSearchButton()
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
        let mcInputView = McPicker(data: [organizations])
        mcInputView.backgroundColor = .gray
        mcInputView.backgroundColorAlpha = 0.25
        locationPicker.text = organizations[0] //TODO: better initial value
        locationPicker.inputViewMcPicker = mcInputView
        locationPicker.doneHandler = { [weak locationPicker] (selections) in
            locationPicker?.text = selections[0]!
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
        guard let searchText = searchBar.text, searchText.count > 0 else {
            self.showAlert(title: "Nothing to search for", message: "Search words cannot be empty")
            return
        }
        guard let formatText = formatPicker.text else {
            Analytics.logError(code: .shouldNotHappen, msg: "error during prepare", file: #file, line: #line)
            return
        }
        let params = SearchParameters(text: searchText, searchClass: scopes[scopeControl.selectedSegmentIndex].lowercased(), searchFormat: Format.getSearchFormat(forSpinnerLabel: formatText), organizationShortName: Organization.findShortName(forName: locationPicker?.text))
        let vc = XResultsViewController()
        vc.searchParameters = params
        print("--- searchParams \(String(describing: vc.searchParameters))")
        self.navigationController?.pushViewController(vc, animated: true)
    }

    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination
        guard
            let resultsVC = vc as? ResultsViewController,
            let searchText = searchBar.text,
            let formatText = formatPicker.text else
        {
            Analytics.logError(code: .shouldNotHappen, msg: "error during prepare", file: #file, line: #line)
            return
        }
        let params = SearchParameters(text: searchText, searchClass: scopes[scopeControl.selectedSegmentIndex].lowercased(), searchFormat: Format.getSearchFormat(forSpinnerLabel: formatText), organizationShortName: Organization.findShortName(forName: locationPicker?.text))
        resultsVC.searchParameters = params
    }*/
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
