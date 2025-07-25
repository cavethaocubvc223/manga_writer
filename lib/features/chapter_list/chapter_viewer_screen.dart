import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/manga.dart';
import '../../models/chapter.dart';

class ChapterViewerScreen extends StatefulWidget {
  final Manga manga;
  final Chapter chapter;

  const ChapterViewerScreen({
    super.key,
    required this.manga,
    required this.chapter,
  });

  @override
  State<ChapterViewerScreen> createState() => _ChapterViewerScreenState();
}

class _ChapterViewerScreenState extends State<ChapterViewerScreen>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isAppBarVisible = true;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadChapterImage();
    _animationController.forward();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadChapterImage() {
    try {
      if (widget.chapter.content.isNotEmpty && widget.chapter.content.contains('base64')) {
        // Extract base64 data from the content
        final base64String = widget.chapter.content.split(',').last;
        // Convert hex string back to bytes
        final bytes = <int>[];
        for (int i = 0; i < base64String.length; i += 2) {
          final hex = base64String.substring(i, i + 2);
          bytes.add(int.parse(hex, radix: 16));
        }
        setState(() {
          _imageBytes = Uint8List.fromList(bytes);
        });
      }
    } catch (e) {
      print('Error loading chapter image: $e');
    }
  }

  void _toggleAppBar() {
    setState(() {
      _isAppBarVisible = !_isAppBarVisible;
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isAppBarVisible
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${widget.chapter.chapterNumber}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.chapter.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              backgroundColor: widget.manga.color,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  onPressed: _resetZoom,
                  icon: const Icon(Icons.zoom_out_map),
                  tooltip: 'Reset Zoom',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'info') {
                      _showChapterInfo();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Chapter Info'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: _toggleAppBar,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: _imageBytes != null
                ? InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                : _buildEmptyState(),
          ),
        ),
      ),
      floatingActionButton: _isAppBarVisible
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              backgroundColor: widget.manga.color,
              child: const Icon(Icons.close, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No Drawing Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This chapter doesn\'t have any drawings yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chapter ${widget.chapter.chapterNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.chapter.title),
            const SizedBox(height: 16),
            Text(
              'Status:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.chapter.isPublished 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.chapter.isPublished ? 'Published' : 'Draft',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: widget.chapter.isPublished 
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Created: ${_formatDate(widget.chapter.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Modified: ${_formatDate(widget.chapter.lastModified)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 