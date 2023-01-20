![SuperDuper](https://raw.githubusercontent.com/blopker/superduper/main/assets/superduper_android_feature.jpg)

Google Play Store: https://play.google.com/store/apps/details?id=io.kbl.superduper

This app is an alternative the official Super ebike app. Control your bike with no account or external server needed. Additionally, it has ModeLock, which will keep your bike on whatever mode you set it at, even through bike restarts.

## Getting Started

- Open the app and select the "Start scan" button. This will find any bikes around you that are on and save the details into the app. 
- When you see your bike, stop the scan. 
- Select your bike in the list. 
- Then hit "Start watch". 
- While the watch is running your bike will reset to 4/4 mode around every 10 seconds.

**Make sure your bluetooth is on**

## FAQ
### I'm having an issue
I'm sorry! Please start by making sure you have the newest app from the app store. After that, please submit the issue to https://github.com/blopker/superduper/issues. It helps to have a way I can reproduce the issue, with screenshots or video. Alternatively, you may have luck either clearing all the app's data or reinstalling it.

### What up with the bike names?
The bike names are randomly generated from your bike's unique ID, to make it easier to read and differentiate between multiple bikes.

### What are the supported devices?
Right now the app requires Android 11+ and iOS 12+. 

## Developers
### Releases
1. Update version, save. Don't commit.
1. Run `make release`
1. Update release notes at provided URL.
1. Upload aab to https://play.google.com/console/u/0/developers/6048825475784314007/app/4973912181639360195/tracks/internal-testing
1. Upload ipa to the Transporter app
1. Release Android on Play store
1. Release iOS on https://appstoreconnect.apple.com/apps/1665290602/appstore/ios/version/inflight
