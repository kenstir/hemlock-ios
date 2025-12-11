# iOS Release Notes

## UNRELEASED -- 4.3.0 

* internal: Upgrade firebase-ios-sdk to 12.0 to fix rare crashes
* internal: Use fastlane to manage version numbers
* internal: Standardize names of app-specific files and schemes

## 4.2.0

### New
* Improve accessibility with dynamic type and accessibility labels

### Fixes
* Fixed bug preventing Edit Hold from clearing phone/email/sms notify
* internal: Refactor data layer (#66 #67 #68)
* noble: Fixed URL used by Pay All Charges button

## 4.1.0

### New
* Add physical description to Item Details
* Add Hours of Operation notes to Library Info
* Use native filled and gray buttons for improved user experience

### Fixes
* Fixed error "expected object, got empty" when a precat item was checked out
* Fixed rare crashes in Search Results, Holds
* Fixed activity indicator not centered
* indiana: Increased text contrast (WCAG 2.0 level AA)

## 4.0.0

### New
* Remember search options, hold options, and list sort options across app launches

  Add just once/always dialog when changing pickup org
* Bump minimum iOS version to 15.6
* pines: Show hold shelf expiration date
* noble: Change server URL

### Fixes
* internal: Convert to async/await for better performance (#61)
* Fixed crash on iPad tapping Electronic Resources

## 3.3.0

* chore: Upgrade to Xcode 16.4
* fix: Add margins to Library Info screen
* internal: Add Firebase Analytics (indiana, sagecat, owwl)
* owwl: Update in-app logo
* Fix login race error: Class "au" is not registered (pines, indiana, owwl)

## 3.2.1

* acorn: Update URL and developer email

## 3.1.7

* fix: Always load home library settings on startup so optional buttons appear

## 3.1.6

* Show hold shelf expiration date (mo)

## 3.1.5

* fix: Display current email/phone in Library Info, ignoring cache
* internal: Upgrade to Xcode 16.2

## 3.1.4

* internal: Push Notifications Change 1: Enable Opt-In Setting Type to prevent creating database events for push notifications to patrons without the app

## 3.1.3

* Fix 2 buttons that were not using dynamic type
* Fix bug where title and author could be blank when paging forward through search results
* internal: Add Firebase Analytics (cwmars)

## 3.1.2

* Restore warning color for text when item approaching due date
* Increase contrast for text colors to WCAG 2.0 level AA
* New main screen with grid of buttons (noble)
* Add "Clear All Accounts" action if there are multiple accounts

## 3.1.1

* Limit display of Upcoming Closures to 5
* Fix regression in 3.1.0: Error decoding OSRF object: Class "aou" is not registered

## 3.1.0

* Add support for Push Notifications
* internal: Add Firebase Analytics (FA)

## 3.0.0

* Replace main screen with grid of buttons (acorn)

## 2.9.1

* Require part selection for item with parts (pines)

## 2.9.0

* Replace Place Hold and Edit Hold screens for better UX and to shrink app size
  // Replaced ASDK with native controls
  // Disable and dim irrelevant date pickers
* Upgrade dependencies
  // Upgrade to Alamofire 5 and PromiseKit 8
  // Remove ASDK entirely
* Fixed ugly error when hold fails due to alert block

## 2.8.1

* Add Upcoming Closures to Library Info
* Show Place Hold button if any copies exist, and show Electronic Resources button if any URLs exist (#30)
* Highlight due date only when overdue

## 2.8.0

* New feature: Checkout History

## 2.7.1

* cool: Update catalog URL
  // Upgrade to AS giraffe patch 2 and AGP 8.1.2

## 2.7.0

* Tap on author name to search by author
* Fix bug in navigation after successful barcode scan

## 2.6.1

* Item Details screen loads faster and does not flash when selecting an item in the middle of a list
  // Replaced ASDK with native UIPageControl / UIKit

## 2.6.0

* Search Results loading is faster and uses less data
  // Replaced ASDK with native UIKit controls
  // Old: 201 requests, preloaded metadata for all results
  // New:  22 requests, preload visible records and rely on prefetching

## 2.5.1

* Display account expiration date on Show Card screen
* Provide a means for the Evergreen admin to invalidate the app cache
  (by changing hemlock.cache_key setting on orgID 1)

## 2.5.0

* Read and delete system messages in the app, instead of launching the browser and having to login again
* Add sort direction to List Details and remember sort preferences across app launches
* Add link to GALILEO Virtual Library (PINES)

## 2.4.1

* Add ability to sort lists by title/author/pubdate

## 2.4.0

* Scan a barcode to search by ISBN or UPC

## 2.3.4

* Add Events button to main screen, if the home branch has an events calendar URL.
* Change Search keyboard to prevent keyboard from obscuring search options.
* Remove expiration date from Place Hold screen.  You can still add an expiration date to a hold by editing it.
* Fix date picker to use compact mode on iOS 14.2+
* Increase brightness on Show Card screen to improve barcode scanning. (OWWL)

## 2.3.3

* Improved contrast in dark mode (acorn, CW MARS)
* Do not count archived or non-visible messages toward unread badge (PINES)
* Sort lists by publication date, like web site

## 2.3.2

* New feature: My Lists
* Add Additional Content link to Item Details screen (COOL)

## 2.3.1

* Automatically navigate back after selecting an option, such as "Search by" or "Limit to"
* Fix rare issue viewing administrative holds of type F or R


## 2.3.0

* Adjust text according to preferred Text Size (dynamic type)
* Display first + last name when logging in with a barcode
* Add Place Hold button to Copy Info screen
* Add Recommended Reads link to Item Details screen

## 1.0.3

Bug fixes and performance improvements.
* Handle network errors fetching Items Checked Out more gracefully
* Don't reload Items Checked Out while navigating back from Item Details
* Enable vertical scrolling in Item Details
* Fines loads faster
* Fixed issue where sometimes items would display as overdue when they weren't

## 1.0.2

* Fixed "invalid barcode" error for patrons with barcodes starting with "D"
* Fixed broken display of copy hold
* Fixed error when renewing floating asset copy
* Fixed crash when renew fails for more than one reason
* Faster startup of Search and Details screens
