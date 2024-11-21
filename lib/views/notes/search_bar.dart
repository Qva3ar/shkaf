import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';

typedef SearchCb = void Function(String searchText);

class SearchBarWidget extends StatefulWidget {
  final SearchCb searchcb;
  const SearchBarWidget({Key? key, required this.searchcb}) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBarWidget> {
  Debounce debounce = Debounce();
  late StreamSubscription<bool> keyboardSubscription;
  String selectedCity = 'Select City';

  final List<String> cities = [
    'New York',
    'London',
    'Tokyo',
    'Paris',
    'Mumbai',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              autofocus: false,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                labelText: 'Search',
              ),
              onChanged: (text) {
                debounce.debouncing(
                  fn: () {
                    widget.searchcb(text);
                  },
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedCity == 'Select City' ? null : selectedCity,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                labelText: 'City',
              ),
              items: cities.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value!;
                });
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              // Add profile icon action here
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Profile"),
                  content: const Text("Profile actions will be here."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
