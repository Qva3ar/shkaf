import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';

typedef SearchCb = void Function(String searchText);
typedef FocusChangeCb = void Function(bool isFocused);

class SearchBarWidget extends StatefulWidget {
  final SearchCb searchcb;
  final FocusChangeCb? onFocusChange;

  const SearchBarWidget({
    Key? key,
    required this.searchcb,
    this.onFocusChange,
  }) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (widget.onFocusChange != null) {
        widget.onFocusChange!(_focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        hintText: 'Поиск',
        hintStyle: AppTextStyles.s17w400.copyWith(color: AppColors.unselectedTextGrey),
        filled: true,
        fillColor: AppColors.lightGrey,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 25,
          color: AppColors.unselectedTextGrey,
        ),
      ),
      onChanged: widget.searchcb,
    );
  }
}
