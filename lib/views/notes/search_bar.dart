import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';

typedef SearchCb = void Function(String searchText);

class SearchBar extends StatefulWidget {
  final SearchCb searchcb;
  SearchBar({required this.searchcb}) : super();

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  Debounce debounce = Debounce();
  late StreamSubscription<bool> keyboardSubscription;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
            child: TextFormField(
              autofocus: false,
              decoration: const InputDecoration(
                isDense: true, // Added this
                contentPadding: EdgeInsets.all(12), //
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                labelText: 'Поиск',
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
        // Padding(
        //   padding: const EdgeInsets.only(top: 8.0),
        //   child: IconButton(
        //     onPressed: (() {}),
        //     icon: const Icon(Icons.search),
        //     color: Colors.black,
        //     iconSize: 20,
        //   ),
        // ),
      ],
    );
  }
}
