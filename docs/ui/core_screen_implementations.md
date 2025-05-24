# Core Screen Implementations - Technical Specifications

## 1. Home Screen Revamp - "Mission Control Dashboard"

### Current State Analysis
The existing home screen uses a simple vertical scroll layout with basic cards. We'll transform this into an engaging dashboard with floating elements and dynamic content.

### New Architecture

```dart
class NewHomeScreen extends StatefulWidget {
  @override
  _NewHomeScreenState createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> 
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _heroAnimationController;
  late AnimationController _particleController;
  late AnimationController _pulseScanController;
  late AnimationController _impactRingController;
  
  // Animation Objects
  late Animation<double> _heroScaleAnimation;
  late Animation<double> _particleOpacityAnimation;
  late Animation<double> _scanPulseAnimation;
  late Animation<double> _impactProgressAnimation;
  
  // State Variables
  double _currentImpactScore = 0.0;
  List<ParticleModel> _backgroundParticles = [];
  UserProfile? _userProfile;
  List<Achievement> _todaysAchievements = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _startBackgroundAnimations();
  }
  
  void _initializeAnimations() {
    // Hero entrance animation (app startup)
    _heroAnimationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _heroScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // Particle system for background ambiance
    _particleController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Pulsing scan button animation
    _pulseScanController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _scanPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseScanController,
      curve: Curves.easeInOut,
    ));
    
    // Impact ring progress animation
    _impactRingController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Start entrance animation
    _heroAnimationController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _heroAnimationController,
          _particleController,
          _pulseScanController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Animated gradient background
              _buildAnimatedBackground(),
              
              // Floating particles
              _buildParticleSystem(),
              
              // Main content
              Transform.scale(
                scale: _heroScaleAnimation.value,
                child: _buildMainContent(),
              ),
              
              // Floating scan button
              _buildFloatingScanButton(),
              
              // Achievement celebration overlay
              if (_todaysAchievements.isNotEmpty)
                _buildAchievementOverlay(),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NewAppTheme.primaryGradientStart.withOpacity(0.1),
            NewAppTheme.primaryGradientEnd.withOpacity(0.05),
            Colors.white,
          ],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
    );
  }
  
  Widget _buildParticleSystem() {
    return CustomPaint(
      size: Size.infinite,
      painter: FloatingParticlesPainter(
        particles: _backgroundParticles,
        animationValue: _particleController.value,
      ),
    );
  }
  
  Widget _buildMainContent() {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        // Animated App Bar
        SliverAppBar(
          expandedHeight: 120,
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: _buildWelcomeHeader(),
            background: _buildImpactRing(),
          ),
        ),
        
        // Main content sections
        SliverPadding(
          padding: EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Today's Impact Goal Card
              _buildImpactGoalCard(),
              SizedBox(height: 24),
              
              // Quick Action Cards Row
              _buildQuickActionCards(),
              SizedBox(height: 24),
              
              // Active Challenges Section
              _buildActiveChallenges(),
              SizedBox(height: 24),
              
              // Community Feed Preview
              _buildCommunityFeedPreview(),
              SizedBox(height: 24),
              
              // Recent Classifications with Swipe Actions
              _buildRecentClassifications(),
              SizedBox(height: 100), // Bottom padding for FAB
            ]),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWelcomeHeader() {
    return Container(
      child: Row(
        children: [
          // User avatar with online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _userProfile?.avatarUrl != null 
                  ? NetworkImage(_userProfile!.avatarUrl!) 
                  : null,
                child: _userProfile?.avatarUrl == null 
                  ? Icon(Icons.person, color: Colors.white)
                  : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
          
          // Welcome text with streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hi ${_userProfile?.displayName ?? 'Eco-Warrior'}!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: NewAppTheme.textPrimary,
                  ),
                ),
                if (_userProfile?.currentStreak != null && _userProfile!.currentStreak > 0)
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, 
                           color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${_userProfile!.currentStreak}-day streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: NewAppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImpactGoalCard() {
    return GlassMorphicCard(
      blur: 10,
      opacity: 0.1,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '🌍 Today\'s Impact Goal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NewAppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            
            // Animated progress ring
            AnimatedBuilder(
              animation: _impactRingController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(120, 120),
                  painter: ImpactRingPainter(
                    progress: _impactProgressAnimation.value,
                    currentScore: _currentImpactScore,
                    targetScore: _userProfile?.dailyGoal ?? 100,
                  ),
                );
              },
            ),
            
            SizedBox(height: 12),
            Text(
              'Keep going! You\'re making a difference.',
              style: TextStyle(
                fontSize: 14,
                color: NewAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionCards() {
    return Row(
      children: [
        // Scan Card (Primary action)
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: _navigateToScan,
            child: AnimatedBuilder(
              animation: _scanPulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scanPulseAnimation.value,
                  child: GlassMorphicCard(
                    gradient: LinearGradient(
                      colors: [
                        NewAppTheme.scanButtonStart,
                        NewAppTheme.scanButtonEnd,
                      ],
                    ),
                    child: Container(
                      height: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'SCAN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Identify waste',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        SizedBox(width: 16),
        
        // Learn Card (Secondary action)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _navigateToEducation,
            child: ShimmeringCard(
              shimmerColors: [
                NewAppTheme.learnButtonStart,
                NewAppTheme.learnButtonEnd,
              ],
              child: Container(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'LEARN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Explore tips',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFloatingScanButton() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Hero(
        tag: 'scan-fab',
        child: AnimatedBuilder(
          animation: _scanPulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NewAppTheme.scanButtonStart.withOpacity(0.3),
                    blurRadius: 20 * _scanPulseAnimation.value,
                    spreadRadius: 2 * _scanPulseAnimation.value,
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _navigateToScan,
                backgroundColor: NewAppTheme.scanButtonStart,
                icon: Icon(Icons.camera_alt_rounded),
                label: Text('Quick Scan'),
                heroTag: 'scan-hero',
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Navigation methods with page transitions
  void _navigateToScan() async {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Hero animation to camera screen
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          NewCameraScanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    );
    
    // Handle scan result
    if (result != null && result is WasteClassification) {
      _handleScanResult(result);
    }
  }
  
  void _handleScanResult(WasteClassification classification) {
    // Update user progress
    setState(() {
      _currentImpactScore += classification.impactPoints;
    });
    
    // Animate impact ring
    _impactRingController.forward();
    
    // Show celebration if goal reached
    if (_currentImpactScore >= (_userProfile?.dailyGoal ?? 100)) {
      _showGoalAchievedCelebration();
    }
  }
  
  void _showGoalAchievedCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GoalAchievedDialog(
        todayScore: _currentImpactScore,
        targetScore: _userProfile?.dailyGoal ?? 100,
        onContinue: () => Navigator.pop(context),
      ),
    );
  }
  
  @override
  void dispose() {
    _heroAnimationController.dispose();
    _particleController.dispose();
    _pulseScanController.dispose();
    _impactRingController.dispose();
    super.dispose();
  }
}

// Supporting Models and Painters
class ParticleModel {
  final Offset position;
  final double size;
  final Color color;
  final double speed;
  final double opacity;
  
  ParticleModel({
    required this.position,
    required this.size,
    required this.color,
    required this.speed,
    required this.opacity,
  });
}

class FloatingParticlesPainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double animationValue;
  
  FloatingParticlesPainter({
    required this.particles,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (final particle in particles) {
      paint.color = particle.color.withOpacity(
        particle.opacity * (0.5 + 0.5 * sin(animationValue * 2 * pi))
      );
      
      final animatedPosition = Offset(
        particle.position.dx + 20 * sin(animationValue * 2 * pi + particle.speed),
        particle.position.dy + 10 * cos(animationValue * 2 * pi + particle.speed),
      );
      
      canvas.drawCircle(animatedPosition, particle.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class ImpactRingPainter extends CustomPainter {
  final double progress;
  final double currentScore;
  final double targetScore;
  
  ImpactRingPainter({
    required this.progress,
    required this.currentScore,
    required this.targetScore,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw corner brackets for focus area
    final focusSize = 200.0;
    final focusRect = Rect.fromCenter(
      center: center,
      width: focusSize,
      height: focusSize,
    );
    
    // Corner brackets
    final bracketLength = 30.0;
    paint.color = isActive ? NewAppTheme.scanActiveColor : NewAppTheme.scanInactiveColor;
    
    // Top-left corner
    canvas.drawLine(
      Offset(focusRect.left, focusRect.top + bracketLength),
      Offset(focusRect.left, focusRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(focusRect.left, focusRect.top),
      Offset(focusRect.left + bracketLength, focusRect.top),
      paint,
    );
    
    // Continue for other corners...
    // (Similar pattern for top-right, bottom-left, bottom-right)
    
    // Scanning line effect
    if (isActive && scanProgress > 0) {
      final lineY = focusRect.top + (focusRect.height * scanProgress);
      paint.color = NewAppTheme.scanLineColor;
      paint.strokeWidth = 2;
      canvas.drawLine(
        Offset(focusRect.left, lineY),
        Offset(focusRect.right, lineY),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(AROverlayPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
           oldDelegate.confidenceLevel != confidenceLevel ||
           oldDelegate.isActive != isActive;
  }
}

class ScanningRingsPainter extends CustomPainter {
  final double animationValue;
  final int rings;
  
  ScanningRingsPainter({
    required this.animationValue,
    required this.rings,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (int i = 0; i < rings; i++) {
      final delay = i * 0.3;
      final adjustedProgress = (animationValue - delay).clamp(0.0, 1.0);
      
      if (adjustedProgress > 0) {
        final radius = maxRadius * adjustedProgress;
        final opacity = 1.0 - adjustedProgress;
        
        paint.color = NewAppTheme.scanRingColor.withOpacity(opacity);
        canvas.drawCircle(center, radius, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(ScanningRingsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
```

