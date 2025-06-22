/// バリデーション関数
class Validators {
  /// 必須入力チェック
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldNameは必須です' : '必須項目です';
    }
    return null;
  }
  
  /// メールアドレスのバリデーション
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'メールアドレスの形式が正しくありません';
    }
    return null;
  }
  
  /// URLのバリデーション
  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;
    
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'URLの形式が正しくありません';
      }
      return null;
    } catch (e) {
      return 'URLの形式が正しくありません';
    }
  }
  
  /// 文字数制限のバリデーション
  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length > max) {
      return fieldName != null 
          ? '$fieldNameは$max文字以内で入力してください' 
          : '$max文字以内で入力してください';
    }
    return null;
  }
  
  /// 最小文字数のバリデーション
  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < min) {
      return fieldName != null 
          ? '$fieldNameは$min文字以上で入力してください' 
          : '$min文字以上で入力してください';
    }
    return null;
  }
  
  /// 日本語文字数制限のバリデーション（半角0.5文字、全角1文字として計算）
  static String? maxJapaneseLength(String? value, double max, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    double length = 0;
    for (int i = 0; i < value.length; i++) {
      final char = value.codeUnitAt(i);
      // 半角文字の範囲
      if (char <= 0x7F || (char >= 0xFF61 && char <= 0xFF9F)) {
        length += 0.5;
      } else {
        length += 1;
      }
    }
    
    if (length > max) {
      return fieldName != null 
          ? '$fieldNameは$max文字以内で入力してください' 
          : '$max文字以内で入力してください';
    }
    return null;
  }
  
  /// 数値のバリデーション
  static String? number(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    if (double.tryParse(value) == null) {
      return fieldName != null 
          ? '$fieldNameは数値で入力してください' 
          : '数値で入力してください';
    }
    return null;
  }
  
  /// 整数のバリデーション
  static String? integer(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    if (int.tryParse(value) == null) {
      return fieldName != null 
          ? '$fieldNameは整数で入力してください' 
          : '整数で入力してください';
    }
    return null;
  }
  
  /// 範囲チェック（数値）
  static String? range(String? value, double min, double max, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    final numValue = double.tryParse(value);
    if (numValue == null) return null;
    
    if (numValue < min || numValue > max) {
      return fieldName != null 
          ? '$fieldNameは$minから$maxの範囲で入力してください' 
          : '$minから$maxの範囲で入力してください';
    }
    return null;
  }
  
  /// 学校名のバリデーション（日本語含む）
  static String? schoolName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '学校名は必須です';
    }
    
    if (value.trim().length < 2) {
      return '学校名は2文字以上で入力してください';
    }
    
    if (value.trim().length > 50) {
      return '学校名は50文字以内で入力してください';
    }
    
    return null;
  }
  
  /// クラス名のバリデーション
  static String? className(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'クラス名は必須です';
    }
    
    // 1年1組、3-2、A組などの形式をサポート
    final classRegex = RegExp(r'^[1-6][-年]?[1-9A-Z]?[組クラス]?$|^[A-Z]組$');
    if (!classRegex.hasMatch(value.trim())) {
      return 'クラス名の形式が正しくありません（例：1年1組、3-2、A組）';
    }
    
    return null;
  }
  
  /// 教師名のバリデーション
  static String? teacherName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '教師名は必須です';
    }
    
    if (value.trim().length < 2) {
      return '教師名は2文字以上で入力してください';
    }
    
    if (value.trim().length > 20) {
      return '教師名は20文字以内で入力してください';
    }
    
    return null;
  }
  
  /// 複数のバリデーションを組み合わせる
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}