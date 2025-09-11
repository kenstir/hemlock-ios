//
//  Copyright (c) 2025 Kenneth H. Cox
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
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

import UIKit
import os.log

struct SearchParameters {
    let text: String
    let searchClass: String
    let searchFormat: String?
    let organizationShortName: String?
    let sort: String?
}

class SearchViewController: UIViewController {

    //MARK: - Properties

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var optionsTable: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    
    weak var activityIndicator: UIActivityIndicatorView!
    
    static let searchKeywordKeyword = "keyword"
    static let searchKeywordIdentifier = "identifier"
    static let searchKeywordAuthor = "author"
    let searchClassLabels = ["Keyword","Title","Author","Subject","Series","ISBN or UPC"]
    let searchClassKeywords = [searchKeywordKeyword,"title",searchKeywordAuthor,"subject","series",searchKeywordIdentifier]
    var selectedSearchClassIndex = 0
    var formatLabels: [String] = []
    var orgLabels: [String] = []

    var options: [StringOption] = []
    let searchClassIndex = 0
    let searchFormatIndex = 1
    let searchLocationIndex = 2

    var barcodeToSearchFor: String? = nil
    var authorToSearchFor: String? = nil

    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // deselect row when navigating back
        if let indexPath = optionsTable.indexPathForSelectedRow {
            optionsTable.deselectRow(at: indexPath, animated: true)
        }