## 3. Results Screen - "Impact Reveal Experience"

### Current State Analysis
The current results screen is text-heavy and static. We'll transform it into a story-driven revelation experience with animations.

### New Architecture

```dart
class NewResultsScreen extends StatefulWidget {
  final WasteClassification classification;
  
  const NewResultsScreen({required this.classification});
  
  @override
  _NewResultsScreenState createState() => _NewResultsScreenState();
}

class _NewResultsScreenState extends State<NewResultsScreen>
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _revealController;
  late AnimationController _impactStoryController;
  late AnimationController _celebrationController;
  
  // Animation Objects
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  
  // State Variables
  int _currentStoryStep = 0;
  bool _showCelebration = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startRevealSequence();
  }
  
  void _initializeAnimations() {
    // Main reveal animation
    _revealController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    ));
    
    // Impact story animation
    _impactStoryController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Celebration animation
    _celebrationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
  }
  
  void _startRevealSequence() async {
    // Step 1: Item recognition
    await _revealController.forward();
    await Future.delayed(Duration(milliseconds: 500));
    
    // Step 2: Category reveal with particle animation
    setState(() {
      _currentStoryStep = 1;
    });
    await _impactStoryController.forward();
    
    // Step 3: Impact story
    setState(() {
      _currentStoryStep = 2;
    });
    await Future.delayed(Duration(milliseconds: 1000));
    
    // Step 4: Points celebration
    setState(() {
      _showCelebration = true;
    });
    await _celebrationController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          _buildGradientBackground(),
          
          // Main content
          _buildMainContent(),
          
          // Floating particles
          _buildParticleOverlay(),
          
          // Celebration overlay
          if (_showCelebration) _buildCelebrationOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          // Header with close button
          _buildHeader(),
          
          // Main reveal area
          Expanded(
            child: AnimatedBuilder(
              animation: _revealController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildRevealContent(),
                );
              },
            ),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildRevealContent() {
    switch (_currentStoryStep) {
      case 0:
        return _buildItemRecognition();
      case 1:
        return _buildCategoryReveal();
      case 2:
        return _buildImpactStory();
      default:
        return _buildFinalResult();
    }
  }
  
  Widget _buildItemRecognition() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Item image with glow effect
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: NewAppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.file(
              File(widget.classification.imageUrl!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        SizedBox(height: 32),
        
        // Recognition text with typewriter effect
        TypewriterText(
          text: 'Identified: ${widget.classification.itemName}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: NewAppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryReveal() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated sorting visualization
        AnimatedBuilder(
          animation: _impactStoryController,
          builder: (context, child) {
            return CustomPaint(
              size: Size(300, 200),
              painter: WasteSortingPainter(
                progress: _impactStoryController.value,
                category: widget.classification.category,
              ),
            );
          },
        ),
        
        SizedBox(height: 32),
        
        // Category badge with animation
        AnimatedContainer(
          duration: Duration(milliseconds: 600),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getCategoryGradient(widget.classification.category),
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _getCategoryColor(widget.classification.category).withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            widget.classification.category,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildImpactStory() {
    return Column(
      children: [
        // Impact journey visualization
        ImpactJourneyWidget(
          classification: widget.classification,
        ),
        
        SizedBox(height: 24),
        
        // Story cards
        Expanded(
          child: PageView(
            children: [
              ImpactStoryCard(
                title: 'Environmental Impact',
                content: widget.classification.explanation,
                icon: Icons.eco,
              ),
              ImpactStoryCard(
                title: 'Disposal Instructions',
                content: widget.classification.disposalInstructions ?? '',
                icon: Icons.recycling,
              ),
              ImpactStoryCard(
                title: 'Did You Know?',
                content: _getInterestingFact(widget.classification.category),
                icon: Icons.lightbulb,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ConfettiPainter(
                progress: _celebrationController.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Supporting widgets and painters
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const TypewriterText({required this.text, required this.style});
  
  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<int> _characterCount;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.text.length * 50),
      vsync: this,
    );
    
    _characterCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        return Text(
          widget.text.substring(0, _characterCount.value),
          style: widget.style,
        );
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class WasteSortingPainter extends CustomPainter {
  final double progress;
  final String category;
  
  WasteSortingPainter({required this.progress, required this.category});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw waste bins
    final binWidth = 60.0;
    final binHeight = 80.0;
    final binSpacing = 80.0;
    
    final bins = [
      {'color': NewAppTheme.wetWasteColor, 'label': 'Wet'},
      {'color': NewAppTheme.dryWasteColor, 'label': 'Dry'},
      {'color': NewAppTheme.hazardousWasteColor, 'label': 'Hazardous'},
      {'color': NewAppTheme.medicalWasteColor, 'label': 'Medical'},
    ];
    
    for (int i = 0; i < bins.length; i++) {
      final x = (size.width - (bins.length * binWidth + (bins.length - 1) * binSpacing)) / 2 +
                i * (binWidth + binSpacing);
      final y = size.height / 2;
      
      final paint = Paint()
        ..color = bins[i]['color'] as Color
        ..style = PaintingStyle.fill;
      
      // Draw bin
      final binRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, binWidth, binHeight),
        Radius.circular(8),
      );
      canvas.drawRRect(binRect, paint);
      
      // Highlight correct bin
      if (_shouldHighlightBin(bins[i]['label'] as String)) {
        paint.color = Colors.white.withOpacity(0.3);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 3;
        canvas.drawRRect(binRect, paint);
      }
    }
    
    // Draw falling item animation
    if (progress > 0.5) {
      final itemProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final correctBinIndex = _getCorrectBinIndex();
      
      final targetX = (size.width - (bins.length * binWidth + (bins.length - 1) * binSpacing)) / 2 +
                     correctBinIndex * (binWidth + binSpacing) + binWidth / 2;
      final startY = 50.0;
      final endY = size.height / 2 - 10;
      
      final currentY = startY + (endY - startY) * itemProgress;
      
      final itemPaint = Paint()
        ..color = NewAppTheme.primaryColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(targetX, currentY),
        8,
        itemPaint,
      );
    }
  }
  
  bool _shouldHighlightBin(String binLabel) {
    return progress > 0.2 && _getBinLabelForCategory() == binLabel;
  }
  
  String _getBinLabelForCategory() {
    switch (category.toLowerCase()) {
      case 'wet waste': return 'Wet';
      case 'dry waste': return 'Dry';
      case 'hazardous waste': return 'Hazardous';
      case 'medical waste': return 'Medical';
      default: return 'Dry';
    }
  }
  
  int _getCorrectBinIndex() {
    switch (category.toLowerCase()) {
      case 'wet waste': return 0;
      case 'dry waste': return 1;
      case 'hazardous waste': return 2;
      case 'medical waste': return 3;
      default: return 1;
    }
  }
  
  @override
  bool shouldRepaint(WasteSortingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
```

