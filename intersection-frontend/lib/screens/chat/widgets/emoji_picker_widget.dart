// lib/screens/chat/widgets/emoji_picker_widget.dart

import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

/// 이모지 피커 위젯
class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final bool isVisible;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          onEmojiSelected(emoji.emoji);
        },
        // emoji_picker_flutter 최신 버전 기준 Config에 height 파라미터가 없어
        // SizedBox(height: 250)로 높이를 제어하고, Config에는 지원되는 옵션만 넣는다.
        config: const Config(
          checkPlatformCompatibility: true,
        ),
      ),
    );
  }
}
