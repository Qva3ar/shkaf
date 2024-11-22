import 'package:flutter/material.dart';
import 'nav_item.dart';

/// CustomBottomNavigationBar
/// This widget represents a custom-styled bottom navigation bar with three items:
/// - Favorites
/// - Categories
/// - Add (a special button for creating an ad or offer)
///
/// It uses a `Row` to arrange items horizontally and handles tap events
/// through a callback function provided via `onTabSelected`.

class CustomBottomNavigationBar extends StatelessWidget {
  // The index of the currently selected item
  final int currentIndex;

  // Callback function to handle taps on items
  final Function(int) onTabSelected;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
     
      padding: const EdgeInsets.symmetric(vertical: 4),
      
      height: 67,
      decoration: const BoxDecoration(
        color: Colors.white, 
      ),
      
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // NavItem for Favorites
          NavItem(
            icon: Icons.favorite_rounded,
            label: 'Избранное', // "Favorites" in Russian
            isSelected: currentIndex == 0, 
            onTap: () => onTabSelected(0), // Notify parent widget when tapped
          ),
          // NavItem for Categories
          NavItem(
            icon: Icons.apps,
            label: 'Категории', // "Categories" in Russian
            isSelected: currentIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          // NavItem for Add button (special styling)
          NavItem(
            icon: Icons.add,
            label: 'Добавить', // "Add" in Russian
            isSelected: currentIndex == 2,
            isAddButton: true, 
            onTap: () => onTabSelected(2),
          ),
        ],
      ),
    );
  }
}