## 4. New Theme System with Proper Implementation

### Theme Class with All Required Colors

```dart
class NewAppTheme {
  // Base Colors from Design System
  static const Color oceanBlue = Color(0xFF00B4D8);
  static const Color vibrantGreen = Color(0xFF06FFA5);
  static const Color sunsetCoral = Color(0xFFFF6B6B);
  static const Color digitalPurple = Color(0xFF845EC2);
  static const Color goldenYellow = Color(0xFFFFD23F);
  static const Color softPink = Color(0xFFFF8AC1);
  
  // Gradient Definitions
  static const Color primaryGradientStart = vibrantGreen;
  static const Color primaryGradientEnd = oceanBlue;
  
  // Button Colors
  static const Color scanButtonStart = vibrantGreen;
  static const Color scanButtonEnd = oceanBlue;
  static const Color learnButtonStart = digitalPurple;
  static const Color learnButtonEnd = sunsetCoral;
  
  // Impact Ring Colors
  static const Color impactRingStart = goldenYellow;
  static const Color impactRingEnd = vibrantGreen;
  
  // Text Colors with Proper Contrast
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Scan Overlay Colors
  static const Color scanOverlayColor = Color(0xFF00B4D8);
  static const Color scanActiveColor = vibrantGreen;
  static const Color scanInactiveColor = Color(0xFF666666);
  static const Color scanLineColor = goldenYellow;
  static const Color scanRingColor = oceanBlue;
  
  // Category Colors (Improved Contrast)
  static const Color wetWasteColor = Color(0xFF2E7D32);    // Darker green
  static const Color dryWasteColor = Color(0xFF1565C0);    // Darker blue
  static const Color hazardousWasteColor = Color(0xFFD84315); // Darker orange
  static const Color medicalWasteColor = Color(0xFFC62828);  // Darker red
  static const Color nonWasteColor = Color(0xFF6A1B9A);    // Darker purple
  
  // Helper Methods
  static List<Color> _getCategoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return [wetWasteColor, Color(0xFF4CAF50)];
      case 'dry waste':
        return [dryWasteColor, Color(0xFF2196F3)];
      case 'hazardous waste':
        return [hazardousWasteColor, Color(0xFFFF5722)];
      case 'medical waste':
        return [medicalWasteColor, Color(0xFFF44336)];
      default:
        return [nonWasteColor, Color(0xFF9C27B0)];
    }
  }
  
  static Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste': return wetWasteColor;
      case 'dry waste': return dryWasteColor;
      case 'hazardous waste': return hazardousWasteColor;
      case 'medical waste': return medicalWasteColor;
      default: return nonWasteColor;
    }
  }
  
  // Dark Theme Support
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: vibrantGreen,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: vibrantGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vibrantGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: vibrantGreen,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vibrantGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }
}
```(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Background ring
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress ring with gradient
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          NewAppTheme.impactRingStart,
          NewAppTheme.impactRingEnd,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle =