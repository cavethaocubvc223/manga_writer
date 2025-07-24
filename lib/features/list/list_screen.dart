import 'package:flutter/material.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final List<Map<String, dynamic>> _mangaList = [
    {
      'title': 'My First Manga',
      'description': 'A story about adventures',
      'pages': 12,
      'lastModified': DateTime.now().subtract(const Duration(days: 1)),
      'color': const Color(0xFFFF6B6B),
    },
    {
      'title': 'Hero Journey',
      'description': 'Epic hero story',
      'pages': 8,
      'lastModified': DateTime.now().subtract(const Duration(days: 3)),
      'color': const Color(0xFF4ECDC4),
    },
    {
      'title': 'Love Story',
      'description': 'Romantic manga series',
      'pages': 15,
      'lastModified': DateTime.now().subtract(const Duration(days: 7)),
      'color': const Color(0xFF667eea),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search feature coming soon!'),
                  backgroundColor: Color(0xFF4ECDC4),
                ),
              );
            },
                         icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: _mangaList.isEmpty
            ? _buildEmptyState()
            : _buildMangaList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create new manga feature coming soon!'),
              backgroundColor: Color(0xFF667eea),
            ),
          );
        },
                 icon: const Icon(Icons.add),
        label: const Text('New Manga'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                                 Icon(
                   Icons.menu_book_outlined,
                   size: 80,
                   color: Colors.grey[400],
                 ),
                const SizedBox(height: 20),
                Text(
                  'No manga yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Start creating your first manga!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMangaList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mangaList.length,
      itemBuilder: (context, index) {
        final manga = _mangaList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    manga['color'],
                    manga['color'].withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
                             child: const Icon(
                 Icons.auto_stories,
                 color: Colors.white,
                 size: 30,
               ),
            ),
            title: Text(
              manga['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  manga['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                                         Icon(
                       Icons.description_outlined,
                       size: 16,
                       color: Colors.grey[500],
                     ),
                    const SizedBox(width: 4),
                    Text(
                      '${manga['pages']} pages',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                                         Icon(
                       Icons.schedule,
                       size: 16,
                       color: Colors.grey[500],
                     ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(manga['lastModified']),
                      style: TextStyle(
                        fontSize: 12,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit feature coming soon!'),
                      backgroundColor: Color(0xFF4ECDC4),
                    ),
                  );
                } else if (value == 'delete') {
                  _showDeleteDialog(index);
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
                  borderRadius: BorderRadius.circular(10),
                ),
                                 child: Icon(
                   Icons.more_vert,
                   color: Colors.grey[600],
                 ),
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening ${manga['title']}...'),
                  backgroundColor: manga['color'],
                ),
              );
            },
          ),
        );
      },
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

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Manga'),
        content: Text('Are you sure you want to delete "${_mangaList[index]['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _mangaList.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Manga deleted successfully'),
                  backgroundColor: Color(0xFF4ECDC4),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 