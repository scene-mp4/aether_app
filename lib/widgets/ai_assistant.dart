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
      final resp = await _service.query(text, context: context);
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
    if (_messages.isEmpty) {
      _messages.add(_Msg(
        "Hi! I'm your AETHER assistant. Ask me anything about air quality or what readings mean.",
        false,
      ));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width * 0.95;
        final width = w > 420 ? 420.0 : w;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> handleSend(String text) async {
              if (text.trim().isEmpty) return;
              
              setModalState(() {
                _messages.add(_Msg(text, true));
                _loading = true;
              });
              setState(() {});
              _ctrl.clear();

              try {
                final resp = await _service.query(text, context: context);
                setModalState(() {
                  _messages.add(_Msg(resp, false));
                });
                setState(() {});
              } catch (e) {
                setModalState(() {
                  _messages.add(_Msg('Error: $e', false));
                });
                setState(() {});
              } finally {
                setModalState(() {
                  _loading = false;
                });
                setState(() {});
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 80,
                right: 16,
                left: 16,
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Material(
                  elevation: 8,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: width,
                    height: 720,
                    color: Colors.white,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          color: const Color(0xFF2B52FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AETHER Assistant',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Ask about air quality',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Chat Messages List
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ListView.builder(
                              itemCount: _messages.length,
                              itemBuilder: (context, i) {
                                final m = _messages[i];
                                return Align(
                                  alignment: m.me
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.me
                                          ? const Color(0xFF2B52FF)
                                          : const Color(0xFFF0F4FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      m.text,
                                      style: TextStyle(
                                        color: m.me
                                            ? Colors.white
                                            : const Color(0xFF333333),
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        if (_loading)
                          const LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF2B52FF),
                            ),
                          ),

                        // Text Field & Send Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFD8E0F0),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _ctrl,
                                    onSubmitted: handleSend,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      hintText: 'Type a question...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2B52FF),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: () => handleSend(_ctrl.text),
                                  child: const Text(
                                    'Send',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2B52FF);
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

/// Helper to launch assistant from anywhere in your widget tree
Future<void> showAiAssistant(BuildContext context) async {
  final AiService service = AiService();
  final List<_Msg> messages = [
    _Msg(
      "Hi! I'm your AETHER assistant. Ask me anything about air quality or what readings mean.",
      false,
    ),
  ];
  final TextEditingController ctrl = TextEditingController();
  bool loading = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final w = MediaQuery.of(ctx).size.width * 0.88;
      final width = w > 360 ? 360.0 : w;

      return StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> sendLocal(String text) async {
            if (text.trim().isEmpty) return;
            setModalState(() {
              messages.add(_Msg(text, true));
              loading = true;
            });
            ctrl.clear();
            try {
              final resp = await service.query(text, context: ctx);
              setModalState(() {
                messages.add(_Msg(resp, false));
              });
            } catch (e) {
              setModalState(() {
                messages.add(_Msg('Error: $e', false));
              });
            } finally {
              setModalState(() {
                loading = false;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 80,
              right: 16,
              left: 16,
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Material(
                elevation: 8,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: width,
                  height: 280,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFF2B52FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AETHER Assistant',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Ask about air quality',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ListView.builder(
                            itemCount: messages.length,
                            itemBuilder: (context, i) {
                              final m = messages[i];
                              return Align(
                                alignment: m.me
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: m.me
                                        ? const Color(0xFF2B52FF)
                                        : const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    m.text,
                                    style: TextStyle(
                                      color: m.me
                                          ? Colors.white
                                          : const Color(0xFF333333),
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (loading)
                        const LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2B52FF),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFD8E0F0),
                                  ),
                                ),
                                child: TextField(
                                  controller: ctrl,
                                  onSubmitted: sendLocal,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'Type a question...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2B52FF),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                onPressed: () => sendLocal(ctrl.text),
                                child: const Text(
                                  'Send',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}