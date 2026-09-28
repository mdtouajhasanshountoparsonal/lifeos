import 'package:flutter/material.dart';

/// Global navigator key — notification tap/deep-link-এর জন্য।
/// শুধু additive plumbing; কোনো existing flow বদলায় না।
class AppNav {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}