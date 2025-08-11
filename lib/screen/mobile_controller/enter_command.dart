import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';

class EnterCommandScreen extends StatefulWidget {
  final void Function(String)? onSend;
  final VoidCallback? onMic;
  const EnterCommandScreen({super.key, this.onSend, this.onMic});

  @override
  State<EnterCommandScreen> createState() => _EnterCommandScreenState();
}

class _EnterCommandScreenState extends State<EnterCommandScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(), // Có thể thêm lịch sử chat ở đây nếu muốn
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _controller,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Type your command...',
                          hintStyle: const TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: ResponsiveLayout.paddingHorizontal,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            widget.onSend?.call(value.trim());
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white, size: 28),
                    onPressed: widget.onMic,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 28),
                    onPressed: () {
                      final value = _controller.text.trim();
                      if (value.isNotEmpty) {
                        widget.onSend?.call(value);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
