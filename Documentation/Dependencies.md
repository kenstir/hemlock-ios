# Dependencies

This a brief attempt to rationalize this project's dependencies and any
relationships between them.  Now that AsyncDisplayKit is removed, it
becomes simpler but not trivial.

## Alamofire - http layer

Might be overkill for what we do here, but I started with it, it is well
maintained, and it has not been a problem.

## PromiseKit - promises

PMK is the center of all async behavior in the app, and many APIs are
built to return Promise<>.  If I started today, I might choose SwiftUI +
async, but I'm not going to switch now.

PMKAlamofire is the integration layer.

## PINRemoteImage - async image loading

PINRemoteImage results in smooth async image loading where it matters -
Search Results.  I tried replacing it with Alamofire 4 image loading, and
it was janky, so I backed off.  I haven't tried with Alamofire 5.

Sadly, PINRemoteImage has 2 dependencies and all together they do not seem
to be so well maintained.  The relationships are:

```mermaid
flowchart TD
    PINRemoteImage -> PINCache;
    PINRemoteImage -> PINOperation;
    PINCache -> PINOperation;
```

This dependency chain is a giant pain to deal with when new Xcode releases
come out that increase the minimum IPHONEOS_DEPLOYMENT_TARGET.  I maintain
forks of all 3 projects on branch kenstir/main, and then tag them in this
order:
1. PINOperation
2. PINCache
3. PINRemoteImage

At each stage, you need to
a. Update any versions in ./Cartfile
b. Run ./update to build an xcframework
c. Edit the .xcodeproj to replace every framework with an xcframework
d. Commit and add a new tag

If ./update fails with something like
```
$ ./update
*** Fetching PINOperation
*** Fetching PINCache
A shell task (/usr/bin/env git fetch --prune --quiet https://github.com/kenstir/PINCache.git refs/tags/*:refs/tags/* +refs/heads/*:refs/heads/* (launched in /Users/kenstir/Library/Caches/org.carthage.CarthageKit/dependencies/PINCache)) failed with exit code 1
```
then you need to make sure everything including tags is pushed to origin,
and then clear the Carthage cache and try again:
```
$ rm -rf ~/Library/Caches/org.carthage.CarthageKit/*
```

## Valet - keychain storage

Valet made it so simple to store accounts and authtokens in the iOS keychain.

## Toast-Swift - toasts

Timed popup messages are not so big a deal, but this is a tiny package.

## zxingify-objc - barcode generation

Used to display the barcode on the Show Card screen.
