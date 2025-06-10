// Firebase Web用のJavaScriptインターオプヘルパー
// dartifyとjsifyメソッドの問題を解決するためのユーティリティ

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

/// JavaScriptオブジェクトをDartオブジェクトに変換する
dynamic dartify(Object? jsObject) {
  if (jsObject == null) {
    return null;
  }
  
  return js_util.dartify(jsObject);
}

/// DartオブジェクトをJavaScriptオブジェクトに変換する
dynamic jsify(Object? dartObject) {
  if (dartObject == null) {
    return null;
  }
  
  return js_util.jsify(dartObject);
}
