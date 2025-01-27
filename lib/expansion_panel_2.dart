
import 'package:flutter/material.dart';

class ReasonableExpansionPanel extends ExpansionPanel {
  bool _isExpanded;
  String name;
  ReasonableExpansionPanel({
    required super.headerBuilder,
    required super.body,
    this.name = "",
    bool isExpanded = false,
    super.canTapOnHeader,
    super.backgroundColor,
    super.splashColor,
    super.highlightColor
  }): _isExpanded = isExpanded;

  @override
  bool get isExpanded => _isExpanded;
  set isExpanded(bool g) => _isExpanded = g;
}