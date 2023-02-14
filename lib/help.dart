import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

const helpText = """
# Useful Links
### [Source Code/FAQ](https://github.com/blopker/superduper/)
### [Bug Reports](https://github.com/blopker/superduper/issues)

# Bike Functions
## Light
Toggles your bike's lights on and off, if your bike has them.

## Mode
Changes the legal category your bike will operate at.

US:
- 1: Class 1 - PAS Only, 20 mph
- 2: Class 2 - PAS & Throttle, 20 mph
- 3: Class 3 - PAS Only, 28 mph
- 4: OFF-ROAD - PAS & Throttle, no limit

EU:
- 1: EPAC - PAS, 25 km/h
- 2: 250W - PAS, 35 km/h
- 3: 850W - PAS, 45 km/h
- 4: OFF-ROAD - PAS/Throttle, no limit
""";

class HelpWidget extends StatelessWidget {
  const HelpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 40,
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 35,
                    )),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3.0),
                    child: Text('Help',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: ListView(shrinkWrap: true, children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: MarkdownBody(
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
        ));
  }
}

// import 'package:flutter/material.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   static const String _title = 'Flutter Code Sample';

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       title: _title,
//       home: MyStatelessWidget(),
//     );
//   }
// }

// class MyStatelessWidget extends StatelessWidget {
//   const MyStatelessWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTextStyle(
//       style: Theme.of(context).textTheme.bodyMedium!,
//       child: LayoutBuilder(
//         builder: (BuildContext context, BoxConstraints viewportConstraints) {
//           return SingleChildScrollView(
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 minHeight: viewportConstraints.maxHeight,
//               ),
//               child: IntrinsicHeight(
//                 child: Column(
//                   children: <Widget>[
//                     Container(
//                       // A fixed-height child.
//                       color: const Color(0xffeeee00), // Yellow
//                       height: 120.0,
//                       alignment: Alignment.center,
//                       child: const Text('Fixed Height Content'),
//                     ),
//                     Expanded(
//                       // A flexible child that will grow to fit the viewport but
//                       // still be at least as big as necessary to fit its contents.
//                       child: Container(
//                         color: const Color(0xffee0000), // Red
//                         height: 120.0,
//                         alignment: Alignment.center,
//                         child: const Text('Flexible Content'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
