// lib/ui/widgets/request_editor.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/api_preset.dart';

class RequestEditor extends StatefulWidget {
  final ApiPreset preset;
  const RequestEditor({Key? key, required this.preset}) : super(key: key);

  @override
  State<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends State<RequestEditor> {
  late TextEditingController bodyController;
  late TextEditingController tokenController;
  late List<Map<String, String>> headers;
  late List<Map<String, String>> params;
  final Map<String, TextEditingController> _urlControllers = {};
  String responseText = '';
  int? statusCode;
  bool loading = false;
  String editableBody = '';
  final Map<String, String> _bodyInputs = {}; // 🧠 track placeholder values

  @override
  void initState() {
    super.initState();
    headers = widget.preset.headers.entries
        .map((e) => {'key': e.key, 'value': e.value})
        .toList();
    params = widget.preset.params.entries
        .map((e) => {'key': e.key, 'value': e.value})
        .toList();
    editableBody = widget.preset.body ?? '';
    bodyController = TextEditingController(text: editableBody);
    tokenController = TextEditingController();

    if (widget.preset.authToken != null &&
        widget.preset.authToken!.isNotEmpty &&
        widget.preset.authToken != '[TOKEN]') {
      tokenController.text = widget.preset.authToken!;
    }

    for (var v in widget.preset.urlVariables) {
      _urlControllers[v] = TextEditingController();
    }
  }

  @override
  void didUpdateWidget(covariant RequestEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preset.id != oldWidget.preset.id) {
      bodyController.dispose();
      tokenController.dispose();
      _urlControllers.forEach((_, controller) => controller.dispose());
      _urlControllers.clear();

      setState(() {
        headers = widget.preset.headers.entries
            .map((e) => {'key': e.key, 'value': e.value})
            .toList();

        params = widget.preset.params.entries
            .map((e) => {'key': e.key, 'value': e.value})
            .toList();

        editableBody = widget.preset.body ?? '';
        bodyController = TextEditingController(text: editableBody);
        tokenController = TextEditingController();

        if (widget.preset.authToken != null &&
            widget.preset.authToken!.isNotEmpty &&
            widget.preset.authToken != '[TOKEN]') {
          tokenController.text = widget.preset.authToken!;
        }

        for (var v in widget.preset.urlVariables) {
          _urlControllers[v] = TextEditingController();
        }

        responseText = '';
        statusCode = null;
      });
    }
  }

  String _buildFinalUrl() {
    String url = widget.preset.url;
    _urlControllers.forEach((key, controller) {
      url = url.replaceAll('[$key]', controller.text.trim());
    });
    return url;
  }

  Map<String, String> _buildFinalHeaders() {
    final Map<String, String> result = {};
    for (var h in headers) {
      final key = h['key'] ?? '';
      var value = h['value'] ?? '';
      if (value.contains('[TOKEN]')) {
        value = value.replaceAll('[TOKEN]', tokenController.text.trim());
      }
      result[key] = value;
    }

    if (widget.preset.authType == 'bearer' && tokenController.text.isNotEmpty) {
      result['Authorization'] = 'Bearer ${tokenController.text.trim()}';
    }
    result['Content-Type'] = 'application/json';
    return result;
  }

  /// 🧩 Build and clean up final JSON body before sending
  String _buildFinalBody() {
    if (_bodyInputs.isEmpty) return '';

    String updated = editableBody;

    _bodyInputs.forEach((placeholder, value) {
      final pattern = RegExp(r'\[\s*' + RegExp.escape(placeholder) + r'\s*\]');
      updated = updated.replaceAll(pattern, value);
    });

    try {
      final decoded = jsonDecode(updated);

      // 🧹 Remove empty or placeholder-only parameters
      if (decoded is Map && decoded['message'] is Map) {
        final msg = decoded['message'] as Map;
        if (msg['template'] is Map) {
          final template = msg['template'] as Map;
          if (template['parameters'] is Map) {
            final parameters = template['parameters'] as Map;

            bool hasRealData = false;
            if (parameters['body'] is List) {
              final bodyList = parameters['body'] as List;
              hasRealData = bodyList.any((item) =>
              item is String &&
                  item.trim().isNotEmpty &&
                  !item.contains('[') &&
                  !item.contains(']'));
            }

            if (!hasRealData) {
              template.remove('parameters');
            }
          }
        }
      }

      if (!_bodyInputs.values.any((v) => v.trim().isNotEmpty)) return '';

      return jsonEncode(decoded);
    } catch (_) {
      return updated;
    }
  }

