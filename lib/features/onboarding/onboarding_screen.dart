import 'package:flutter/material.dart';
import '../../gen/assets.gen.dart';
import '../info/info_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Create Your Own Manga",
      description: "Turn your creative ideas into amazing manga pages with professional and easy-to-use drawing tools",
      primaryColor: const Color(0xFFFF6B6B),
      secondaryColor: const Color(0xFFFFE66D),
    ),
    OnboardingData(
      title: "Professional Drawing Tools",
      description: "Use diverse brushes, layer system and special effects to create vivid manga characters",
      primaryColor: const Color(0xFF4ECDC4),
      secondaryColor: const Color(0xFF44A08D),
    ),
    OnboardingData(
      title: "Share & Connect",
      description: "Upload your work and connect with the manga creator community worldwide",
      primaryColor: const Color(0xFF667eea),
      secondaryColor: const Color(0xFF764ba2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _buildPageIndicator(),
                const SizedBox(height: 30),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.onboardingImage.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        // Dark overlay for better text readability
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.7),
              data.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Main content container
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    // Enhanced glass morphism effect
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Icon with background
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              data.primaryColor,
                              data.secondaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: data.primaryColor.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForPage(_currentPage),
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title with shadow
                      Text(
                        data.title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Description with shadow
                      Text(
                        data.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.6,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForPage(int index) {
    switch (index) {
      case 0:
        return Icons.auto_stories_rounded;
      case 1:
        return Icons.brush_rounded;
      case 2:
        return Icons.share_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _pages.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index 
                  ? _pages[_currentPage].primaryColor
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip button
          if (_currentPage < _pages.length - 1)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextButton(
                onPressed: () {
                  _navigateToInfo();
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 80),

          // Next/Get Started button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _pages[_currentPage].primaryColor,
                  _pages[_currentPage].secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _pages[_currentPage].primaryColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _navigateToInfo();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentPage < _pages.length - 1 
                        ? Icons.arrow_forward_rounded 
                        : Icons.rocket_launch_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToInfo() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const InfoScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingData {
  final String title;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;

  OnboardingData({
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
  });
}


