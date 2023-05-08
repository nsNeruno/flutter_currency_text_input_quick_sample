import 'dart:collection';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

// TODO: Replace with correct import to where AmountInputFormatterSet is declared
import 'num_ext.dart';

class AmountInputFormatter extends TextInputFormatter {

  AmountInputFormatter({
    this.includeDecimals = false,
    this.decimalPlaces = 2,
    this.locale = 'id',
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    final selectionDelta = max(
      0,
      newText.length - newValue.selection.baseOffset,
    );

    bool endsWithSymbol = false;
    String decimalSeparator = '';

    num? parsed;
    if (includeDecimals) {
      final NumberSymbols? symbols = numberFormatSymbols[locale];
      if (symbols == null) {
        throw ArgumentError.value(locale, 'Locale', 'Not a valid I18N Locale',);
      }
      decimalSeparator = symbols.DECIMAL_SEP;
      final groupSeparator = symbols.GROUP_SEP;
      endsWithSymbol = newText.isNotEmpty
          ? newText[newText.length - 1] == decimalSeparator
          : false;
      parsed = num.tryParse(
        newText.replaceAllMapped(
          RegExp('[$groupSeparator$decimalSeparator]',),
          (match) {
            if (match.group(0,) == decimalSeparator) {
              return '.';
            }
            return '';
          },
        ),
      );
    } else {
      parsed = num.tryParse(
        newText.replaceAll(RegExp(r"\D",), "",),
      );
    }

    if (parsed != null) {
      newText = NumberFormat.currency(
        locale: locale,
        name: '',
        symbol: '',
        decimalDigits: includeDecimals
            ? max(min(decimalPlaces, parsed.decimalPlaces,), 0,)
            : 0,
      ).format(parsed,);
    } else {
      newText = '';
    }

    newText = endsWithSymbol ? '$newText$decimalSeparator' : newText;
    final newOffset = newText.length - selectionDelta;

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newOffset,
      ),
    );
  }

  final bool includeDecimals;
  final int decimalPlaces;
  final String locale;
}

class AmountInputFormatterSet extends ListBase<TextInputFormatter> {

  AmountInputFormatterSet({
    int maxLength = 15,
    bool includeDecimals = false,
    int decimalPlaces = 2,
    String locale = 'id',
  }): _internal = [
    FilteringTextInputFormatter.allow(
      includeDecimals
          ? RegExp(r"[\d.,]",)
          : RegExp(r"\d",),
    ),
    if (includeDecimals)
      () {
        final NumberSymbols? symbols = numberFormatSymbols[locale];
        if (symbols == null) {
          throw ArgumentError.value(
            locale, 'Locale', 'Not a valid I18N Locale',
          );
        }
        final decimalSeparator = symbols.DECIMAL_SEP;
        final exp = "(?<=\\d+\\$decimalSeparator\\d*)\\$decimalSeparator";
        return FilteringTextInputFormatter.deny(
          RegExp(exp,),
        );
      }(),
    LengthLimitingTextInputFormatter(
      maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    ),
    AmountInputFormatter(
      includeDecimals: includeDecimals,
      locale: locale,
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
