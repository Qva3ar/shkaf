import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';

typedef NoteCallback = void Function(CloudNote note);
typedef NoteEmptyCallback = void Function();

class NotesGridView extends StatelessWidget {
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;
  final ScrollController scrollController;
  const NotesGridView(
      {Key? key,
      required this.notes,
      required this.onDeleteNote,
      required this.onTap,
      required this.scrollController})
      : super(key: key);

  final List<CloudNote> notes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        controller: scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two items per row
          mainAxisSpacing: 14, // Spacing between rows
          crossAxisSpacing: 20, // Spacing between columns
          childAspectRatio: 183 / 220, // Aspect ratio of each card
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index]; // Current note
          return GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              onTap(notes[index]);
              // Navigator.pushNamed(
              //   context,
              //   noteDetailsRoute, // Note details
              //   arguments: note,
              // );
            },
            child: Container(
              width: 183,
              height: 220,
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              note.imagesUrls != null && note.imagesUrls!.isNotEmpty
                                  ? note.imagesUrls![0]
                                  : 'https://via.placeholder.com/150',
                              width: 175,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              // Логика для добавления в избранное
                            },
                            child: Container(
                              width: 16,
                              height: 14.63,
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: const Icon(
                                Icons.favorite_border,
                                size: 16,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Text(
                    //   note.text,
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: AppTextStyles.s16w600.copyWith(
                    //     color: AppColors.black,
                    //   ),
                    // ),
                    const SizedBox(height: 4),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     // Display city name
                    //     Text(
                    //       getCityName(note.cityId ?? 0, TURKEY),
                    //       style: AppTextStyles.s12w600.copyWith(
                    //         color: AppColors.grey,
                    //       ),
                    //     ),
                    //     // Display formatted updatedAt
                    //     Text(
                    //       formatUpdatedAt(note.updatedAt), // Format the date
                    //       style: AppTextStyles.s12w600.copyWith(
                    //         color: AppColors.grey,
                    //       ),
                    //     ),
                    //   ],
                    // )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
