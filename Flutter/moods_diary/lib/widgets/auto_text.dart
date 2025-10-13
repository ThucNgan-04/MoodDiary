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
    final settings = context.watch<SettingProvider>().settings;
    final text = transProvider.getText(widget.text, lang);

    final baseStyle = widget.style ?? const TextStyle(); 

    double fontSize;
    switch (settings.fontSize) {
      case 'small':
        fontSize = 17;
        break;
      case 'medium':
        fontSize = 19;
        break;
      case 'large':
        fontSize = 23;
        break;
      default:
        fontSize = 18;
    }
    final effectiveStyle = (widget.style ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      color: widget.style?.color ??
          Theme.of(context).textTheme.bodyMedium?.color,
    );

    return Text(
      text,
      style: effectiveStyle,
      textAlign: widget.textAlign,
    );
  }
}
