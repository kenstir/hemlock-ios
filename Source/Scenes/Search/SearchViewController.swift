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
    @IBOutlet weak var formatPicker: UIPickerView!
    @IBOutlet weak var locationPicker: UIPickerView!
    
    var items = App.searchFormats
    let scopes = ["Keyword","Title","Author","Subject","Series"]
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        // setup searchBar
        searchBar.tintColor = AppSettings.themeBackgroundColor

        // setup scopeControl
        scopeControl.removeAllSegments()
        scopeControl.tintColor = AppSettings.themeBackgroundColor
        for i in 0..<scopes.count {
            scopeControl.insertSegment(withTitle: scopes[i], at: i, animated: false)
        }
        scopeControl.selectedSegmentIndex = 0
        
        // setup formatPicker
        formatPicker.tintColor = AppSettings.themeBackgroundColor
        formatPicker.dataSource = self
        formatPicker.delegate = self
        print("setup - reload")
        formatPicker.reloadAllComponents()
        print("setup - 1")
        let a = formatPicker.numberOfComponents
        print("setup - 2 \(a)")
        let b = formatPicker.numberOfRows(inComponent: 0)
        print("setup - 3 \(b)")
        let c = formatPicker.rowSize(forComponent: 0)
        print("setup - 4 \(c)")
        let d = formatPicker.view(forRow: 0, forComponent: 0)
        print("setup - 5 \(d)")
        print("done")
    }
}

extension SearchViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        print("xxx numberOfComponents")
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        print("xxx numberOfRowsInComponent")
        return items.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        print("xxx titleForRow")
        return items[row]
    }
    
//    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
//        print("xxx rowHeight")
//        return 37
//    }

    /*
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        print("xxx viewForRow")
        if let tmpView = view as? UILabel {
            print("  - label")
            tmpView.text = items[row]
            return tmpView
        } else if let tmpView = view as? UITextField {
            print("  - textfield")
            return tmpView
        } else if let tmpView = view as? UITextView {
            print("  - textview")
            return tmpView
        } else if let tmpView = view {
            print("  - unknown view")
            return tmpView
        }
        let newView = UILabel()
        newView.text = items[row]
        return newView
    }
    */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("xxx selected row \(row)")
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
