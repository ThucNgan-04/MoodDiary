import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/setting_provider.dart';
import 'auto_text.dart';

class SettingOptions {
  // Phương thức tiện ích để chuyển đổi mã hex thành đối tượng Color
  static Color _hexToColor(String hexColor) {
    if (hexColor.startsWith('#')) {
      hexColor = hexColor.substring(1);
    }
    if (hexColor.length == 6) {
      // ignore: prefer_interpolation_to_compose_strings
      hexColor = 'FF' + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Phương thức tĩnh để xây dựng ô chọn ngôn ngữ
  static Widget buildLanguageSelector(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        // TÍNH TOÁN MÀU CHỦ ĐỀ
        final Color selectedColor = settings.colorTheme != null
            ? SettingOptions._hexToColor(settings.colorTheme!)
            : Theme.of(context).colorScheme.primary;
            
        return ListTile(
          title: AutoText(
            "Ngôn ngữ",
          ),
          trailing: DropdownButton<String>(
            value: settings.language,
            items: [
              DropdownMenuItem(value: 'vi', child: AutoText("Tiếng Việt",style: TextStyle(color: selectedColor),)),
              DropdownMenuItem(value: 'en', child: AutoText("Tiếng Anh", style: TextStyle(color: selectedColor),)),
            ],
            onChanged: (value) => provider.updateSetting(language: value),
          ),
        );
      },
    );
  }

  // Phương thức tĩnh để xây dựng bộ chọn màu
  static Widget buildColorSelector(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        // MÀU CHỦ ĐỀ
        final List<Color> colors = [
          const Color.fromARGB(255, 227, 95, 141),
          const Color.fromARGB(255, 205, 118, 133),
          const Color.fromARGB(255, 0, 0, 0),
          const Color.fromARGB(255, 37, 199, 169),
          const Color.fromARGB(255, 119, 139, 176),
          const Color.fromRGBO(255, 192, 203, 1),
          const Color.fromARGB(255, 200, 192, 255),
        ];
        final String? currentHexColor = provider.settings.colorTheme;
        
        return ListTile(
          title: AutoText("Màu sắc"),
          subtitle: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((color) {
              // ignore: deprecated_member_use
              String hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              bool isSelected = currentHexColor == hexColor;
              return GestureDetector(
                onTap: () => provider.updateSetting(colorTheme: hexColor),
                child: Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _hexToColor(currentHexColor!) : Colors.transparent,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected 
                      ? Icon(
                          Icons.check,
                          color: color == const Color.fromARGB(255, 0, 0, 0)
                              ? Colors.white
                              : Theme.of(context).colorScheme.onPrimary,
                        ) 
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Phương thức tĩnh để xây dựng công tắc chế độ tối
  static Widget buildThemeSwitch(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        // TÍNH TOÁN MÀU CHỦ ĐỀ
        return ListTile(
          title: AutoText("Sáng/ tối", style: TextStyle(color: Colors.black),),
          trailing: Switch(
            value: settings.theme == 'dark',
            onChanged: (value) => provider.updateSetting(theme: value ? 'dark' : 'light'),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  // Phương thức tĩnh để xây dựng thanh trượt cỡ chữ
  static Widget buildFontSizeSlider(BuildContext context) {
    return Consumer<SettingProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        String fontSizeLabel = "";

        double sliderValue = 1.0;
        if (settings.fontSize == "small") {
          fontSizeLabel = "Nhỏ";
          sliderValue = 0.0;
        } else if (settings.fontSize == "medium") {
          fontSizeLabel = "Vừa";
          sliderValue = 1.0;
        } else {
          fontSizeLabel = "Lớn";
          sliderValue = 2.0;
        }

        return ListTile(
          title: AutoText("Cỡ chữ"),
          subtitle: Slider(
            value: sliderValue,
            min: 0,
            max: 2,
            divisions: 2,
            activeColor: Theme.of(context).colorScheme.primary,
            label: fontSizeLabel,
            onChanged: (val) {
              if (val == 0) {
                provider.updateSetting(fontSize: "small");
              } else if (val == 1) {
                provider.updateSetting(fontSize: "medium");
              } else {
                provider.updateSetting(fontSize: "large");
              }
            },
          ),
        );
      },
    );
  }
}
