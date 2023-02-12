import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 10,
              top: 10,
            ),
            child: TextFormField(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.only(left: 20.0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30.0))),
                labelText: 'Поиск',
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: IconButton(
            onPressed: (() {}),
            icon: const Icon(Icons.search),
            color: Colors.black,
            iconSize: 20,
          ),
        ),
      ],
    );
  }
}
