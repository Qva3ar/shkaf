import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';

/// NavItem
/// This widget represents a single item in the bottom navigation bar.
/// It includes an icon, a label, and handles tap events.
///
/// Special styling is applied for the Add button (when `isAddButton` is true).
class NavItem extends StatelessWidget {
  // Icon to display
  final IconData icon;

  // Label text for the item
  final String label;

  // Whether this item is currently selected
  final bool isSelected;

  // Whether this is the special "Add" button
  final bool isAddButton;

  // Callback to handle taps
  final VoidCallback onTap;

  const NavItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isAddButton = false, // Default: not an Add button
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Detect tap gestures and trigger the callback
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Minimum size for the column
        children: [
          // Container for the circular background and icon
          Container(
            width: 26, // Fixed width for the circle
            height: 26, // Fixed height for the circle
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.violet // Violet if selected
                  : AppColors.unselectedTapGrey, // Grey if not selected
              borderRadius: BorderRadius.circular(20), // Circular shape
            ),
            child: Icon(
              icon,
              color: Colors.white, // Icon color is always white
              size: 18, // Fixed size for the icon
            ),
          ),
          // Spacer between the icon and the label
          const SizedBox(height: 10),
          // Label text (hidden for Add button)
          Text(
            label,
            style: AppTextStyles.s10w400.copyWith(
              color: isSelected
                  ? AppColors.violet // Violet if selected
                  : AppColors.unselectedTextGrey, // Grey if not selected
            ),
          ),
        ],
      ),
    );
  }
}
