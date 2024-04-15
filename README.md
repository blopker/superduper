![Superduper](https://raw.githubusercontent.com/blopker/superduper/main/assets/superduper_android_feature.jpg)

[<img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Google Play" width="200"/>](https://play.google.com/store/apps/details?id=io.kbl.superduper)

[<img src="https://explore.tivo.com/content/dam/tivo/explore/how-to/app-store-badge.png" alt="Apple Store" width="200"/>](https://testflight.apple.com/join/Tl0UibRY)

This app is an alternative the official Super ebike app.

Features:

- No account or internet connection required
- Quickly switch between multiple bikes
- Lock settings, like Mode, to automatically switch when the bike is turned on and the app is running
- (Android only) Background Lock, which will keep your bike on whatever settings you set it at, even the phone is locked
- Open source

## Getting Started

- Open the app and select the "Select Bike" button. This will find any bikes around you that are on and save the details into the app.
- Select your bike in the list.
- Set the settings you want to use. These can be changed at any time.

Optionally, you can tap the "Edit" button to change the name of the bike.

**Make sure your bluetooth is on**

## FAQ

### The app won't connect to my bike

Make sure your bike is on and your bluetooth is on. If you're on Android, make sure the app has location permissions. If you're on iOS, make sure the app has bluetooth permissions.

Make sure only one app is connected to the bike at a time. If you have the official app open, disconnect from the bike within the app, and close it. It can also help to uninstall the official app.

You can also try restarting the bike and your phone.

Finally, older bike firmware may not be supported. Make sure your bike is up to date.

### How does Background Lock work and how is it different from the setting lock?

The setting lock feature tells Superduper to ignore whatever the bike is set to and use the settings you have set in the app. This is useful for when the bike starts up and settings reset, like lights and mode. However, the app only enforces the setting lock when the app is open. If you close the app, the bike will go back to whatever settings it was set to. To use it, long press the setting button you want to lock.

Background Lock is a feature that will keep the bike on the settings you set in the app, even if the app is closed. This is useful for when you want to leave the bike on a certain setting, like lights and mode, but don't want to keep the app open. For now, this feature is only available on Android. It also takes extra battery to keep the app running in the background.

### What up with the bike names?

The bike names are randomly generated from your bike's unique ID, to make it easier to read and differentiate between multiple bikes. You can change the name in the bike's Edit page after you connect to the bike for the first time.

### What are the supported devices?

Right now the app requires Android 10+ and iOS 12+.

### What bikes are supported?

So far, all bike models have worked. Open a ticket if your model is having issues!

### Can this app make the bike go even faster?

Superduper can only add automation around what the official app already does. It cannot, for instance, program the controller. This is the job of the firmware, software that runs on the bike itself.

### I'm having another issue or have a feature request

I'm sorry! Please start by making sure you have the newest app from the app store. After that, please submit the issue to https://github.com/blopker/superduper/issues. It helps to have a way I can reproduce the issue, with screenshots or video. Alternatively, you may have luck either clearing all the app's data or reinstalling it.

## Developers

### Releases

1. Update version, save. Don't commit.
1. Run `make release`
1. Update release notes at provided URL.
1. Upload aab to https://play.google.com/console/u/0/developers/6048825475784314007/app/4973912181639360195/tracks/internal-testing
1. Upload ipa to the Transporter app
1. Release Android on Play store
1. Release iOS on https://appstoreconnect.apple.com/apps/1665290602/appstore/ios/version/inflight
