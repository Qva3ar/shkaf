import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_network/image_network.dart';
import 'package:jiffy/jiffy.dart';

import '../../services/cloud/cloud_note.dart';
import '../../services/cloud/firebase_cloud_storage.dart';
import '../categories/category_list.dart';

class ImprovedInfiniteScrollWidget extends StatefulWidget {
  final int? selectedCityId;
  final int? selectedCategoryId;
  final int? selectedSubcategoryId;

  const ImprovedInfiniteScrollWidget({
    Key? key,
    this.selectedCityId,
    this.selectedCategoryId,
    this.selectedSubcategoryId,
  }) : super(key: key);

  @override
  _ImprovedInfiniteScrollWidgetState createState() => _ImprovedInfiniteScrollWidgetState();
}

class _ImprovedInfiniteScrollWidgetState extends State<ImprovedInfiniteScrollWidget> {
  final FirebaseCloudStorage _notesService = FirebaseCloudStorage();
  final ScrollController _scrollController = ScrollController();
  
  List<CloudNote> _notes = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollListener);
    _fetchInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _notes.clear();
    });

    try {
      final result = await _fetchData(isRefresh: true);
      setState(() {
        _notes = result.$1;
        _lastDocument = result.$2;
        _hasMoreData = _notes.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _fetchData();
      setState(() {
        _notes.addAll(result.$1);
        _lastDocument = result.$2;
        _hasMoreData = result.$1.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  Future<(List<CloudNote>, DocumentSnapshot?)> _fetchData({bool isRefresh = false}) async {
    Query query = FirebaseFirestore.instance.collection('notes');

    // Apply filters based on selected parameters
    if (widget.selectedCityId != null) {
      query = query.where('cityId', isEqualTo: widget.selectedCityId);
    }
    if (widget.selectedCategoryId != null) {
      query = query.where('categoryId', isEqualTo: widget.selectedCategoryId);
    }
    if (widget.selectedSubcategoryId != null) {
      query = query.where('subcategoryId', isEqualTo: widget.selectedSubcategoryId);
    }

    // Order and limit query
    query = query.orderBy('createdAt', descending: true).limit(_pageSize);

    // If not refreshing and last document exists, start after it
    if (!isRefresh && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();
    final notes = snapshot.docs
        .map((doc) => CloudNote.fromFirestore(doc))
        .toList();

    return (notes, snapshot.docs.isNotEmpty ? snapshot.docs.last : null);
  }

  void _handleError(dynamic error) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading notes: ${error.toString()}'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _fetchInitialData,
        ),
      ),
    );
  }

  void _onScrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Widget _buildNoteCard(CloudNote note) {
    return Card(
      semanticContainer: true,
      elevation: 0,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNoteImage(note),
          _buildNoteDetails(note),
        ],
      ),
    );
  }

  Widget _buildNoteImage(CloudNote note) {
    return SizedBox(
      child: note.imagesUrls != null && note.imagesUrls!.isNotEmpty
          ? ImageNetwork(
              image: note.imagesUrls![0],
              imageCache: CachedNetworkImageProvider(note.imagesUrls![0]),
              height: 120,
              width: double.infinity,
              duration: 1500,
              onPointer: true,
              debugPrint: false,
              fullScreen: false,
              fitAndroidIos: BoxFit.cover,
              fitWeb: BoxFitWeb.cover,
              borderRadius: BorderRadius.circular(4),
              onLoading: const CircularProgressIndicator(
                color: Colors.indigoAccent,
              ),
              onError: const Icon(
                Icons.error,
                color: Colors.red,
              ),
            )
          : Image.asset(
              'assets/images/img_placeholder.jpeg',
              height: 120, 
              width: double.infinity, 
              fit: BoxFit.fill
            ),
    );
  }

  Widget _buildNoteDetails(CloudNote note) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            note.text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  getCityName(note.cityId ?? 0),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(177, 158, 158, 158),
                  ),
                ),
              ),
              Text(
                getFormattedDate(note.updatedAt ?? note.createdAt),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        child: _notes.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _notes.length + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notes.length) {
                        return _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : const SizedBox.shrink();
                      }
                      return _buildNoteCard(_notes[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No notes found'),
          ElevatedButton(
            onPressed: _fetchInitialData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Utility functions
String getFormattedDate(DateTime date) {
  return Jiffy.parseFromDateTime(date).format(pattern: 'dd.MM.yyyy');
}