  Future<void> sendRequest() async {
    setState(() {
      loading = true;
      responseText = '';
    });

    try {
      final targetUrl = _buildFinalUrl();
      final method = widget.preset.method.toUpperCase();
      final headersMap = _buildFinalHeaders();

      String finalBodyString = widget.preset.body ?? '';
      bool hasUserInputs = _bodyInputs.values.any((v) => v.trim().isNotEmpty);
      bool shouldSendBody = finalBodyString.isNotEmpty && hasUserInputs;

      dynamic bodyForProxy;
      if (shouldSendBody) {
        try {
          bodyForProxy = jsonDecode(_buildFinalBody());
        } catch (_) {
          bodyForProxy = _buildFinalBody();
        }
      }

      final proxyUri = Uri.parse(
        "https://us-central1-bbc-api-tool.cloudfunctions.net/bevatelProxy",
      );

      final proxyPayload = {
        "url": targetUrl,
        "method": method,
        "headers": headersMap,
        if (shouldSendBody) "body": bodyForProxy,
      };

      // 🧠 Debug: Print outgoing payload
      print("============================================");
      print("🚀 Sending Request via Proxy:");
      print(jsonEncode(proxyPayload));
      print("============================================");

      final resp = await http.post(
        proxyUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(proxyPayload),
      );

      setState(() {
        loading = false;
        statusCode = resp.statusCode;
        responseText = _prettyJson(resp.body);
      });
    } catch (e) {
      setState(() {
        loading = false;
        responseText = "Error: $e";
      });
    }
  }

  String _prettyJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  bool _hasEditableParams() {
    return widget.preset.params.values.any((v) => v.contains('[') && v.contains(']'));
  }

  Widget _keyValueEditor(String title, List<Map<String, String>> list) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E2ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF003366))),
          const SizedBox(height: 8),
          for (int i = 0; i < list.length; i++)
            if ((list[i]['value'] ?? '').contains('['))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: list[i]['key']),
                        readOnly: true,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFD8E2ED)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller:
                        TextEditingController(text: list[i]['value']),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF80CFFF)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFD8E2ED)),
                          ),
                        ),
                        onChanged: (v) => list[i]['value'] = v,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color mainBackground = Color(0xFFF5F9FC);
    const Color cardBackground = Color(0xFFFAFCFE);
    const Color borderColor = Color(0xFFD8E2ED);
    const Color focusColor = Color(0xFF80CFFF);
    const Color sectionText = Color(0xFF003366);
    final Color successColor = Colors.green.shade600;
    final Color errorColor = Colors.red.shade400;

    return Container(
      color: mainBackground,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ElevatedButton.icon(
              onPressed: sendRequest,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: sectionText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                if (widget.preset.requiresToken ||
                    widget.preset.authType == 'bearer') ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Authorization",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: tokenController,
                          decoration: const InputDecoration(
                            labelText: "Bearer Token",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (widget.preset.urlVariables.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("URL Variables",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: sectionText)),
                        const SizedBox(height: 6),
                        for (var v in widget.preset.urlVariables)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: TextField(
                              controller: _urlControllers[v],
                              decoration: InputDecoration(
                                labelText: v,
                                border: const OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: focusColor, width: 2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                _keyValueEditor("Headers", headers),
                if (_hasEditableParams())
                  _keyValueEditor("Parameters (Editable Only)", params),

                if (widget.preset.body != null &&
                    widget.preset.body!.contains('[')) ...[
                  const Divider(),
                  const Text(
                    'Body Placeholders',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: sectionText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...RegExp(r'\[(.*?)\]')
                      .allMatches(widget.preset.body!)
                      .map((match) {
                    final placeholder = match.group(1)!.trim();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: placeholder,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                            const BorderSide(color: borderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide:
                            BorderSide(color: focusColor, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          _bodyInputs[placeholder] = value;
                        },
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 20),

                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (responseText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Response",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: sectionText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (statusCode != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusCode! >= 200 &&
                                      statusCode! < 300
                                      ? successColor
                                      : errorColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "$statusCode",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black),
                          ),
                          child: SelectableText(
                            responseText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

