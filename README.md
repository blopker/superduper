<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="assets/superduper-nobg.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">SuperDuper App</h3>

  <p align="center">
    An alternative ebike app.
    <br />
    <a href="https://discord.gg/STvgARZYaw"><strong>Join the Discord</strong></a>
    <br />
    <br />
    <a href="https://testflight.apple.com/join/Tl0UibRY">iOS Download</a>
    ·
    <a href="https://play.google.com/store/apps/details?id=io.kbl.superduper">Android Download</a>
    ·
    <a href="https://github.com/blopker/superduper/issues">Bug Reports</a>
  </p>
</div>
<br/>

Features:

- No account or internet connection required
- Quickly switch between multiple bikes
- Automatically connect to one active bike when the app opens
- Mark values as Set on connect so they are reapplied and confirmed while the app is open
- Open source

## Getting Started

1. Power on your bike and choose `Add bike`.
2. Allow the Bluetooth access needed by your operating system.
3. Select the bike found nearby, confirm its name and region, and save it.
4. Set Light, Mode, and Assist from Bike Control. Enable
   `Set on connect` for each value Superduper should restore.

The first saved bike becomes active. On later launches, Superduper connects to
that bike directly, applies its Set on connect values, confirms them, and reports
`Ready to ride` without requiring Bike Control to be opened. With multiple
bikes, use `Make active` to choose the one that auto-connects.

## Bike Functions

Bike Control sends changes immediately and confirms the resulting state before
showing it as ready. `Set on connect` stores the currently confirmed value
and reapplies it whenever that bike connects while Superduper is open. Unkept
values follow the bike.

### Light

If your bike has them, this toggles your bike's lights on and off.

### Mode

Changes the legal category your bike will operate at. PAS is Pedal Assist System,
which means the motor will only run when you are pedaling.
Throttle means the motor will run when you press the throttle, regardless of if you are pedaling or not.

Note: the mode setting means different things on different bike models. The table below may only match the early RX/R models.

#### US (RX/R Bikes):

| Mode | Class | PAS | Throttle | Speed Limit |
| ---- | ----- | --- | -------- | ----------- |
| 1    | 1     | Yes | No       | 20 mph      |
| 2    | 2     | Yes | Yes      | 20 mph      |
| 3    | 3     | Yes | No       | 28 mph      |
| 4    | Off-Road | Yes | Yes  | No Limit    |


#### EU (RX/R Bikes):

| Mode | Class | PAS | Throttle | Speed Limit |
| ---- | ----- | --- | -------- | ----------- |
| 1    | EPAC  | Yes | No       | 25 km/h     |
| 2    | 250W  | Yes | No       | 35 km/h     |
| 3    | 850W  | Yes | No       | 45 km/h     |
| 4    | Off-Road | Yes | Yes  | No Limit    |

### Assist

Changes the amount of assist your bike will provide while pedaling.
0 is no assist, 4 is full assist. This does not affect throttle power.


## FAQ

### The app won't connect to my bike

Make sure your bike is on and your bluetooth is on. If you're on Android, make sure the app has location permissions. If you're on iOS, make sure the app has bluetooth permissions. Additionally, on some devices GPS needs to be enabled for scanning to work.

Make sure only one app is connected to the bike at a time. If you have the official app open, disconnect from the bike within the app, and close it. It can also help to uninstall the official app.

You can also try restarting the bike and your phone.

Finally, older (or newer) bike firmware may not be supported. Make sure your bike firmware is up to date from the official app.

### How does Set on connect work?

It saves the value the bike most recently confirmed. While Superduper is open,
the active-bike session reads the bike, restores any kept value that differs,
and reads again before reporting `Ready to ride`. Closing or backgrounding the
app pauses that guarantee; reopening the app resynchronizes the active bike.

### What are the supported devices?

Android 10+, iOS 15+.

### What bikes are supported?

So far, all bike models have worked. Open a ticket if your model is having issues!

### Can this app make the bike go even faster?

Superduper can only add automation around what the official app already does. It cannot, for instance, program the controller. This is the job of the firmware, software that runs on the bike itself. Check out the [CFW site](https://cfw.reverse.bike/) for that.

### I'm having another issue or have a feature request

I'm sorry! Please start by making sure you have the newest app from the app store. After that, please submit the issue to https://github.com/blopker/superduper/issues. It helps to have a way I can reproduce the issue, with screenshots or video. Alternatively, you may have luck either clearing all the app's data or reinstalling it.

### Releases

1. Update version, save. Don't commit.
1. Run `make release`
1. Update release notes at provided URL.
1. Upload aab to https://play.google.com/console/u/0/developers/6048825475784314007/app/4973912181639360195/tracks/internal-testing
1. Upload ipa to the Transporter app
1. Release Android on Play store
1. Release iOS on https://appstoreconnect.apple.com/apps/1665290602/appstore/ios/version/inflight
