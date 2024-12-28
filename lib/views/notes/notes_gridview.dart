import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/views/categories/category_list.dart';

typedef NoteCallback = void Function(CloudNote note);
typedef NoteEmptyCallback = void Function();

class NotesGridView extends StatelessWidget {
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;
  final NoteCallback onTapFavorite;
  final ScrollController scrollController;
  const NotesGridView(
      {Key? key,
      required this.notes,
      required this.onDeleteNote,
      required this.onTap,
      required this.onTapFavorite,
      required this.scrollController})
      : super(key: key);

  final List<CloudNote> notes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: AutoHeightGridView(
        controller: scrollController,
        shrinkWrap: true,
        itemCount: notes.length,
        mainAxisSpacing: 8, // Расстояние между элементами по вертикали
        crossAxisSpacing: 5, // Расстояние между элементами по горизонтали
        builder: (context, index) {
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
              height: 257,
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: note.imagesUrls != null && note.imagesUrls!.isNotEmpty
                                ? Image.network(
                                    '${note.imagesUrls![0]}_160x160',
                                    width: 180,
                                    height: 160,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/images/img_placeholder.jpeg',
                                    width: 180,
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
                              onTapFavorite(note);
                            },
                            child: Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              child: note.isFavorite
                                  ? const Icon(Icons.favorite, size: 25, color: AppColors.red)
                                  : const Icon(Icons.favorite_border,
                                      size: 25, color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 46,
                      alignment: Alignment.topLeft,
                      child: Text(
                        note.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.s14w500.copyWith(color: AppColors.black),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Display city name
                          Text(
                            getCityName(note.cityId ?? 0, TURKEY),
                            style: AppTextStyles.s12w600.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                          // Display formatted updatedAt
                          Text(
                            formatUpdatedAt(note.updatedAt), // Format the date
                            style: AppTextStyles.s12w600.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
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
