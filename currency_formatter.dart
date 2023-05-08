import 'dart:collection';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// TODO: Replace with correct import to where AmountInputFormatterSet is declared
import 'num_ext.dart';

class AmountInputFormatter extends TextInputFormatter {

  AmountInputFormatter({
    this.includeDecimals = false,
    this.decimalPlaces = 2,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    final endsWithSymbol = newText.isNotEmpty
        ? ['.', ',',].contains(newText[newText.length - 1],)
        : false;
    final selectionDelta = max(
      0,
      newText.length - newValue.selection.baseOffset,
    );
    num? parsed = num.tryParse(
      includeDecimals ? newText : newText.replaceAll(r"\D", "",),
    );
    if (parsed != null) {
      newText = NumberFormat.currency(
        locale: 'id',
        name: '',
        symbol: '',
        decimalDigits: includeDecimals
            ? max(min(decimalPlaces, parsed.decimalPlaces,), 0,)
            : 0,
      ).format(parsed,).replaceAll(
        RegExp(r"\D",), '.',
      );
    } else {
      newText = '';
    }

    newText = endsWithSymbol ? '$newText.' : newText;
    int newOffset = newText.length - selectionDelta;

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newOffset,
      ),
    );
  }

  final bool includeDecimals;
  final int decimalPlaces;
}

class AmountInputFormatterSet extends ListBase<TextInputFormatter> {

  AmountInputFormatterSet({
    int maxLength = 15,
    bool includeDecimals = false,
    int decimalPlaces = 2,
  }): _internal = [
    FilteringTextInputFormatter.allow(
      includeDecimals
          ? RegExp(r"[\d.,]",)
          : RegExp(r"\d",),
    ),
    if (includeDecimals)
      FilteringTextInputFormatter.deny(
        RegExp(r"(?<=\d+[.,]\d*)[.,]",),
      ),
    LengthLimitingTextInputFormatter(
      maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    ),
    AmountInputFormatter(
      includeDecimals: includeDecimals,
    ),
  ];

  final List<TextInputFormatter> _internal;

  @override
  int get length => _internal.length;

  @override
  TextInputFormatter operator [](int index) {
    return _internal[index];
  }

  @override
  void operator []=(int index, TextInputFormatter value) {
  }

  @override
  set length(int newLength) {}
}
