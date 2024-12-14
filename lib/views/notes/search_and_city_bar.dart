import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/views/notes/city_dropdown.dart';
import 'package:mynotes/views/notes/search_bar.dart';

class SearchAndCityBar extends StatefulWidget {
  final Function(String) onSearch;
  final int selectedCityId;
  final Function(int) onCityChanged;

  const SearchAndCityBar({
    Key? key,
    required this.onSearch,
    required this.selectedCityId,
    required this.onCityChanged,
  }) : super(key: key);

  @override
  State<SearchAndCityBar> createState() => _SearchAndCityBarState();
}

class _SearchAndCityBarState extends State<SearchAndCityBar> {
  bool _isSearchFocused = false;

  void _onSearchFocusChange(bool isFocused) {
    setState(() {
      _isSearchFocused = isFocused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Учитываем отступы: Padding слева (16) + справа (8) + SizedBox(8)
    // Итого: 16 + 8(между виджетами) + 8 = 32 пикселя на отступы
    const horizontalSpacing = 16.0 + 8.0 + 8.0;
    final availableWidth = screenWidth - horizontalSpacing;

    // При фокусе поиска (когда _isSearchFocused == true)
    // Зададим пропорции так, чтобы они умещались.
    // Например: на поиск 60% доступного места, на выбор города 30%.
    // Итого 0.6 + 0.3 = 0.9 от доступного места. Останется немного "запаса".
    final searchFocusedWidth = availableWidth * 0.6;
    final cityFocusedWidth = availableWidth * 0.3;

    // Если не в фокусе, можем использовать фиксированные размеры или другие пропорции.
    // Проверим, если 188 + 188 + 32 отступов влезет в экран:
    // Допустим ширина экрана 400, тогда 188+188=376 + 32=408 — не влезет.
    // Можно уменьшить до, скажем, 160 для каждой при неактивном поиске:
    final nonFocusedWidth = 160.0;

    final searchWidth = _isSearchFocused ? searchFocusedWidth : nonFocusedWidth;
    final cityWidth = _isSearchFocused ? cityFocusedWidth : nonFocusedWidth;

    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(color: AppColors.white),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 8, 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: searchWidth,
              child: SearchBarWidget(
                searchcb: widget.onSearch,
                onFocusChange: _onSearchFocusChange,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: cityWidth,
              child: CityDropdown(
                selectedCityId: widget.selectedCityId,
                onCityChanged: widget.onCityChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
