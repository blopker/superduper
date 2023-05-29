import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

const helpText = """
# Useful Links
[Source Code/FAQ](https://github.com/blopker/superduper/)

[Bug Reports](https://github.com/blopker/superduper/issues)

# Bike Functions
Control your bike's functions by tapping the buttons on the screen. Press the lock icon to lock the setting.
A locked setting tells the bike to use that setting when it turns on. An unlocked setting will reset to the default
when the bike turns on.

## Light
If your bike has them, this toggles your bike's lights on and off.

## Mode
Changes the legal category your bike will operate at. PAS is Pedal Assist System, 
which means the motor will only run when you are pedaling. 
Throttle means the motor will run when you press the throttle, regardless of if you are pedaling or not.

### US:
| Mode | Class | PAS | Throttle | Speed Limit |
| ---- | ----- | --- | -------- | ----------- |
| 1    | 1     | Yes | No       | 20 mph      |
| 2    | 2     | Yes | Yes      | 20 mph      |
| 3    | 3     | Yes | No       | 28 mph      |
| 4    | Off-Road | Yes | Yes  | No Limit    |


### EU:
| Mode | Class | PAS | Throttle | Speed Limit |
| ---- | ----- | --- | -------- | ----------- |
| 1    | EPAC  | Yes | No       | 25 km/h     |
| 2    | 250W  | Yes | No       | 35 km/h     |
| 3    | 850W  | Yes | No       | 45 km/h     |
| 4    | Off-Road | Yes | Yes  | No Limit    |

## Assist
Changes the amount of assist your bike will provide while pedaling. 
0 is no assist, 4 is full assist. This does not affect throttle power.

## Background Lock (Android Only)
**Uses extra battery.** Locks the current "locked" settings in the background. This means that if you close the app, or your phone goes to sleep, the settings will continue to be applied.
""";

class HelpWidget extends StatelessWidget {
  const HelpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.black87,
            title: const Text('Help'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            )),
        body: Container(
            height: MediaQuery.of(context).size.height,
            color: Colors.black87,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView(shrinkWrap: true, children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, bottom: 20),
                      child: MarkdownBody(
                        styleSheet: MarkdownStyleSheet(
                            h1Padding:
                                const EdgeInsets.only(top: 10, bottom: 10),
                            h2Padding:
                                const EdgeInsets.only(top: 10, bottom: 10),
                            h3Padding:
                                const EdgeInsets.only(top: 10, bottom: 10)),
                        selectable: true,
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        data: helpText,
                      ),
                    )
                  ]),
                ),
              ],
            )),
      ),
    );
  }
}
