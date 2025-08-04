import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/user_service.dart';
import '../../services/progress_service.dart';
import '../../services/character_service.dart';
import '../../models/daily_progress.dart';
import '../../models/character.dart';
import '../info/info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userInfo;
  bool _isLoadingUserInfo = true;
  List<DailyProgress> _weeklyProgress = [];
  List<Character> _characters = [];
  DailyProgress? _todayProgress;
  String _reminderMessage = '';
  Map<String, dynamic> _weeklyStats = {};
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserInfo(),
      _loadProgressData(),
      _loadCharacters(),
      _loadReminderMessage(),
    ]);
    setState(() {
      _isLoadingData = false;
    });
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await UserService.getUserInfo();
    setState(() {
      _userInfo = userInfo;
      _isLoadingUserInfo = false;
    });
  }

  Future<void> _loadProgressData() async {
    final weeklyProgress = await ProgressService.getRecentProgress(7);
    final todayProgress = await ProgressService.getTodayProgress();
    final weeklyStats = await ProgressService.getWeeklyStats();
    
    setState(() {
      _weeklyProgress = weeklyProgress;
      _todayProgress = todayProgress;
      _weeklyStats = weeklyStats;
    });
  }

  Future<void> _loadCharacters() async {
    final characters = await CharacterService.getAllCharacters();
    setState(() {
      _characters = characters;
    });
  }

  Future<void> _loadReminderMessage() async {
    final message = await ProgressService.getTodayReminderMessage();
    setState(() {
      _reminderMessage = message;
    });
  }

  Future<void> _logout() async {
    final success = await UserService.clearUserInfo();
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const InfoScreen()),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? Your information will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAddProgressDialog() {
    int pages = _todayProgress?.pagesWritten ?? 0;
    int chapters = _todayProgress?.chaptersCompleted ?? 0;
    int characters = _todayProgress?.charactersCreated ?? 0;
    int timeMinutes = _todayProgress?.timeSpentMinutes ?? 0;
    String notes = _todayProgress?.notes ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Today\'s Progress'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Pages Written',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: pages.toString()),
                  onChanged: (value) => pages = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Chapters Completed',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: chapters.toString()),
                  onChanged: (value) => chapters = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Characters Created',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: characters.toString()),
                  onChanged: (value) => characters = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: timeMinutes.toString()),
                  onChanged: (value) => timeMinutes = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: notes),
                  onChanged: (value) => notes = value,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await ProgressService.updateTodayProgress(
                  pagesWritten: pages,
                  chaptersCompleted: chapters,
                  charactersCreated: characters,
                  timeSpentMinutes: timeMinutes,
                  notes: notes,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadAllData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Manga Creator Dashboard'),
        elevation: 0,
        actions: [
          if (!_isLoadingUserInfo && _userInfo != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const InfoScreen()),
                  );
                } else if (value == 'logout') {
                  _showLogoutDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      const Text('Edit Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red[600])),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF4ECDC4),
                  child: Text(
                    _userInfo?['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section with reminder
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              
              // Daily Progress Chart
              _buildProgressChartSection(),
              const SizedBox(height: 20),
              
              // Today's Stats
              _buildTodayStatsSection(),
              const SizedBox(height: 20),
              
              // Weekly Stats
              _buildWeeklyStatsSection(),
              const SizedBox(height: 20),
              
              // Character Management Section
              _buildCharacterSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProgressDialog,
        tooltip: 'Update Progress',
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, size: 40, color: Color(0xFFFF6B6B)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_userInfo != null)
                      Text(
                        'Hello ${_userInfo!['name']}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      )
                    else
                      const Text(
                        'Welcome to Manga Creator!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      DateTime.now().hour < 12 ? 'Good morning!' : 
                      DateTime.now().hour < 18 ? 'Good afternoon!' : 'Good evening!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF4ECDC4)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _reminderMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF667eea)),
              const SizedBox(width: 8),
              const Text(
                'Progress - Last 7 Days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _weeklyProgress.length) {
                          final date = _weeklyProgress[value.toInt()].date;
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyProgress.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.pagesWritten.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF4ECDC4),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF4ECDC4).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatsSection() {
    final todayGoal = 3; // This should come from ProgressService.getDailyGoal()
    final todayPages = _todayProgress?.pagesWritten ?? 0;
    final progress = todayPages / todayGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: Color(0xFFFF6B6B)),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Progress',
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
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                      strokeWidth: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$todayPages/$todayGoal pages',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}% completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildStatItem(
                      Icons.book,
                      'Chapters',
                      (_todayProgress?.chaptersCompleted ?? 0).toString(),
                      const Color(0xFF667eea),
                    ),
                    const SizedBox(height: 8),
                    _buildStatItem(
                      Icons.person,
                      'Characters',
                      (_todayProgress?.charactersCreated ?? 0).toString(),
                      const Color(0xFFFF8E53),
                    ),
                    const SizedBox(height: 8),
                    _buildStatItem(
                      Icons.access_time,
                      'Time',
                      _todayProgress?.formattedTimeSpent ?? '0m',
                      const Color(0xFF44A08D),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range, color: Color(0xFF764ba2)),
              const SizedBox(width: 8),
              const Text(
                'This Week\'s Statistics',
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
                child: _buildWeeklyStatCard(
                  'Total Pages',
                  (_weeklyStats['totalPages'] ?? 0).toString(),
                  Icons.description,
                  const Color(0xFF4ECDC4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeeklyStatCard(
                  'Chapters Completed',
                  (_weeklyStats['totalChapters'] ?? 0).toString(),
                  Icons.book,
                  const Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyStatCard(
                  'Characters Created',
                  (_weeklyStats['totalCharacters'] ?? 0).toString(),
                  Icons.person_add,
                  const Color(0xFFFF8E53),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeeklyStatCard(
                  'Active Days',
                  (_weeklyStats['activeDays'] ?? 0).toString(),
                  Icons.event_available,
                  const Color(0xFF44A08D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people, color: Color(0xFF6C5CE7)),
                  const SizedBox(width: 8),
                  const Text(
                    'Character Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddCharacterDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_characters.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.person_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No characters yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your first character!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _characters.take(3).map((character) => 
                _buildCharacterCard(character)).toList(),
            ),
          if (_characters.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full character list
                  },
                  child: Text(
                    'View all ${_characters.length} characters',
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(Character character) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: character.characterColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: character.characterColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: character.characterColor,
            radius: 24,
            child: Text(
              character.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  character.roleDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (character.description.isNotEmpty)
                  Text(
                    character.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditCharacterDialog(character);
              } else if (value == 'delete') {
                _showDeleteCharacterDialog(character);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(Icons.more_vert, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showAddCharacterDialog() {
    String name = '';
    String description = '';
    String role = 'supporting';
    String appearance = '';
    String personality = '';
    String backstory = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Character'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Character Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: Character.availableRoles.map((roleValue) {
                    return DropdownMenuItem(
                      value: roleValue,
                      child: Text(Character(
                        id: '', name: '', description: '', role: roleValue,
                        createdAt: DateTime.now(), lastModified: DateTime.now(),
                      ).roleDisplayName),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => role = value ?? 'supporting'),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => description = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Appearance',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => appearance = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Personality',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => personality = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Background',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => backstory = value,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.trim().isEmpty) return;
                
                final success = await CharacterService.addCharacter(
                  name: name.trim(),
                  description: description.trim(),
                  role: role,
                  appearance: appearance.trim(),
                  personality: personality.trim(),
                  backstory: backstory.trim(),
                );
                
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadCharacters();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCharacterDialog(Character character) {
    String name = character.name;
    String description = character.description;
    String role = character.role;
    String appearance = character.appearance;
    String personality = character.personality;
    String backstory = character.backstory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Character'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Character Name',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: name),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: Character.availableRoles.map((roleValue) {
                    return DropdownMenuItem(
                      value: roleValue,
                      child: Text(Character(
                        id: '', name: '', description: '', role: roleValue,
                        createdAt: DateTime.now(), lastModified: DateTime.now(),
                      ).roleDisplayName),
                    );
                  }).toList(),
                  onChanged: (value) => setDialogState(() => role = value ?? role),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: description),
                  onChanged: (value) => description = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Appearance',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: appearance),
                  onChanged: (value) => appearance = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Personality',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: personality),
                  onChanged: (value) => personality = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Background',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: backstory),
                  onChanged: (value) => backstory = value,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.trim().isEmpty) return;
                
                final updatedCharacter = character.copyWith(
                  name: name.trim(),
                  description: description.trim(),
                  role: role,
                  appearance: appearance.trim(),
                  personality: personality.trim(),
                  backstory: backstory.trim(),
                );
                
                final success = await CharacterService.updateCharacter(updatedCharacter);
                
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadCharacters();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCharacterDialog(Character character) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Character'),
        content: Text('Are you sure you want to delete character "${character.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final success = await CharacterService.deleteCharacter(character.id);
              if (success && mounted) {
                Navigator.pop(context);
                _loadCharacters();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}