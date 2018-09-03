# Handling the Virtual Keyboard

I had a lot of trouble handling the virtual keyboard, e.g. it would appear and occlude the fields you were trying to edit.  Here is the pattern I adopted (with a lot of help from StackOverflow):

## Create View Hierarchy
* Create a ScrollView as the only child of the top View
* Create a Content View as the only child of the ScrollView
* Create all scrolled content as children of the Content View

## Add Constraints
* Add inset=0 on all sides of ScrollView
* Add inset=0 on all sides of Content View
* Add equal width constraint between Content View and top View
* Add insets between the children and the top and bottom of the Content View

## Setup Behavior
In setupViews (called from viewDidLoad), call:
* setupTapToDismissKeyboard(onScrollView:)
* scrollView.setupKeyboardAutoResizer()
