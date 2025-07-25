import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../models/manga.dart';
import '../../models/chapter.dart';
import '../../services/chapter_service.dart';

class CreateChapterScreen extends StatefulWidget {
  final Manga manga;
  final Chapter? editingChapter;

  const CreateChapterScreen({
    super.key,
    required this.manga,
    this.editingChapter,
  });

  @override
  State<CreateChapterScreen> createState() => _CreateChapterScreenState();
}

class _CreateChapterScreenState extends State<CreateChapterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late SignatureController _signatureController;
  
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  bool _isPublished = false;
  Color _selectedColor = Colors.black;
  double _strokeWidth = 2.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Drawing tools
  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.pink,
  ];
  
  final List<double> _strokeWidths = [1.0, 2.0, 4.0, 6.0, 8.0];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _signatureController = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _selectedColor,
      exportBackgroundColor: Colors.white,
    );

    // Load existing chapter data if editing
    if (widget.editingChapter != null) {
      _titleController.text = widget.editingChapter!.title;
      _isPublished = widget.editingChapter!.isPublished;
      // Note: We would need to save drawing data as base64 string in content field
      // and restore it here if editing existing chapter
    }

    // Listen for changes
    _titleController.addListener(_onContentChanged);
    _signatureController.onDrawStart = () => _onContentChanged();
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _signatureController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final saved = await _saveChapter();
              Navigator.of(context).pop(saved);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<bool> _saveChapter() async {
    if (!_formKey.currentState!.validate()) return false;

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert drawing to base64 string
      final Uint8List? signature = await _signatureController.toPngBytes();
      String content = '';
      
      if (signature != null) {
        // Convert to base64 for storage
        content = 'data:image/png;base64,${signature.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}';
      }

      bool success;
      
      if (widget.editingChapter != null) {
        // Update existing chapter
        final updatedChapter = widget.editingChapter!.copyWith(
          title: _titleController.text.trim(),
          content: content,
          isPublished: _isPublished,
        );
        success = await ChapterService.updateChapter(updatedChapter);
      } else {
        // Create new chapter
        success = await ChapterService.addChapter(
          mangaId: widget.manga.id,
          title: _titleController.text.trim(),
          content: content,
        );
      }

      if (success) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.editingChapter != null 
                    ? 'Chapter saved successfully!'
                    : 'Chapter created successfully!'),
              ],
            ),
            backgroundColor: widget.manga.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return true;
      } else {
        _showErrorMessage('Failed to save chapter. Please try again.');
        return false;
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _updateDrawingSettings() {
    _signatureController = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _selectedColor,
      exportBackgroundColor: Colors.white,
      points: _signatureController.points, // Preserve existing drawing
    );
    setState(() {});
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text('Are you sure you want to clear all drawings? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _signatureController.clear();
              Navigator.pop(context);
              _onContentChanged();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _undoLastStroke() {
    if (_signatureController.points.isNotEmpty) {
      _signatureController.undo();
      _onContentChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            widget.editingChapter != null ? 'Edit Chapter' : 'Draw New Chapter',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: widget.manga.color,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Unsaved',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              onPressed: _isLoading ? null : () async {
                final saved = await _saveChapter();
                if (saved) {
                  Navigator.of(context).pop(true);
                }
              },
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildDrawingTools(),
              Expanded(
                child: _buildDrawingCanvas(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: widget.manga.color,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Manga info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.brush,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.manga.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.editingChapter != null 
                          ? 'Chapter ${widget.editingChapter!.chapterNumber}'
                          : 'New Chapter',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Chapter title input
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Chapter Title',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a chapter title';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingTools() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Color palette
          Row(
            children: [
              const Icon(Icons.palette, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Colors:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: _colors.map((color) {
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                        _updateDrawingSettings();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? widget.manga.color : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stroke width
          Row(
            children: [
              const Icon(Icons.line_weight, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Brush Size:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: _strokeWidths.map((width) {
                    final isSelected = width == _strokeWidth;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _strokeWidth = width;
                        });
                        _updateDrawingSettings();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? widget.manga.color.withOpacity(0.1) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? widget.manga.color : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Container(
                          width: 20,
                          height: width * 2,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(width),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Canvas header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.draw,
                    color: widget.manga.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Drawing Canvas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _undoLastStroke,
                        icon: const Icon(Icons.undo),
                        tooltip: 'Undo',
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: _clearCanvas,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear All',
                        iconSize: 20,
                      ),
                    ],
                  ),
                  if (widget.editingChapter != null)
                    Row(
                      children: [
                        const Text(
                          'Published',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Switch.adaptive(
                          value: _isPublished,
                          onChanged: (value) {
                            setState(() {
                              _isPublished = value;
                              _hasUnsavedChanges = true;
                            });
                          },
                          activeColor: widget.manga.color,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Drawing area
            Expanded(
              child: Signature(
                controller: _signatureController,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Drawing info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.manga.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.brush,
                  size: 16,
                  color: widget.manga.color,
                ),
                const SizedBox(width: 4),
                Text(
                  'Manga Page',
                  style: TextStyle(
                    color: widget.manga.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Current brush info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_strokeWidth.toInt()}px',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Save button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveChapter,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, size: 18),
            label: Text(_isLoading ? 'Saving...' : 'Save Chapter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.manga.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 