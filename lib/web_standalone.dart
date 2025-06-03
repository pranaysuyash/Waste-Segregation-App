import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart' as app;
import 'services/storage_service.dart';
import 'services/ai_service.dart';
import 'services/educational_content_service.dart';
import 'services/gamification_service.dart';
import 'services/premium_service.dart';
import 'services/ad_service.dart';
import 'services/google_drive_service.dart';
import 'providers/theme_provider.dart';
import 'utils/constants.dart';
import 'widgets/responsive_text.dart';

/// Entry point specifically for the web version
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('🌐 Initializing Web Standalone Mode...');
    
    // Initialize Hive for web
    await Hive.initFlutter();
    
    // Open required boxes
    await Hive.openBox<String>(StorageKeys.userBox);
    await Hive.openBox<String>(StorageKeys.classificationsBox);
    await Hive.openBox<String>(StorageKeys.gamificationBox);
    await Hive.openBox<String>(StorageKeys.settingsBox);
    
    print('✅ Hive initialized successfully');
    
    // Initialize storage service
    final storageService = StorageService();
    
    // Use the Flutter runApp function
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<StorageService>.value(value: storageService),
        ],
        child: const WasteSegregationWebApp(),
      ),
    );
  } catch (e) {
    print('❌ Error initializing web app: $e');
    // Use the Flutter runApp function
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

/// Simple web app class for standalone web version
class WasteSegregationWebApp extends StatelessWidget {
  const WasteSegregationWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste Segregation App - Web',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const WebHomePage(),
    );
  }
}

/// Simple home page for web version
class WebHomePage extends StatelessWidget {
  const WebHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveAppBarTitle(
          title: 'WasteWise',
        ),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recycling,
              size: 100,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to Waste Segregation App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Web version coming soon!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home tab with app introduction
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          Center(
            child: Container(
              width: 150,
              height: 150,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.recycling,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App introduction
          const Text(
            'Welcome to Waste Segregation App',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'This application helps you properly segregate waste using AI image recognition.',
            style: TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 24),
          
          // Features section
          const Text(
            'Key Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Feature cards
          FeatureCard(
            icon: Icons.camera_alt,
            title: 'Image Recognition',
            description: 'Take a photo of an item to identify its waste category',
            color: Colors.blue.shade100,
          ),
          
          const SizedBox(height: 12),
          
          FeatureCard(
            icon: Icons.category,
            title: 'Waste Categories',
            description: 'Learn about different waste types and how to dispose of them properly',
            color: Colors.orange.shade100,
          ),
          
          const SizedBox(height: 12),
          
          FeatureCard(
            icon: Icons.bar_chart,
            title: 'Waste Analytics',
            description: 'Track your waste disposal habits and see your impact',
            color: Colors.purple.shade100,
          ),
          
          const SizedBox(height: 24),
          
          // Download section
          const Text(
            'Get the Full Experience',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'For the best experience with all features including AI image recognition, download the mobile app.',
            style: TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 16),
          
          // Download buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.android),
                label: const Text('Android App'),
                onPressed: () {
                  _showComingSoonDialog(context);
                },
              ),
              
              const SizedBox(width: 12),
              
              OutlinedButton.icon(
                icon: const Icon(Icons.apple),
                label: const Text('iOS App'),
                onPressed: () {
                  _showComingSoonDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('The mobile app will be available for download soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Learn tab with waste categories
class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waste Categories',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Learn about different types of waste and how to properly dispose of them.',
            style: TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 24),
          
          // Waste categories
          WasteCategoryCard(
            title: 'Wet Waste',
            description: 'Biodegradable waste that can be composted',
            examples: 'Food scraps, garden waste, biodegradable packaging',
            color: Colors.green.shade100,
            iconData: Icons.eco,
          ),
          
          const SizedBox(height: 16),
          
          WasteCategoryCard(
            title: 'Dry Waste',
            description: 'Non-biodegradable waste that can often be recycled',
            examples: 'Paper, plastic, glass, metal',
            color: Colors.blue.shade100,
            iconData: Icons.delete_outline,
          ),
          
          const SizedBox(height: 16),
          
          WasteCategoryCard(
            title: 'Hazardous Waste',
            description: 'Waste that poses substantial or potential threats to public health or the environment',
            examples: 'Batteries, chemicals, electronic waste',
            color: Colors.red.shade100,
            iconData: Icons.warning,
          ),
          
          const SizedBox(height: 16),
          
          WasteCategoryCard(
            title: 'Medical Waste',
            description: 'Waste generated from healthcare facilities',
            examples: 'Needles, bandages, expired medicines',
            color: Colors.purple.shade100,
            iconData: Icons.medical_services,
          ),
          
          const SizedBox(height: 16),
          
          WasteCategoryCard(
            title: 'Non-Waste',
            description: 'Items that should not be discarded',
            examples: 'Reusable items, edible food',
            color: Colors.orange.shade100,
            iconData: Icons.recycling,
          ),
        ],
      ),
    );
  }
}

// About tab with app information
class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This App',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'The Waste Segregation App is designed to help users properly classify and dispose of waste using AI technology.',
            style: TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 24),
          
          // Mission section
          const Text(
            'Our Mission',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'To reduce waste going to landfills by educating people about proper waste segregation and making it easy to identify how to dispose of items correctly.',
            style: TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 24),
          
          // Impact section
          const Text(
            'Environmental Impact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Environmental impact stats
          Row(
            children: [
              Expanded(
                child: ImpactCard(
                  title: '80%',
                  description: 'Landfill waste reduction possible with proper segregation',
                  color: Colors.green.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ImpactCard(
                  title: '1/3',
                  description: 'Of all food produced globally is wasted',
                  color: Colors.orange.shade100,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ImpactCard(
                  title: '25x',
                  description: 'Food waste in landfills produces methane 25 times more potent than CO2',
                  color: Colors.red.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ImpactCard(
                  title: '5-7x',
                  description: 'Paper can typically be recycled 5-7 times before fibers become too short',
                  color: Colors.blue.shade100,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Technology section
          const Text(
            'Technology',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'Our app uses advanced AI powered by Google Gemini to identify items from images and classify them into the appropriate waste category.',
            style: TextStyle(fontSize: 16),
          ),
          
          const SizedBox(height: 24),
          
          // Clipboard sharing section
          const Text(
            'Share This App',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Copy Share Link'),
            onPressed: () {
              _copyToClipboard(context);
            },
          ),
          
          const SizedBox(height: 40),
          
          // Footer
          const Center(
            child: Text(
              '© 2025 Waste Segregation App',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _copyToClipboard(BuildContext context) {
    // This would normally use our ShareService, but we're keeping it simple
    // for this standalone web version
    var controller = TextEditingController();
    controller.text = 'Check out the Waste Segregation App! It helps you properly sort your waste using AI: https://waste-segregation-app.web.app';
    
    // Copy to clipboard (normally you'd use Clipboard.setData)
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Reusable widgets

class FeatureCard extends StatelessWidget {

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  }) : super(key: key);
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WasteCategoryCard extends StatelessWidget {

  const WasteCategoryCard({
    Key? key,
    required this.title,
    required this.description,
    required this.examples,
    required this.color,
    required this.iconData,
  }) : super(key: key);
  final String title;
  final String description;
  final String examples;
  final Color color;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Examples: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(examples),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ImpactCard extends StatelessWidget {

  const ImpactCard({
    Key? key,
    required this.title,
    required this.description,
    required this.color,
  }) : super(key: key);
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
