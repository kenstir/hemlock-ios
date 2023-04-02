# Handling the Virtual Keyboard

I had a lot of trouble handling the virtual keyboard, e.g. it would appear and occlude the fields you were trying to edit.  Here is the implentation pattern, for UIKit and Texture ViewControllers.

## UIKit

Adding scroll views is way harder than it should be.  Follow this guide: https://useyourloaf.com/blog/scroll-view-layouts-with-interface-builder/

### Create View Hierarchy
* Create a ScrollView as the only child of the top View
  - Uncheck 'Content Layout Guides' in the size inspector
* Create a Content View as the only child of the ScrollView
* Create all scrolled content as children of the Content View

### Add Constraints
* Add inset=0 on all sides of ScrollView
* Add inset=0 on all sides of Content View
* Add equal width constraint between Content View and top View
* Add insets between the children and the top and bottom of the Content View

### Setup Behavior
In `setupViews()` (called from `viewDidLoad()`), call:
* `setupTapToDismissKeyboard(onScrollView:)`
* `scrollView.setupKeyboardAutoResizer()`

## Texture (AsyncDisplayKit) -- DO NOT USE FOR NEW CODE

See XPlaceHoldsViewController.swift

### Create View Hierarchy
In `setupNodes()` (called from `viewDidLoad()`), call:
* Create a `ASDisplayNode` as the VC's node (containerNode)
* `setupContainerNode()`: Set containerNode.layoutSpectBlock to a closure that wraps `scrollNode`
* `setupScrollNode()`: Set scrollNode.layoutSpecBlock to a closure that returns `pageLayoutSpec()`
* `pageLayoutSpec()`: Returns the ASLayoutSpec of the content to be scrolled.

### Setup Behavior
In `viewWillAppear()`, call:
* `self.setupTapToDismissKeyboard(onScrollView: scrollNode.view)`
* `scrollNode.view.setupKeyboardAutoResizer()`

