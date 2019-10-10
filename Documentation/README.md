# Hemlock Developer Docs

This is a reference guide to material that may be helpful for other developers learning the code, or for me when I inevitably forget the reasoning behind some non-obvious code.

## OpenSRF and the JSON Gateway

*  [OSRF JSON Gateway](OSRF JSON Gateway.md)

## Running Tests

Before you can run the tests, you need to provide login creds for a live Evergreen server.  See ../TestUserData/README.md

## Footnotes

Non-obvious code that gets repeated may have a reference like

```
// See Footnote #x - xyzzy
```

### Footnote #1 - handling the keyboard

See [Handling the Virtual Keyboard](Handling the Keyboard.md)

### Footnote #2 - nav bar isTranslucent

In a Texture VC, set isTranslucent=false on the navigationBar, or else scrollNode allows text to scroll underneath the nav bar.
