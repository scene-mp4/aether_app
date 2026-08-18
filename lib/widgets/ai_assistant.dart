import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'dart:async';

class AiAssistant extends StatefulWidget {
  final bool compact;
  const AiAssistant({super.key, this.compact = true});

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant> {
  final AiService _service = AiService();
  final List<_Msg> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = false;

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Msg(text, true));
      _loading = true;
    });
    _ctrl.clear();

    try {
      final resp = await _service.query(text);
      setState(() {
        _messages.add(_Msg(resp, false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_Msg('Error: $e', false));
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Material(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Expanded(
                            child: Text('AETHER Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        return Align(
                          alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: m.me ? const Color(0xFF1E56FF) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(color: m.me ? Colors.white : Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 8, right: 8, top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            onSubmitted: _send,
                            decoration: const InputDecoration(
                              hintText: 'Type a question...'
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _send(_ctrl.text),
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF1E56FF);
    if (widget.compact) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: _openSheet,
              backgroundColor: bg,
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton.extended(
            onPressed: _openSheet,
            backgroundColor: bg,
            label: const Text('AETHER Assistant'),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool me;
  _Msg(this.text, this.me);
}

/// Helper: show the assistant sheet from any widget (useful if you have
/// your own placeholder button). Example:
///
/// ```dart
/// onPressed: () => showAiAssistant(context);
/// ```
Future<void> showAiAssistant(BuildContext context) async {
  final AiService _service = AiService();
  final List<_Msg> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        Future<void> _send(String text) async {
          if (text.trim().isEmpty) return;
          setState(() {
            _messages.add(_Msg(text, true));
            _loading = true;
          });
          _ctrl.clear();
          try {
            final resp = await _service.query(text);
            setState(() {
              _messages.add(_Msg(resp, false));
            });
          } catch (e) {
            setState(() {
              _messages.add(_Msg('Error: $e', false));
            });
          } finally {
            setState(() {
              _loading = false;
            });
          }
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Material(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Expanded(
                            child: Text('AETHER Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        return Align(
                          alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: m.me ? const Color(0xFF1E56FF) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(color: m.me ? Colors.white : Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 8, right: 8, top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            onSubmitted: _send,
                            decoration: const InputDecoration(
                              hintText: 'Type a question...'
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _send(_ctrl.text),
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      });
    },
  );
}
