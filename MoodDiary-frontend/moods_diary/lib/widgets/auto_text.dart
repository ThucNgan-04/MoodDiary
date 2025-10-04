import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
import '../providers/translation_provider.dart';

class AutoText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const AutoText(this.text, {super.key, this.style, this.textAlign});

  @override
  State<AutoText> createState() => _AutoTextState();
}

class _AutoTextState extends State<AutoText> {
  @override
  void initState() {
    super.initState();
    // preload dịch ngay khi widget khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<SettingProvider>().settings.language;
      context.read<TranslationProvider>().preload(widget.text, lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingProvider>().settings.language;
    final transProvider = context.watch<TranslationProvider>();

    final text = transProvider.getText(widget.text, lang);

    return Text(
      text,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
