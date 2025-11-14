import 'dart:convert';

class ApiPreset {
  final String id;
  final String name;
  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> params;
  final String? body;
  final Map<String, bool> editableFields;
  final List<String> urlVariables; // ✅ existing
  bool get requiresToken => headers.values.any((v) => v.contains('[TOKEN]'));

  // ⚙️ NEW: Auth support fields
  final String? authType; // "bearer", etc.
  final String? authToken; // token value or placeholder like [TOKEN]

  ApiPreset({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    required this.headers,
    required this.params,
    this.body,
    required this.editableFields,
    required this.urlVariables,
    this.authType, // ⚙️ added
    this.authToken, // ⚙️ added
  });

  static bool _hasPlaceholder(String value) {
    final regex = RegExp(r'\[(.*?)\]');
    return regex.hasMatch(value);
  }

  static Map<String, bool> _extractEditableMap(Map<String, String> fields) {
    final map = <String, bool>{};
    for (var entry in fields.entries) {
      map[entry.key] = _hasPlaceholder(entry.value);
    }
    return map;
  }

  /// ⚙️ NEW — Extract Auth data from Postman `auth` section
  static Map<String, dynamic> _extractAuth(Map<String, dynamic>? auth) {
    if (auth == null) return {};
    final type = auth['type'];
    if (type == 'bearer' && auth['bearer'] is List) {
      final token = (auth['bearer'] as List)
          .map((b) => b['value'])
          .where((v) => v != null)
          .cast<String>()
          .firstOrNull;
      return {'type': type, 'token': token};
    }
    return {};
  }

  factory ApiPreset.fromPostman(Map<String, dynamic> json) {
    final request = json['request'] ?? {};
    final url = request['url'];

    final rawHeaders = (request['header'] as List?)
        ?.map((h) => MapEntry(
      (h['key'] ?? '').toString(),
      (h['value'] ?? '').toString(),
    ))
        .where((e) => e.key.isNotEmpty)
        .toList() ??
        [];

    final headers = Map<String, String>.fromEntries(rawHeaders);
    final params = <String, String>{};
    if (url is Map && url['query'] != null) {
      for (var q in url['query']) {
        params[(q['key'] ?? '').toString()] = (q['value'] ?? '').toString();
      }
    }

    String? body;
    if (request['body'] != null && request['body']['raw'] != null) {
      body = request['body']['raw'].toString();
    }

    final urlRaw = (url is Map ? url['raw'] : url)?.toString() ?? '';

    final urlVars = RegExp(r'\[(.*?)\]')
        .allMatches(urlRaw)
        .map((m) => m.group(1) ?? '')
        .toList();

    final editableMap = {
      ..._extractEditableMap(headers),
      ..._extractEditableMap(params),
      if (body != null) 'body': _hasPlaceholder(body),
    };

    // ⚙️ Extract auth if present
    final authData = _extractAuth(request['auth']);

    return ApiPreset(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Unnamed',
      method: request['method']?.toString().toUpperCase() ?? 'GET',
      url: urlRaw,
      headers: headers,
      params: params,
      body: body,
      editableFields: editableMap,
      urlVariables: urlVars,
      authType: authData['type'], // ⚙️ new
      authToken: authData['token'], // ⚙️ new
    );
  }

  static String cleanValue(String value) {
    return value.replaceAll(RegExp(r'[\[\]]'), '');
  }
}
