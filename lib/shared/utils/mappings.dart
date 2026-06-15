/// Enum mappings between Chinese strings and integer values.
/// Matches the novel_hub Django project conventions.
class EnumMapping {
  final String name;
  final Map<String, int> _zhToValue;
  final Map<int, String> _valueToZh;

  const EnumMapping(this.name, this._zhToValue)
      : _valueToZh = const {};

  EnumMapping._(this.name, this._zhToValue, this._valueToZh);

  factory EnumMapping.create(String name, Map<String, int> mappings) {
    final reversed = mappings.map((key, value) => MapEntry(value, key));
    return EnumMapping._(name, mappings, reversed);
  }

  int getValue(String zh) => _zhToValue[zh] ?? 1;
  String getZh(int value) => _valueToZh[value] ?? _zhToValue.keys.first;

  List<String> get allZh => _zhToValue.keys.toList();
  List<int> get allValue => _valueToZh.keys.toList();
}

/// Genre mappings: 奇幻, 武侠, 同人, 言情, 科幻, 悬疑
final genreMapping = EnumMapping.create('genre', {
  '奇幻': 1,
  '武侠': 2,
  '同人': 3,
  '言情': 4,
  '科幻': 5,
  '悬疑': 6,
});

/// Status mappings: 连载中, 完结, 断更
final statusMapping = EnumMapping.create('status', {
  '连载中': 1,
  '完结': 2,
  '断更': 3,
});

/// Ptype mappings: 短篇, 中篇, 长篇
final ptypeMapping = EnumMapping.create('ptype', {
  '短篇': 1,
  '中篇': 2,
  '长篇': 3,
});