        doSearchOnStartup()
    }

    //MARK: - Functions

    func setupViews() {
        setupActivityIndicator()
        optionsTable.delegate = self
        optionsTable.dataSource = self
        optionsTable.tableFooterView = UIView() // prevent ghost rows at end of table
        self.setupHomeButton()
        setupSearchBar()
        setupOptionsTable()
        setupSearchButton()
    }
    
    func setupActivityIndicator() {
        activityIndicator = addActivityIndicator()
        Style.styleActivityIndicator(activityIndicator)
    }
    
    func setupSearchBar() {
        Style.styleSearchBar(searchBar)

        // The idea here was to use a .done keyboard for small screens,
        // where the keyboard obscures the search options.  But that
        // doesn't prevent cases where dynamic type is extra huge, so
        // for now always use .done instead of .search.
        //if UIScreen.main.bounds.height < 667
        searchBar.returnKeyType = .done

        var image = loadAssetImage(named: "barcode_scan")
        if #available(iOS 13.0, *) {
            image = image?.withTintColor(Style.secondaryLabelColor)
        }
        searchBar.showsBookmarkButton = true
        searchBar.setImage(image, for: .bookmark, state: .normal)
    }

    func setupOptionsTable() {
        options = []
        options.append(StringOption(
            key: AppState.Key.searchClass,
            title: "Search by",
            defaultValue: searchClassKeywords[0],
            optionLabels: searchClassLabels,
            optionValues: searchClassKeywords))
        options.append(StringOption(
            key: AppState.Key.searchFormat,
            title: "Limit to",
            defaultValue: "",
            optionLabels: CodedValueMap.searchFormatSpinnerLabels(),
            optionValues: CodedValueMap.searchFormatSpinnerValues()))
        options.append(StringOption(
            key: AppState.Key.searchOrg,
            title: "Search within",
            defaultValue: Organization.find(byId: App.account?.searchOrgID)?.shortname ?? "",
            optionLabels: Organization.getSpinnerLabels(),
            optionValues: Organization.getShortNames(),
            optionIsPrimary: Organization.getIsPrimary()))

        for option in options {
            option.load()
        }

        optionsTable.reloadData()
    }
    
    func setupSearchButton() {
        searchButton.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
        Style.styleButton(asInverse: searchButton)
    }

    func doSearchOnStartup() {
        // handle barcode when navigating back
        if let barcode = barcodeToSearchFor {
            searchBar.textField?.text = barcode
            barcodeToSearchFor = nil
            Task {
                self.doSearch(byBarcode: barcode)
            }
            return
        }

        // handle author when navigating
        if let author = authorToSearchFor {
            searchBar.textField?.text = author
            authorToSearchFor = nil
            Task {
                self.doSearch(byAuthor: author)
            }
            return
        }
    }

    @MainActor
    func doSearch(byBarcode barcode: String) {
        let entry = options[searchClassIndex]
        entry.select(byValue: SearchViewController.searchKeywordIdentifier)
        self.optionsTable.reloadData()
        doSearch()
    }

    @MainActor
    func doSearch(byAuthor author: String) {
        let entry = options[searchClassIndex]
        entry.select(byValue: SearchViewController.searchKeywordAuthor)
        self.optionsTable.reloadData()
        doSearch()
    }

    @objc func buttonPressed(sender: UIButton) {
        doSearch()
    }

    @MainActor
    func doSearch() {
        guard let searchText = searchBar.text?.trim(), !searchText.isEmpty else {
            self.showAlert(title: "Nothing to search for", message: "Search words cannot be empty")
            return
        }
        let searchClass = options[searchClassIndex].value
        let searchFormat = options[searchFormatIndex].value
        let searchOrg = options[searchLocationIndex].value
        let params = SearchParameters(text: searchText, searchClass: searchClass, searchFormat: searchFormat, organizationShortName: searchOrg, sort: App.config.sort)

        if let vc = UIStoryboard(name: "Results", bundle: nil).instantiateInitialViewController() as? ResultsViewController {
            vc.searchParameters = params
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func searchClass(forLabel label: String) -> String {
        let index = searchClassLabels.firstIndex(of: label) ?? 0
        return searchClassKeywords[index]
    }
}

extension UISearchBar {
    var textField: UITextField? {
        if #available(iOS 13.0, *) {
            return searchTextField
        } else {
            let subViews = subviews.flatMap { $0.subviews }
            let textField = (subViews.filter { $0 is UITextField }).first as? UITextField
            return textField
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.returnKeyType == .done {
            searchBar.textField?.resignFirstResponder()
        } else {
            doSearch()
        }
    }
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        let grantMessage = "Grant access to the camera in the Settings app under Privacy >> Camera"
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [self] granted in
                // NB: non-main thread
                DispatchQueue.main.async {
                    if !granted {
                        self.showAlert(title: "Notice", message: "Can't scan a barcode without camera access.")
                    } else {
                        self.showScanBarcodeVC()
                    }
                }
            }
        case .denied:
            showAlert(title: "Camera access was denied", message: grantMessage)
        case .restricted:
            showAlert(title: "Camera access is restricted", message: grantMessage)
        default:
            showScanBarcodeVC()
        }
    }

    func showScanBarcodeVC() {
        guard let vc = UIStoryboard(name: "ScanBarcode", bundle: nil).instantiateInitialViewController() as? ScanBarcodeViewController else { return }
        vc.barcodeScannedHandler = { barcode in
            self.barcodeToSearchFor = barcode
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

//MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Options"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchOptionsCell", for: indexPath)

        let entry = options[indexPath.row]
        cell.textLabel?.text = entry.title
        cell.detailTextLabel?.text = entry.description
        if indexPath.row == searchClassIndex {
            os_log("[search] cellForRowAt value=%@", entry.description)
        }

        return cell
    }
}

//MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = UIStoryboard(name: "Options", bundle: nil).instantiateInitialViewController() as? OptionsViewController else { return }
        
        let entry = options[indexPath.row]
        vc.title = entry.title
        vc.optionLabels = entry.optionLabels
        vc.optionValues = entry.optionValues
        vc.optionIsEnabled = entry.optionIsEnabled
        vc.optionIsPrimary = entry.optionIsPrimary
        vc.selectedPath = IndexPath(row: entry.selectedIndex, section: 0)

        vc.selectionChangedHandler = { index, trimmedLabel in
            os_log("[search] selection    value=%@", trimmedLabel)
            entry.selectedIndex = index
            entry.description = trimmedLabel
            entry.value = entry.optionValues.isEmpty ? trimmedLabel : entry.optionValues[index]
            entry.save()
            self.optionsTable.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }
}
