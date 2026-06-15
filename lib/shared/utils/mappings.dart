/// Enum mappings between Chinese strings and integer values.
/// Matches the novel_hub Django project conventions.
///
/// Index 1 is always OTHER/其他 (fallback).
class EnumMapping {
  final String name;
  final Map<String, int> _zhToValue;
  final Map<int, String> _valueToZh;

  const EnumMapping(this.name, this._zhToValue) : _valueToZh = const {};

  EnumMapping._(this.name, this._zhToValue, this._valueToZh);

  factory EnumMapping.create(String name, Map<String, int> mappings) {
    // Add fallback "其他" = 1
    final allMappings = {'其他': 1, ...mappings};
    final reversed = allMappings.map((key, value) => MapEntry(value, key));
    return EnumMapping._(name, allMappings, reversed);
  }

  int getValue(String zh) => _zhToValue[zh] ?? 1;
  String getZh(int value) => _valueToZh[value] ?? '其他';

  List<String> get allZh => _zhToValue.keys.toList();
  List<int> get allValue => _valueToZh.keys.toList();
}

/// Genre mappings (from novel_hub/utils/mappings.py)
/// 1=其他, 2=魔幻, 3=玄幻, 4=古风, 5=科幻, 6=校园, 7=都市, 8=游戏, 9=同人, 10=悬疑
final genreMapping = EnumMapping.create('genre', {
  '魔幻': 2,
  '玄幻': 3,
  '古风': 4,
  '科幻': 5,
  '校园': 6,
  '都市': 7,
  '游戏': 8,
  '同人': 9,
  '悬疑': 10,
});

/// Status mappings (from novel_hub/utils/mappings.py)
/// 1=其他, 2=已完结, 3=连载中, 4=断更, 5=断更A, 6=完结A, 7=下架
final statusMapping = EnumMapping.create('status', {
  '已完结': 2,
  '连载中': 3,
  '断更': 4,
  '断更A': 5,
  '完结A': 6,
  '下架': 7,
});

/// Ptype mappings (from novel_hub/utils/mappings.py)
/// 1=其他, 2=免费, 3=签约, 4=VIP
final ptypeMapping = EnumMapping.create('ptype', {
  '免费': 2,
  '签约': 3,
  'VIP': 4,
});
