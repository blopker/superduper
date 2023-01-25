![SuperDuper](https://raw.githubusercontent.com/blopker/superduper/main/assets/superduper_android_feature.jpg)

[<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Google Play" width="200"/>](https://play.google.com/store/apps/details?id=io.kbl.superduper)

[<img src="https://explore.tivo.com/content/dam/tivo/explore/how-to/app-store-badge.png" alt="Apple Store" width="200"/>](https://testflight.apple.com/join/Tl0UibRY)

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

### What bikes are supported?
Right now only the R/RX models are supported. More models may be supported in the future once more data is aquired. Open a ticket if you have a model that doesn't work (especially if you live in the Bay Area).

### Can this app make the bike go even faster?
Superduper can only add automation around what the official app already does. It cannot, for instance, program the controller. This is the job of the firmware, software that runs on the bike itself.

### Do I have to keep bluetooth and Superduper on at all times?
The way ModeLock works, is that the app maintains a connection to the bike to monitor the bike's mode setting. If the app detects the mode has changed, like through a restart, the app will automatically put the mode back to what you set it at. Therefore, the app needs to be running and bluetooth needs to be on at all times.

## Developers
### Releases
1. Update version, save. Don't commit.
1. Run `make release`
1. Update release notes at provided URL.
1. Upload aab to https://play.google.com/console/u/0/developers/6048825475784314007/app/4973912181639360195/tracks/internal-testing
1. Upload ipa to the Transporter app
1. Release Android on Play store
1. Release iOS on https://appstoreconnect.apple.com/apps/1665290602/appstore/ios/version/inflight
