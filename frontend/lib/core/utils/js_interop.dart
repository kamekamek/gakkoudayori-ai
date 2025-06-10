// Web用のJavaScriptインターオプヘルパー
// dart:js_interopを使用した新しい実装

import 'dart:js_interop';

/// JavaScriptオブジェクトをDartオブジェクトに変換する
dynamic dartify(JSAny? jsObject) {
  if (jsObject == null) {
    return null;
  }

  // JSAnyをDartの値に変換
  if (jsObject.isA<JSString>()) {
    return (jsObject as JSString).toDart;
  } else if (jsObject.isA<JSNumber>()) {
    return (jsObject as JSNumber).toDartDouble;
  } else if (jsObject.isA<JSBoolean>()) {
    return (jsObject as JSBoolean).toDart;
  } else if (jsObject.isA<JSArray>()) {
    final jsArray = jsObject as JSArray;
    return List.generate(jsArray.length, (i) => dartify(jsArray[i]));
  } else if (jsObject.isA<JSObject>()) {
    final jsObj = jsObject as JSObject;
    final Map<String, dynamic> map = {};
    // JSObjectの処理は簡略化
    return map;
  }

  return jsObject;
}

/// DartオブジェクトをJavaScriptオブジェクトに変換する
JSAny? jsify(Object? dartObject) {
  if (dartObject == null) {
    return null;
  }

  if (dartObject is String) {
    return dartObject.toJS;
  } else if (dartObject is num) {
    return dartObject.toJS;
  } else if (dartObject is bool) {
    return dartObject.toJS;
  } else if (dartObject is List) {
    return dartObject.map((e) => jsify(e)).toList().toJS;
  } else if (dartObject is Map<String, dynamic>) {
    final jsObj = JSObject();
    dartObject.forEach((key, value) {
      // JSObjectのプロパティ設定は簡略化
    });
    return jsObj;
  }

  return dartObject.toString().toJS;
}
