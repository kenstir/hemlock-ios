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

    @IBOutlet weak var formatTextField: McTextField!
    
    @IBOutlet weak var formatPicker: UIPickerView!
    @IBOutlet weak var libraryButton: UIButton!
    
    var items = App.searchFormats
    let scopes = ["Keyword","Title","Author","Subject","Series"]
    let formats = App.searchFormats
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    //MARK: - Functions
    
    func setupViews() {
        // searchBar
        searchBar.tintColor = AppSettings.themeBackgroundColor

        // scopeControl
        scopeControl.removeAllSegments()
        scopeControl.tintColor = AppSettings.themeBackgroundColor
        for i in 0..<scopes.count {
            scopeControl.insertSegment(withTitle: scopes[i], at: i, animated: false)
        }
        scopeControl.selectedSegmentIndex = 0

        // picker
        let data = [formats]
        let mcInputView = McPicker(data: data)
        mcInputView.backgroundColor = .gray
        mcInputView.backgroundColorAlpha = 0.25
        formatTextField.inputViewMcPicker = mcInputView
        formatTextField.doneHandler = { [weak formatTextField] (selections) in
            formatTextField?.text = selections[0]!
        }
        formatTextField.selectionChangedHandler = { [weak formatTextField] (selections, componentThatChanged) in
            formatTextField?.text = selections[componentThatChanged]!
        }
        formatTextField.cancelHandler = { [weak formatTextField] in
            formatTextField?.text = "Cancelled."
        }
        formatTextField.textFieldWillBeginEditingHandler = { [weak formatTextField] (selections) in
            if formatTextField?.text == "" {
                // Selections always default to the first value per component
                formatTextField?.text = selections[0]
            }
        }

        // formatButton
        //Theme.styleOutlineButton(button: formatButton, color: AppSettings.themeBackgroundDark2)
        //formatButton.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)

        // formatPicker
        formatPicker.tintColor = AppSettings.themeBackgroundColor
        formatPicker.dataSource = self
        formatPicker.delegate = self
        formatPicker.reloadAllComponents()

        // libraryButton
//        Theme.styleOutlineButton(button: libraryButton, color: AppSettings.themeBackgroundDark2)
//        libraryButton.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
    }
    
    @IBAction func buttonPressed(sender: UIButton) {
        print("xxx button pressed - \(sender)")
        formatPicker.isHidden = false
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
        if pickerView == formatPicker {
            let str = formats[row]
            print("xxx selected row \(str)")
        } else {
            print("xxx selected row \(row)")
        }
        pickerView.isHidden = true
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
