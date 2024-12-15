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
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.white),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 8, 7),
        child: Row(
          children: [
            Expanded(
              child: SearchBarWidget(
                searchcb: widget.onSearch,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 130,
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
