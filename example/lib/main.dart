import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:type_ahead_text_field/type_ahead_text_field.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TypeAheadTextFieldController? controller;
  final List<SuggestedDataWrapper> data = [];
  OverlayEntry? overlayEntry;
  final GlobalKey<EditableTextState> tfKey = new GlobalKey();
  final BehaviorSubject<PrefixMatchState> bhMatchedState =
      new BehaviorSubject();
  final List<String> users = ['john', 'josh', 'lucas', 'don', 'will'];
  final List<String> tags = ['meme', 'challenge', 'city'];
  PrefixMatchState? filterState;
  GlobalKey suggestionWidgetKey = new GlobalKey();
  bool readOnly = false;

  @override
  void initState() {
    super.initState();
    data.addAll(users.map((e) => SuggestedDataWrapper(id: e, prefix: '@')));
    data.addAll(tags.map((e) => SuggestedDataWrapper(id: e, prefix: '#')));

    ///You can set customSpanBuilder later if you needed and add recognizer to it but remember to set readonly to true
    /*TextSpan(
        text: data.id,
        style: TextStyle(color: Colors.blue),
        recognizer: LongPressGestureRecognizer()
          ..onLongPress = () {
            
          })*/
    controller = new TypeAheadTextFieldController(
        appliedPrefixes: ['@', '#'].toSet(),
        suggestibleData: data.toSet(),
        textFieldKey: tfKey,
        edgePadding: EdgeInsets.all(6),
        onRemove: (data) {
          WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
            setState(() {});
          });
        },
        customSpanBuilder: (SuggestedDataWrapper data) {
          ///data.id
          ///data.prefix
          ///data.item
          return customSpan(data);
        },
        onStateChanged: (PrefixMatchState? state) {
          if (state != null && (filterState == null || filterState != state)) {
            filterState = state;
            bhMatchedState.add(state);
          }

          if (state != null) {
            if (overlayEntry == null) {
              showSuggestionDialog();
            }
          } else {
            removeOverlay();
          }
        });
  }

  showSuggestionDialog() {
    overlayEntry = OverlayEntry(builder: (context) {
      return StreamBuilder<PrefixMatchState>(
          stream: bhMatchedState,
          builder: (context, snapshot) {
            List<SuggestedDataWrapper> filteredData = filterState != null
                ? data
                    .where((element) => element.prefix == filterState!.prefix)
                    .toList()
                : [];

            Offset? offset;
            offset = controller!.calculateGlobalOffset(
                context, snapshot.data?.offset,
                dialogHeight: 300, dialogWidth: 200);
            return offset != null
                ? Stack(
                    children: [
                      AnimatedPositioned(
                        key: suggestionWidgetKey,
                        duration: Duration(milliseconds: 300),
                        left: (offset.dx),
                        top: (offset.dy),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            color: Colors.blue,
                            height: 300,
                            width: 200,
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                      onPressed: () {
                                        removeOverlay();
                                      },
                                      icon: Icon(Icons.close)),
                                ),
                                Text('Filter: ${filterState?.text}'),
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: 200),
                                    child: ListView.builder(
                                      itemBuilder: (context, index) {
                                        var item = filteredData[index];
                                        return GestureDetector(
                                          child: ListTile(
                                            title: Text('${item.id}'),
                                          ),
                                          onTap: () {
                                            controller!.approveSelection(
                                                filterState!, item);
                                            removeOverlay();
                                            setState(() {});
                                          },
                                        );
                                      },
                                      itemCount: filteredData.length,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container();
          });
    });

    Overlay.of(context)?.insert(overlayEntry!);
  }

  TextSpan customSpan(SuggestedDataWrapper data) {
    return TextSpan(
        text: data.id,
        style: TextStyle(color: Colors.blue),
        recognizer: readOnly
            ? (TapGestureRecognizer()
              ..onTap = () {
                showAboutDialog(
                    context: context,
                    children: [Text('${data.prefix}${data.id}')]);
              })
            : null);
  }

  removeOverlay() {
    try {
      overlayEntry?.remove();
      overlayEntry = null;
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              child: Text(
                'Added data: ${controller?.getApprovedData().map((e) => '${e.prefix}${e.id}').toString()}',
                style: TextStyle(color: Colors.blue),
              ),
              padding: EdgeInsets.only(bottom: 24, top: 24),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              child: TextField(
                key: tfKey,
                readOnly: readOnly,
                scrollController: controller?.scrollController,
                controller: controller,
                maxLines: 10,
                decoration: InputDecoration.collapsed(hintText: 'Description'),
                cursorHeight: 14,
                cursorWidth: 2,
                onSubmitted: (s) {
                  removeOverlay();
                },
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  readOnly = !readOnly;
                  setState(() {});
                },
                child: Text('${readOnly ? 'EDIT' : 'SAVE'}'))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    bhMatchedState.close();
  }
}
