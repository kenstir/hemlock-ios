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

class SearchViewController: UIViewController {
    
    //MARK: - Properties

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var scopeControl: UISegmentedControl!
    @IBOutlet weak var formatPicker: McTextField!
    @IBOutlet weak var locationPicker: McTextField!

    let scopes = App.searchScopes
    let formats = App.searchFormats
    let organizations = App.organizations
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        // searchBar
        searchBar.tintColor = AppSettings.themeBackgroundColor

        setupScopeControl()
        setupFormatPicker()
        setupLocationPicker()
    }
    
    func setupScopeControl() {
        scopeControl.removeAllSegments()
        scopeControl.tintColor = AppSettings.themeBackgroundColor
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
    }
    
    @IBAction func buttonPressed(sender: UIButton) {
        print("xxx button pressed - \(sender)")
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String) {
        //called on every key press, do not search here
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("xxx searchBarSearchButtonClicked")
    }
    
    func searchBar(_ searchBar: UISearchBar,
                   selectedScopeButtonIndexDidChange selectedScope: Int) {
        print("xxx scope: \(scopes[selectedScope])")
    }
}
