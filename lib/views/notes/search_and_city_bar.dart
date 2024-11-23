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
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(color: AppColors.white),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 14, 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSearchFocused ? MediaQuery.of(context).size.width * 0.65 : 188,
              child: SearchBarWidget(
                searchcb: widget.onSearch,
                onFocusChange: _onSearchFocusChange,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSearchFocused ? MediaQuery.of(context).size.width * 0.25 : 188,
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

