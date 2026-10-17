import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '/ui/player/components/lyrics_switch.dart';
import '/ui/player/components/lyrics_widget.dart';
import '/ui/widgets/common_dialog_widget.dart';


class LyricsDialog extends StatelessWidget {
  const LyricsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommonDialog(
      maxWidth: 700,
      child: Column(
        children: [
        Expanded(
          child: LyricsWidget(padding: EdgeInsets.symmetric(vertical: 40))
        ),
      ]),
    );
  }
}
