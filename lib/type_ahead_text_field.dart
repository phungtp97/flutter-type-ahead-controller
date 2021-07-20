library typeaheadtextfield;

import 'package:flutter/material.dart';

class SuggestedDataWrapper<T> {
  ///You can use this to store additional data e.g UserModel
  final T? item;

  ///Important, this will define how the controller will call out your item;
  final String prefix;

  ///Check with data
  final String id;

  SuggestedDataWrapper({required this.id, required this.prefix, this.item});

  @override
  bool operator ==(Object other) {
    return other is SuggestedDataWrapper &&
        other.prefix == this.prefix &&
        other.id == this.id;
  }
}

class TypeAheadTextFieldController extends TextEditingController {
  ///set this scroll controller to TextField constructor to translate the suggestion dialog base on scroll controller offset
  final ScrollController scrollController = new ScrollController();

  ///the TextField Key, of course
  late final GlobalKey<EditableTextState> textFieldKey;

  ///which prefixes you want to catch, support multiple prefixes e.g @, #, &, ...
  late Set<String> appliedPrefixes;

  ///regex to check text field text and split to highlight the approved parts
  late RegExp _allRegex;

  ///padding to the suggestion dialog
  final EdgeInsets? edgePadding;

  ///called when match or non match the prefix
  Function(PrefixMatchState? prefixMatchState)? onStateChanged;

  ///set a list of suggestion based on the matching prefix, you can change it later, make sure to call setState
  Set<SuggestedDataWrapper>? _suggestibleData;

  ///custom span for matching text
  TextSpan Function(SuggestedDataWrapper data)? customSpanBuilder;

  ///call when a matching text get removed
  Function(List<SuggestedDataWrapper> data)? onRemove;

  TypeAheadTextFieldController(
      {required this.appliedPrefixes,
      required this.textFieldKey,
      this.customSpanBuilder,
      this.onRemove,
      this.edgePadding =
          const EdgeInsets.only(left: 8, right: 0, top: 20, bottom: 0),
      this.onStateChanged,
      Set<SuggestedDataWrapper>? suggestibleData}) {
    this._suggestibleData = suggestibleData;
  }

  Set<String>? _prefixes;
  double? _scrollOffset;
  double? devicePixelRatio;
  Set<SuggestedDataWrapper> _approvedData = Set();
  String? _lastCheckedText;
  late double _cursorHeight;
  late double _cursorWidth;

  @override
  TextSpan buildTextSpan(
      {BuildContext? context, TextStyle? style, bool? withComposing}) {
    List<TextSpan> children = [];

    List<SuggestedDataWrapper> tempMatchedList = [];

    if (_suggestibleData != null && _approvedData.length > 0) {
      _prefixes = appliedPrefixes;

      List<String> patterns = [];

      _prefixes!.forEach((e) {
        var matchedWithPrefix = _approvedData
            .where((element) => element.prefix == e)
            .map((e) => e.id)
            .toSet();
        if (matchedWithPrefix.length > 0) {
          patterns.add(r'(?<=' +
              e +
              ')(' +
              '${matchedWithPrefix.map((e) => '$e').join('|')}' +
              r')');
        }
      });

      var patternStr = patterns.join('|');

      _allRegex = RegExp(patternStr);
      text.splitMapJoin(_allRegex, onMatch: (s) {
        String itemText = text.trim().substring(s.start, s.end);
        print('on match -- $itemText');
        String prefix = text.substring(s.start - 1, s.start);
        SuggestedDataWrapper? data;
        try {
          data = _approvedData.length > 0
              ? _approvedData.firstWhere(
                  (data) => data.id == itemText && prefix == prefix,
                )
              : null;
        } catch (e) {}
        var span = (this.customSpanBuilder != null && data != null)
            ? customSpanBuilder!(data)
            : TextSpan(
                text: itemText,
                style: style,
              );

        children.add(span);

        if (data != null) {
          tempMatchedList.add(data);
        }

        return text;
      }, onNonMatch: (s) {
        children.add(
          TextSpan(text: s),
        );
        return s;
      });
    } else {
      children.add(TextSpan(text: text, style: style));
    }

    var deletedWords = _approvedData.where((element) {
      return !tempMatchedList.contains(element);
    }).toList();

    if (deletedWords.length > 0) {
      onRemove?.call(deletedWords);
      deletedWords.forEach((element) {
        _approvedData.remove(element);
      });
    }

    if (_lastCheckedText == null || _lastCheckedText != text) {
      try {
        TextPainter painter = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(text: '', children: children),
        );
        try {
          painter.layout();
        } catch (e) {}

        print('check -- ${painter.height}');

        _cursorWidth = (textFieldKey.currentWidget as TextField).cursorWidth;
        _cursorHeight =
            ((textFieldKey.currentWidget as TextField).cursorHeight ??
                style?.fontSize ??
                Theme.of(textFieldKey.currentContext!)
                    .textTheme
                    .headline6!
                    .fontSize!);

        if (devicePixelRatio == null && textFieldKey.currentContext != null) {
          devicePixelRatio =
              MediaQuery.of(textFieldKey.currentContext!).devicePixelRatio;
        }

        Rect caretPrototype =
            Rect.fromLTWH(0.0, 0.0, _cursorWidth, _cursorHeight);

        TextPosition cursorTextPosition = this.selection.base;

        Offset caretOffset =
            painter.getOffsetForCaret(cursorTextPosition, caretPrototype);

        var preferredLineHeight = painter.preferredLineHeight;

        Offset positiveOffset = Offset(
          caretOffset.dx > 0 ? caretOffset.dx : -caretOffset.dx,
          (caretOffset.dy > 0 ? caretOffset.dy : -caretOffset.dy) +
              preferredLineHeight,
        );

        _selectionCheck(positiveOffset, _cursorHeight);
      } catch (e) {
        throw e;
      }
    }

