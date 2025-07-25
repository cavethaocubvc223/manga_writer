import 'package:flutter/material.dart';
import '../../models/manga.dart';
import '../../models/chapter.dart';
import '../../services/chapter_service.dart';
import '../create_chapter/create_chapter_screen.dart';
import 'chapter_viewer_screen.dart';

class ChapterListScreen extends StatefulWidget {
  final Manga manga;

  const ChapterListScreen({
    super.key,
    required this.manga,
  });

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen>
    with TickerProviderStateMixin {
  List<Chapter> _chapters = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    
    _loadChapters();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chapters = await ChapterService.getChaptersByMangaId(widget.manga.id);
      final stats = await ChapterService.getChapterStats(widget.manga.id);
      
      setState(() {
        _chapters = chapters;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Failed to load chapters');
    }
  }

  Future<void> _refreshChapters() async {
    await _loadChapters();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            _buildStatsSection(),
            _buildChaptersList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => CreateChapterScreen(manga: widget.manga),
            ),
          );
          
          if (result == true) {
            _refreshChapters();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Chapter'),
        backgroundColor: widget.manga.color,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: widget.manga.color,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.manga.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.manga.color,
                widget.manga.color.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60), // Space for app bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_stories,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.manga.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showSearchDialog();
          },
          icon: const Icon(Icons.search),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'stats') {
              _showStatsDialog();
            } else if (value == 'reorder') {
              _showReorderDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Statistics'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reorder',
              child: Row(
                children: [
                  Icon(Icons.reorder, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Reorder Chapters'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: widget.manga.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Story Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Chapters',
                    '${_stats['totalChapters'] ?? 0}',
                    Icons.menu_book,
                    widget.manga.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Published',
                    '${_stats['publishedChapters'] ?? 0}',
                    Icons.publish,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Words',
                    '${_stats['totalWords'] ?? 0}',
                    Icons.article,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_chapters.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No chapters yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start writing your first chapter!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => CreateChapterScreen(manga: widget.manga),
                    ),
                  );
                  
                  if (result == true) {
                    _refreshChapters();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create First Chapter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.manga.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chapter = _chapters[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.manga.color,
                      widget.manga.color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${chapter.chapterNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              title: Text(
                chapter.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Drawing preview or placeholder
                  Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: chapter.content.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.image,
                                  color: widget.manga.color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Manga Page Drawing',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Tap to View',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.draw,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'No drawing yet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: chapter.isPublished 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chapter.isPublished ? 'Published' : 'Draft',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: chapter.isPublished 
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.brush,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Drawing Page',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(chapter.lastModified),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editChapter(chapter);
                  } else if (value == 'publish') {
                    _togglePublish(chapter);
                  } else if (value == 'delete') {
                    _deleteChapter(chapter);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'publish',
                    child: Row(
                      children: [
                        Icon(
                          chapter.isPublished ? Icons.unpublished : Icons.publish,
                          color: chapter.isPublished ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(chapter.isPublished ? 'Unpublish' : 'Publish'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ),
              ),
              onTap: () {
                _viewChapter(chapter);
              },
            ),
          );
        },
        childCount: _chapters.length,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return '${difference} days ago';
    }
  }

  void _viewChapter(Chapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterViewerScreen(
          manga: widget.manga,
          chapter: chapter,
        ),
      ),
    );
  }

  void _editChapter(Chapter chapter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateChapterScreen(
          manga: widget.manga,
          editingChapter: chapter,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshChapters();
      }
    });
  }

  Future<void> _togglePublish(Chapter chapter) async {
    final success = await ChapterService.toggleChapterPublish(chapter.id);
    if (success) {
      _refreshChapters();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chapter.isPublished 
                ? 'Chapter unpublished successfully'
                : 'Chapter published successfully',
          ),
          backgroundColor: widget.manga.color,
        ),
      );
    } else {
      _showErrorMessage('Failed to update chapter status');
    }
  }

  void _deleteChapter(Chapter chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chapter'),
        content: Text('Are you sure you want to delete "${chapter.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await ChapterService.deleteChapter(chapter.id);
              if (success) {
                _refreshChapters();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Chapter deleted successfully'),
                    backgroundColor: widget.manga.color,
                  ),
                );
              } else {
                _showErrorMessage('Failed to delete chapter');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return AlertDialog(
          title: const Text('Search Chapters'),
          content: TextField(
            onChanged: (value) {
              searchQuery = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter chapter title or content',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (searchQuery.isNotEmpty) {
                  final results = await ChapterService.searchChaptersInManga(
                    widget.manga.id,
                    searchQuery,
                  );
                  setState(() {
                    _chapters = results;
                  });
                  
                  if (results.isEmpty) {
                    _showErrorMessage('No chapters found matching your search');
                  }
                } else {
                  _refreshChapters();
                }
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailedStat('Total Chapters', '${_stats['totalChapters']}'),
            _buildDetailedStat('Published Chapters', '${_stats['publishedChapters']}'),
            _buildDetailedStat('Draft Chapters', '${_stats['draftChapters']}'),
            _buildDetailedStat('Total Words', '${_stats['totalWords']}'),
            _buildDetailedStat('Average Words per Chapter', '${_stats['averageWords']}'),
            _buildDetailedStat('Estimated Reading Time', '${_stats['estimatedReadingTime']} minutes'),
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

  Widget _buildDetailedStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showReorderDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reorder feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
} 