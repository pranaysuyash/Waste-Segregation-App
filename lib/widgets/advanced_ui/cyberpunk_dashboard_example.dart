import 'package:flutter/material.dart';
// import '../../utils/design_system.dart'; // Removed unused import
// import 'futuristic_impact_ring.dart'; // File was corrupted and removed

/// 🚀 EPIC FUTURISTIC DASHBOARD THAT WILL BLOW USERS' MINDS! 🚀
/// 
/// This showcases the cyberpunk impact rings in all their glory!
/// Features: Dark theme, neon glows, holographic effects, particle systems!

class CyberpunkWasteImpactDashboard extends StatefulWidget {
  const CyberpunkWasteImpactDashboard({super.key});

  @override
  _CyberpunkWasteImpactDashboardState createState() => _CyberpunkWasteImpactDashboardState();
}

class _CyberpunkWasteImpactDashboardState extends State<CyberpunkWasteImpactDashboard> {
  // Sample futuristic data
  double wasteItemsClassified = 73.0;
  double dailyTarget = 100.0;
  double co2Saved = 28.5;
  double co2Target = 50.0;
  int currentStreak = 12;
  int streakTarget = 30;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F), // Deep space background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00F5FF), Color(0xFFFF006E)],
          ).createShader(bounds),
          child: const Text(
            'CYBERPUNK IMPACT MATRIX',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.0,
            colors: [
              Color(0xFF1A0A2E), // Deep purple
              Color(0xFF16213E), // Dark blue
              Color(0xFF0A0A0F), // Almost black
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 🎯 MAIN CYBERPUNK CLASSIFICATION RING 🎯
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00ffff).withValues(alpha:0.5),
                    width: 3,
                  ),
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00ffff).withValues(alpha:0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${wasteItemsClassified.toInt()}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00ffff),
                        ),
                      ),
                      Text(
                        'of ${dailyTarget.toInt()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha:0.7),
                        ),
                      ),
                      const Text(
                        'ITEMS CLASSIFIED',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00ffff),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 🌟 SECONDARY IMPACT RINGS GRID 🌟
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.8,
                children: [
                  // Environmental Impact Ring
                  _buildCompactCyberRing(
                    'PLANET SAVER',
                    co2Saved,
                    co2Target,
                    'KG CO₂',
                    const [Color(0xFF39FF14), Color(0xFF00FF41)],
                    Icons.eco,
                  ),
                  
                  // Streak Ring
                  _buildCompactCyberRing(
                    'STREAK COMBO',
                    currentStreak.toDouble(),
                    streakTarget.toDouble(),
                    'DAYS',
                    const [Color(0xFFFF0080), Color(0xFF8A2BE2)],
                    Icons.whatshot,
                  ),
                  
                  // Weekly Progress
                  _buildCompactCyberRing(
                    'WEEKLY TARGET',
                    45.0,
                    70.0,
                    'ITEMS',
                    const [Color(0xFFFFD700), Color(0xFFFF4500)],
                    Icons.calendar_today,
                  ),
                  
                  // AI Efficiency
                  _buildCompactCyberRing(
                    'AI EFFICIENCY',
                    87.0,
                    100.0,
                    'PERCENT',
                    const [Color(0xFF00FFFF), Color(0xFF0080FF)],
                    Icons.psychology,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // 💫 HOLOGRAPHIC STATS PANEL 💫
              _buildHolographicStatsPanel(),
              
              const SizedBox(height: 40),
              
              // 🎮 INTERACTIVE CONTROL PANEL 🎮
              _buildCyberControlPanel(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompactCyberRing(
    String title,
    double currentValue,
    double targetValue,
    String unit,
    List<Color> colors,
    IconData icon,
  ) {
    final progress = currentValue / targetValue;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha:0.05),
            Colors.white.withValues(alpha:0.02),
            Colors.black.withValues(alpha:0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.first.withValues(alpha:0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha:0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title with neon effect
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withValues(alpha:0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 12),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Compact progress ring
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.first.withValues(alpha:0.2),
                      width: 6,
                    ),
                  ),
                ),
                
                // Progress circle
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(colors.first),
                  ),
                ),
                
                // Center content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: colors,
                      ).createShader(bounds),
                      child: Text(
                        currentValue.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha:0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progress percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.first.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.first.withValues(alpha:0.3),
              ),
            ),
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.first,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHolographicStatsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha:0.08),
            Colors.white.withValues(alpha:0.03),
            Colors.black.withValues(alpha:0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF00F5FF).withValues(alpha:0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withValues(alpha:0.2),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F5FF), Color(0xFF00D4AA)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'NEURAL ANALYTICS MATRIX',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00F5FF),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'TOTAL PROCESSED',
                  '${wasteItemsClassified.toInt()}',
                  'items today',
                  Icons.memory,
                  const Color(0xFF00F5FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'EFFICIENCY RATING',
                  '94.7%',
                  'neural accuracy',
                  Icons.psychology,
                  const Color(0xFF39FF14),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'CARBON IMPACT',
                  '${co2Saved.toStringAsFixed(1)}kg',
                  'CO₂ neutralized',
                  Icons.eco,
                  const Color(0xFF00FF41),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'STREAK POWER',
                  '${currentStreak}x',
                  'combo multiplier',
                  Icons.whatshot,
                  const Color(0xFFFF0080),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [color, color.withValues(alpha:0.7)],
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha:0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCyberControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha:0.06),
            Colors.white.withValues(alpha:0.02),
            Colors.black.withValues(alpha:0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFFF006E).withValues(alpha:0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF006E).withValues(alpha:0.2),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          const Text(
            'SYSTEM CONTROL MATRIX',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF006E),
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Control buttons
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  'BOOST NEURAL NET',
                  Icons.flash_on,
                  const [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  () => _boostSystem(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlButton(
                  'SYNC MATRIX',
                  Icons.sync,
                  const [Color(0xFF00FFFF), Color(0xFF0080FF)],
                  () => _syncMatrix(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Full width button
          _buildControlButton(
            'INITIALIZE QUANTUM PROCESSING',
            Icons.auto_awesome,
            const [Color(0xFF8A2BE2), Color(0xFF9400D3)],
            () => _quantumProcess(),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton(
    String text,
    IconData icon,
    List<Color> colors,
    VoidCallback onPressed, {
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ).copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha:0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _boostSystem() {
    setState(() {
      wasteItemsClassified = (wasteItemsClassified + 5).clamp(0, dailyTarget);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🚀 NEURAL BOOST ACTIVATED!'),
        backgroundColor: const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
  
  void _syncMatrix() {
    setState(() {
      co2Saved = (co2Saved + 2.5).clamp(0, co2Target);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('⚡ MATRIX SYNCHRONIZED!'),
        backgroundColor: const Color(0xFF00FFFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
  
  void _quantumProcess() {
    setState(() {
      currentStreak = (currentStreak + 1).clamp(0, streakTarget);
      wasteItemsClassified = (wasteItemsClassified + 3).clamp(0, dailyTarget);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🌌 QUANTUM PROCESSING INITIATED!'),
        backgroundColor: const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