    _lastCheckedText = text;

    return TextSpan(style: style, children: children);
  }

  setApprovedData(Set<SuggestedDataWrapper> data) {
    this._suggestibleData = data;
  }

  void approveSelection(PrefixMatchState state, SuggestedDataWrapper data) {
    _approvedData.add(data);
    TextSelection selection = this.selection;

    int position = selection.baseOffset;

    int replacedLength = state.text.replaceAll('${state.prefix}', '').length;

    String newText = this
        .text
        .replaceRange(position - replacedLength, position, data.id + ' ');

    text = newText;

    int offset = position + (data.id.length - replacedLength);

    selection = TextSelection.fromPosition(TextPosition(offset: offset + 1));
    _lastCheckedText = newText;

    this.selection = selection;
  }

  void _selectionCheck(Offset dimensionalOffset, double cursorHeight) {
    if (selection.start > 0) {
      List<String> texts = text.substring(0, selection.start).split(' ');
      if (texts.length > 0) {
        var lines =
            '\n'.allMatches(text.substring(0, selection.baseOffset)).length + 1;

        ///r'(?!(\r\n|\n|\r)).*'

        var str =
            appliedPrefixes.map((prefix) => r'(' + prefix + '.*)').join('|');

        str = '^($str)' + r'(?!(\r\n|\n|\r))$';

        var generalRegexp = RegExp(str);

        if (generalRegexp.hasMatch(texts.last)) {
          String prefix = '';
          appliedPrefixes.forEach((element) {
            if (texts.last.startsWith(element)) {
              prefix = element;
            }
          });

          if (scrollController.hasClients) {
            if (scrollController.position.axis == Axis.horizontal) {
              _scrollOffset =
                  this.scrollController.position.pixels / devicePixelRatio!;
            } else {
              _scrollOffset = this.scrollController.position.pixels;
            }
          } else {
            _scrollOffset = 0.0;
          }

          double physicalOffsetDx = dimensionalOffset.dx;

          double physicalOffsetDy = lines * (cursorHeight + 5) + 12;

          if (_scrollOffset != null && _scrollOffset! >= 0) {
            if (scrollController.position.axis == Axis.horizontal) {
              physicalOffsetDx = physicalOffsetDx - (_scrollOffset ?? 0);
            } else {
              physicalOffsetDy = physicalOffsetDy - (_scrollOffset ?? 0);
            }
          }

          Offset physicalOffset = new Offset(
              physicalOffsetDx + (edgePadding?.left ?? 0), physicalOffsetDy);

          WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
            onStateChanged!(
                PrefixMatchState(prefix, texts.last, offset: physicalOffset));
          });
        } else {
          WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
            onStateChanged!(null);
          });
        }
      }
    }
  }

  Set<SuggestedDataWrapper> getApprovedData() => _approvedData;

  Offset? calculateGlobalOffset(BuildContext context, Offset? localOffset,
      {double? dialogHeight, double? dialogWidth}) {
    if (localOffset != null) {
      RenderBox? tfBox =
          textFieldKey.currentContext?.findRenderObject() as RenderBox?;

      double? screenWidth;
      double? screenHeight;
      if (tfBox != null) {
        screenWidth = MediaQuery.of(context).size.width;
        screenHeight = MediaQuery.of(context).size.height -
            MediaQuery.of(context).viewInsets.bottom;
      }

      Offset? globalOffset = tfBox?.localToGlobal(Offset.zero);
      Offset? avoidTruncationOffset;

      double topPadding;
      double leftPadding;

      if (globalOffset != null) {
        double dx = globalOffset.dx + localOffset.dx;
        double dy = globalOffset.dy + localOffset.dy;

        if (dialogHeight != null && (dy + dialogHeight) > screenHeight!) {
          topPadding =
              (dy - dialogHeight - _cursorHeight - (edgePadding?.top ?? 0.0));
          if (topPadding > (screenHeight - dialogHeight)) {
            topPadding = screenHeight -
                dialogHeight -
                _cursorHeight -
                (edgePadding?.top ?? 0.0);
          }
        } else {
          topPadding = dy + (edgePadding?.bottom ?? 0.0);
        }

        if (dialogWidth != null && (dx + dialogWidth) > screenWidth!) {
          if (dx > (screenWidth - dialogWidth)) {
            leftPadding = (dx - dialogWidth);
            if (leftPadding > (screenWidth - dialogWidth)) {
              leftPadding = screenWidth - dialogWidth;
            }
          } else {
            leftPadding = dx - (dialogWidth - (edgePadding?.left ?? 0.0));
          }
        } else {
          leftPadding = dx + (edgePadding?.right ?? 0.0);
        }
        avoidTruncationOffset = Offset(leftPadding, topPadding);
      }

      return avoidTruncationOffset;
    } else {
      return null;
    }
  }
}

class PrefixMatchState {
  late final String prefix;
  late final String text;
  Offset? offset;

  PrefixMatchState(this.prefix, this.text, {this.offset});
}

enum TypeAheadItemChangedState { Add, Remove }

class PositionData {
  double? top;
  double? bottom;
  double? left;
  double? right;

  PositionData({this.top, this.bottom, this.left, this.right})
      : assert(
            (top != null || bottom != null) && (left != null || right != null));
}
