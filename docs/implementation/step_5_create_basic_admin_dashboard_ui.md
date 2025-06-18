# Step 5: Create Basic Admin Dashboard UI

## 🎯 **OBJECTIVE**
Build a comprehensive admin dashboard that provides a user-friendly interface for managing all data types (guest + signed-in), ML training data, user recovery, and system monitoring while maintaining privacy protection and security.

## 📋 **PREREQUISITES**
- ✅ Step 1-4 completed: ML data collection, enhanced deletion, admin recovery service, and guest ML collection
- ✅ Existing settings screen architecture
- ✅ Admin authentication system (`pranaysuyash@gmail.com`)
- ✅ All backend services for admin operations implemented

## 🏗️ **IMPLEMENTATION TASKS**

### **Task 5.1: Create Admin Dashboard Main Screen**

#### **File: `lib/features/admin/screens/admin_dashboard_screen.dart`**

**Action Items:**
1. **Create main admin dashboard structure**
   ```dart
   class AdminDashboardScreen extends StatefulWidget {
     @override
     _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
   }
   
   class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
     int _selectedIndex = 0;
     
     final List<Widget> _screens = [
       AdminOverviewScreen(),
       UserManagementScreen(),
       MLDataManagementScreen(),
       RecoveryManagementScreen(),
       SystemMonitoringScreen(),
     ];
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(
           title: Text('Admin Dashboard'),
           backgroundColor: Colors.deepPurple,
           foregroundColor: Colors.white,
           actions: [
             IconButton(
               icon: Icon(Icons.refresh),
               onPressed: _refreshDashboard,
             ),
             IconButton(
               icon: Icon(Icons.logout),
               onPressed: _signOut,
             ),
           ],
         ),
         body: _screens[_selectedIndex],
         bottomNavigationBar: BottomNavigationBar(
           type: BottomNavigationBarType.fixed,
           currentIndex: _selectedIndex,
           onTap: (index) => setState(() => _selectedIndex = index),
           selectedItemColor: Colors.deepPurple,
           items: [
             BottomNavigationBarItem(
               icon: Icon(Icons.dashboard),
               label: 'Overview',
             ),
             BottomNavigationBarItem(
               icon: Icon(Icons.people),
               label: 'Users',
             ),
             BottomNavigationBarItem(
               icon: Icon(Icons.psychology),
               label: 'ML Data',
             ),
             BottomNavigationBarItem(
               icon: Icon(Icons.restore),
               label: 'Recovery',
             ),
             BottomNavigationBarItem(
               icon: Icon(Icons.monitoring),
               label: 'System',
             ),
           ],
         ),
       );
     }
     
     Future<void> _refreshDashboard() async {
       // Refresh all dashboard data
       setState(() {});
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Dashboard refreshed')),
       );
     }
     
     Future<void> _signOut() async {
       final confirmed = await showDialog<bool>(
         context: context,
         builder: (context) => AlertDialog(
           title: Text('Sign Out'),
           content: Text('Are you sure you want to sign out of admin dashboard?'),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context, false),
               child: Text('Cancel'),
             ),
             TextButton(
               onPressed: () => Navigator.pop(context, true),
               child: Text('Sign Out'),
             ),
           ],
         ),
       );
       
       if (confirmed == true) {
         await FirebaseAuth.instance.signOut();
         Navigator.of(context).pushReplacementNamed('/auth');
       }
     }
   }
   ```

### **Task 5.2: Create Admin Overview Screen**

#### **File: `lib/features/admin/screens/admin_overview_screen.dart`**

**Action Items:**
1. **Create comprehensive dashboard overview**
   ```dart
   class AdminOverviewScreen extends StatefulWidget {
     @override
     _AdminOverviewScreenState createState() => _AdminOverviewScreenState();
   }
   
   class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
     SystemOverviewData? _overviewData;
     bool _isLoading = true;
     
     @override
     void initState() {
     super.initState();
       _loadOverviewData();
     }
     
     @override
     Widget build(BuildContext context) {
       if (_isLoading) {
         return Center(child: CircularProgressIndicator());
       }
       
       if (_overviewData == null) {
         return Center(child: Text('Failed to load dashboard data'));
       }
       
       return RefreshIndicator(
         onRefresh: _loadOverviewData,
         child: ListView(
           padding: EdgeInsets.all(16),
           children: [
             _buildWelcomeCard(),
             SizedBox(height: 16),
             _buildQuickStatsGrid(),
             SizedBox(height: 16),
             _buildMLDataOverview(),
             SizedBox(height: 16),
             _buildUserActivityOverview(),
             SizedBox(height: 16),
             _buildRecoveryRequestsOverview(),
             SizedBox(height: 16),
             _buildQuickActions(),
           ],
         ),
       );
     }
     
     Widget _buildWelcomeCard() {
       return Card(
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
                   SizedBox(width: 8),
                   Text(
                     'Admin Dashboard',
                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
               SizedBox(height: 8),
               Text(
                 'Welcome back! Here\'s your system overview.',
                 style: TextStyle(color: Colors.grey[600]),
               ),
               SizedBox(height: 8),
               Text(
                 'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                 style: TextStyle(fontSize: 12, color: Colors.grey[500]),
               ),
             ],
           ),
         ),
       );
     }
     
     Widget _buildQuickStatsGrid() {
       return GridView.count(
         crossAxisCount: 2,
         shrinkWrap: true,
         physics: NeverScrollableScrollPhysics(),
         childAspectRatio: 1.5,
         crossAxisSpacing: 16,
         mainAxisSpacing: 16,
         children: [
           _buildStatCard(
             'Total Users',
             _overviewData!.totalUsers.toString(),
             Icons.people,
             Colors.blue,
           ),
           _buildStatCard(
             'Guest Users',
             _overviewData!.guestUsers.toString(),
             Icons.person,
             Colors.green,
           ),
           _buildStatCard(
             'ML Classifications',
             _overviewData!.totalMLClassifications.toString(),
             Icons.psychology,
             Colors.purple,
           ),
           _buildStatCard(
             'Recovery Requests',
             _overviewData!.pendingRecoveryRequests.toString(),
             Icons.restore,
             Colors.orange,
           ),
         ],
       );
     }
     
     Widget _buildStatCard(String title, String value, IconData icon, Color color) {
       return Card(
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(icon, size: 32, color: color),
               SizedBox(height: 8),
               Text(
                 value,
                 style: TextStyle(
                   fontSize: 24,
                   fontWeight: FontWeight.bold,
                   color: color,
                 ),
               ),
               Text(
                 title,
                 style: TextStyle(
                   fontSize: 12,
                   color: Colors.grey[600],
                 ),
                 textAlign: TextAlign.center,
               ),
             ],
           ),
         ),
       );
     }
     
     Future<void> _loadOverviewData() async {
       setState(() => _isLoading = true);
       
       try {
         final overviewData = await AdminOverviewService.getSystemOverview();
         setState(() {
           _overviewData = overviewData;
           _isLoading = false;
         });
       } catch (e) {
         debugPrint('Error loading overview data: $e');
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Failed to load dashboard data: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
   }
   ```

2. **Create AdminOverviewService**
   ```dart
   // File: lib/core/services/admin_overview_service.dart
   class AdminOverviewService {
     static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
     
     static Future<SystemOverviewData> getSystemOverview() async {
       await _verifyAdminAccess();
       
       try {
         // Get counts in parallel for performance
         final futures = await Future.wait([
           _getTotalUsers(),
           _getGuestUsers(),
           _getTotalMLClassifications(),
           _getPendingRecoveryRequests(),
           _getRecentActivity(),
         ]);
         
         return SystemOverviewData(
           totalUsers: futures[0] as int,
           guestUsers: futures[1] as int,
           totalMLClassifications: futures[2] as int,
           pendingRecoveryRequests: futures[3] as int,
           recentActivity: futures[4] as List<ActivityItem>,
           lastUpdated: DateTime.now(),
         );
         
       } catch (e) {
         debugPrint('Error getting system overview: $e');
         rethrow;
       }
     }
     
     static Future<int> _getTotalUsers() async {
       final snapshot = await _firestore.collection('users').count().get();
       return snapshot.count;
     }
     
     static Future<int> _getGuestUsers() async {
       final snapshot = await _firestore
           .collection('admin_user_recovery')
           .where('userType', isEqualTo: 'guest')
           .count()
           .get();
       return snapshot.count;
     }
     
     static Future<int> _getTotalMLClassifications() async {
       final snapshot = await _firestore
           .collection('admin_classifications')
           .count()
           .get();
       return snapshot.count;
     }
     
     static Future<int> _getPendingRecoveryRequests() async {
       final snapshot = await _firestore
           .collection('admin_recovery_requests')
           .where('status', isEqualTo: 'pending')
           .count()
           .get();
       return snapshot.count;
     }
     
     static Future<void> _verifyAdminAccess() async {
       final currentUser = FirebaseAuth.instance.currentUser;
       if (currentUser == null || currentUser.email != 'pranaysuyash@gmail.com') {
         throw Exception('Unauthorized: Admin access required');
       }
     }
   }
   
   class SystemOverviewData {
     final int totalUsers;
     final int guestUsers;
     final int totalMLClassifications;
     final int pendingRecoveryRequests;
     final List<ActivityItem> recentActivity;
     final DateTime lastUpdated;
     
     SystemOverviewData({
       required this.totalUsers,
       required this.guestUsers,
       required this.totalMLClassifications,
       required this.pendingRecoveryRequests,
       required this.recentActivity,
       required this.lastUpdated,
     });
   }
   ```

### **Task 5.3: Create User Management Screen**

#### **File: `lib/features/admin/screens/user_management_screen.dart`**

**Action Items:**
1. **Create user search and management interface**
   ```dart
   class UserManagementScreen extends StatefulWidget {
     @override
     _UserManagementScreenState createState() => _UserManagementScreenState();
   }
   
   class _UserManagementScreenState extends State<UserManagementScreen> {
     final TextEditingController _searchController = TextEditingController();
     UserRecoveryInfo? _foundUser;
     bool _isSearching = false;
     List<RecoveryRequest> _recentRequests = [];
     
     @override
     void initState() {
       super.initState();
       _loadRecentRequests();
     }
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         body: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               _buildUserSearchSection(),
               SizedBox(height: 24),
               _buildUserResultSection(),
               SizedBox(height: 24),
               _buildRecentRequestsSection(),
             ],
           ),
         ),
       );
     }
     
     Widget _buildUserSearchSection() {
       return Card(
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'User Lookup',
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
               ),
               SizedBox(height: 12),
               Row(
                 children: [
                   Expanded(
                     child: TextField(
                       controller: _searchController,
                       decoration: InputDecoration(
                         labelText: 'User Email',
                         hintText: 'Enter user email to lookup',
                         border: OutlineInputBorder(),
                         prefixIcon: Icon(Icons.search),
                       ),
                       onSubmitted: (_) => _searchUser(),
                     ),
                   ),
                   SizedBox(width: 12),
                   ElevatedButton(
                     onPressed: _isSearching ? null : _searchUser,
                     child: _isSearching
                         ? SizedBox(
                             width: 20,
                             height: 20,
                             child: CircularProgressIndicator(strokeWidth: 2),
                           )
                         : Text('Search'),
                   ),
                 ],
               ),
               SizedBox(height: 8),
               Text(
                 'Privacy-preserving lookup using hashed user correlation',
                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
               ),
             ],
           ),
         ),
       );
     }
     
     Widget _buildUserResultSection() {
       if (_foundUser == null) {
         return SizedBox();
       }
       
       return Card(
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Icon(Icons.person, color: Colors.blue),
                   SizedBox(width: 8),
                   Text(
                     'User Found',
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
               SizedBox(height: 16),
               _buildUserInfoRow('Classifications', _foundUser!.classificationCount.toString()),
               _buildUserInfoRow('Last Backup', _foundUser!.lastBackup?.toString().substring(0, 16) ?? 'Never'),
               _buildUserInfoRow('App Version', _foundUser!.appVersion ?? 'Unknown'),
               _buildUserInfoRow('Region', _foundUser!.region ?? 'Unknown'),
               _buildUserInfoRow('Account Status', _foundUser!.accountDeleted ? 'Deleted' : 'Active'),
               if (_foundUser!.accountDeleted) ...[
                 _buildUserInfoRow('Deletion Type', _foundUser!.deletionType ?? 'Unknown'),
                 _buildUserInfoRow('Data Preserved', _foundUser!.dataPreserved ? 'Yes' : 'No'),
               ],
               SizedBox(height: 16),
               Row(
                 children: [
                   ElevatedButton.icon(
                     onPressed: () => _viewUserClassifications(),
                     icon: Icon(Icons.list),
                     label: Text('View Classifications'),
                   ),
                   SizedBox(width: 12),
                   ElevatedButton.icon(
                     onPressed: () => _initiateRecovery(),
                     icon: Icon(Icons.restore),
                     label: Text('Start Recovery'),
                   ),
                 ],
               ),
             ],
           ),
         ),
       );
     }
     
     Widget _buildUserInfoRow(String label, String value) {
       return Padding(
         padding: EdgeInsets.symmetric(vertical: 4),
         child: Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             SizedBox(
               width: 120,
               child: Text(
                 '$label:',
                 style: TextStyle(fontWeight: FontWeight.w500),
               ),
             ),
             Expanded(
               child: Text(
                 value,
                 style: TextStyle(color: Colors.grey[700]),
               ),
             ),
           ],
         ),
       );
     }
     
     Future<void> _searchUser() async {
       if (_searchController.text.trim().isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Please enter a user email')),
         );
         return;
       }
       
       setState(() => _isSearching = true);
       
       try {
         final userInfo = await AdminDataRecoveryService.lookupUserForRecovery(
           _searchController.text.trim()
         );
         
         setState(() {
           _foundUser = userInfo;
           _isSearching = false;
         });
         
         if (userInfo == null) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('No data found for this user'),
               backgroundColor: Colors.orange,
             ),
           );
         }
         
       } catch (e) {
         setState(() => _isSearching = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Search failed: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
     
     Future<void> _viewUserClassifications() async {
       if (_foundUser == null) return;
       
       Navigator.of(context).push(
         MaterialPageRoute(
           builder: (context) => UserClassificationsScreen(
             userRecoveryInfo: _foundUser!,
           ),
         ),
       );
     }
     
     Future<void> _initiateRecovery() async {
       if (_foundUser == null) return;
       
       Navigator.of(context).push(
         MaterialPageRoute(
           builder: (context) => InitiateRecoveryScreen(
             userRecoveryInfo: _foundUser!,
             userEmail: _searchController.text.trim(),
           ),
         ),
       );
     }
   }
   ```

### **Task 5.4: Create ML Data Management Screen**

#### **File: `lib/features/admin/screens/ml_data_management_screen.dart`**

**Action Items:**
1. **Create ML data overview and management interface**
   ```dart
   class MLDataManagementScreen extends StatefulWidget {
     @override
     _MLDataManagementScreenState createState() => _MLDataManagementScreenState();
   }
   
   class _MLDataManagementScreenState extends State<MLDataManagementScreen> {
     MLDataAnalytics? _analytics;
     bool _isLoading = true;
     
     @override
     void initState() {
       super.initState();
       _loadMLAnalytics();
     }
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         body: _isLoading
             ? Center(child: CircularProgressIndicator())
             : RefreshIndicator(
                 onRefresh: _loadMLAnalytics,
                 child: ListView(
                   padding: EdgeInsets.all(16),
                   children: [
                     _buildMLDataOverview(),
                     SizedBox(height: 16),
                     _buildDataQualitySection(),
                     SizedBox(height: 16),
                     _buildDataDistributionSection(),
                     SizedBox(height: 16),
                     _buildMLDataActions(),
                   ],
                 ),
               ),
       );
     }
     
     Widget _buildMLDataOverview() {
       return Card(
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Icon(Icons.psychology, color: Colors.purple),
                   SizedBox(width: 8),
                   Text(
                     'ML Training Data Overview',
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
               SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(
                     child: _buildMLStatCard(
                       'Total Classifications',
                       _analytics?.totalClassifications.toString() ?? '0',
                       Colors.blue,
                     ),
                   ),
                   SizedBox(width: 12),
                   Expanded(
                     child: _buildMLStatCard(
                       'Guest Data',
                       _analytics?.guestClassifications.toString() ?? '0',
                       Colors.green,
                     ),
                   ),
                 ],
               ),
               SizedBox(height: 12),
               Row(
                 children: [
                   Expanded(
                     child: _buildMLStatCard(
                       'Signed-in Data',
                       _analytics?.signedInClassifications.toString() ?? '0',
                       Colors.orange,
                     ),
                   ),
                   SizedBox(width: 12),
                   Expanded(
                     child: _buildMLStatCard(
                       'Data Quality',
                       '${(_analytics?.averageQualityScore ?? 0).toStringAsFixed(1)}%',
                       Colors.purple,
                     ),
                   ),
                 ],
               ),
             ],
           ),
         ),
       );
     }
     
     Widget _buildMLStatCard(String label, String value, Color color) {
       return Container(
         padding: EdgeInsets.all(12),
         decoration: BoxDecoration(
           color: color.withOpacity(0.1),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: color.withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               value,
               style: TextStyle(
                 fontSize: 20,
                 fontWeight: FontWeight.bold,
                 color: color,
               ),
             ),
             SizedBox(height: 4),
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
     
     Widget _buildDataQualitySection() {
       return Card(
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'Data Quality Metrics',
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
               ),
               SizedBox(height: 12),
               if (_analytics?.categoryDistribution != null) ...[
                 Text('Category Distribution:', style: TextStyle(fontWeight: FontWeight.w500)),
                 SizedBox(height: 8),
                 ..._analytics!.categoryDistribution.entries.map(
                   (entry) => Padding(
                     padding: EdgeInsets.symmetric(vertical: 2),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(entry.key),
                         Text('${entry.value} items'),
                       ],
                     ),
                   ),
                 ).toList(),
               ],
               SizedBox(height: 16),
               ElevatedButton.icon(
                 onPressed: _exportMLDataQualityReport,
                 icon: Icon(Icons.download),
                 label: Text('Export Quality Report'),
               ),
             ],
           ),
         ),
       );
     }
     
     Widget _buildMLDataActions() {
       return Card(
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'ML Data Actions',
                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
               ),
               SizedBox(height: 12),
               Wrap(
                 spacing: 12,
                 runSpacing: 12,
                 children: [
                   ElevatedButton.icon(
                     onPressed: _exportTrainingDataset,
                     icon: Icon(Icons.file_download),
                     label: Text('Export Training Set'),
                   ),
                   ElevatedButton.icon(
                     onPressed: _viewDataSamples,
                     icon: Icon(Icons.preview),
                     label: Text('View Samples'),
                   ),
                   ElevatedButton.icon(
                     onPressed: _validateDataPrivacy,
                     icon: Icon(Icons.shield),
                     label: Text('Privacy Check'),
                   ),
                   ElevatedButton.icon(
                     onPressed: _cleanupLowQualityData,
                     icon: Icon(Icons.cleaning_services),
                     label: Text('Cleanup Data'),
                   ),
                 ],
               ),
             ],
           ),
         ),
       );
     }
     
     Future<void> _loadMLAnalytics() async {
       setState(() => _isLoading = true);
       
       try {
         final analytics = await MLDataAnalyticsService.getMLDataAnalytics();
         setState(() {
           _analytics = analytics;
           _isLoading = false;
         });
       } catch (e) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Failed to load ML analytics: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
     
     Future<void> _exportTrainingDataset() async {
       try {
         final dataset = await MLDataExportService.exportTrainingDataset();
         
         // Show export success dialog
         showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: Text('Export Successful'),
             content: Text('Training dataset exported with ${dataset.length} classifications'),
             actions: [
               TextButton(
                 onPressed: () => Navigator.pop(context),
                 child: Text('OK'),
               ),
             ],
           ),
         );
         
       } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Export failed: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
   }
   ```

### **Task 5.5: Create Recovery Management Screen**

#### **File: `lib/features/admin/screens/recovery_management_screen.dart`**

**Action Items:**
1. **Create recovery request management interface**
   ```dart
   class RecoveryManagementScreen extends StatefulWidget {
     @override
     _RecoveryManagementScreenState createState() => _RecoveryManagementScreenState();
   }
   
   class _RecoveryManagementScreenState extends State<RecoveryManagementScreen> {
     List<RecoveryRequest> _pendingRequests = [];
     List<RecoveryRequest> _recentRequests = [];
     bool _isLoading = true;
     
     @override
     void initState() {
       super.initState();
       _loadRecoveryRequests();
     }
     
     @override
     Widget build(BuildContext context) {
       return DefaultTabController(
         length: 2,
         child: Scaffold(
           appBar: AppBar(
             title: Text('Recovery Management'),
             bottom: TabBar(
               tabs: [
                 Tab(text: 'Pending (${_pendingRequests.length})'),
                 Tab(text: 'Recent'),
               ],
             ),
           ),
           body: TabBarView(
             children: [
               _buildPendingRequestsTab(),
               _buildRecentRequestsTab(),
             ],
           ),
         ),
       );
     }
     
     Widget _buildPendingRequestsTab() {
       if (_isLoading) {
         return Center(child: CircularProgressIndicator());
       }
       
       if (_pendingRequests.isEmpty) {
         return Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.check_circle, size: 64, color: Colors.green),
               SizedBox(height: 16),
               Text('No pending recovery requests'),
               Text('All caught up!', style: TextStyle(color: Colors.grey)),
             ],
           ),
         );
       }
       
       return ListView.builder(
         padding: EdgeInsets.all(16),
         itemCount: _pendingRequests.length,
         itemBuilder: (context, index) {
           final request = _pendingRequests[index];
           return _buildRecoveryRequestCard(request, isPending: true);
         },
       );
     }
     
     Widget _buildRecoveryRequestCard(RecoveryRequest request, {bool isPending = false}) {
       final statusColor = _getStatusColor(request.status);
       
       return Card(
         margin: EdgeInsets.only(bottom: 12),
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Container(
                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: statusColor.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: statusColor.withOpacity(0.3)),
                     ),
                     child: Text(
                       request.status.toUpperCase(),
                       style: TextStyle(
                         fontSize: 10,
                         fontWeight: FontWeight.bold,
                         color: statusColor,
                       ),
                     ),
                   ),
                   Spacer(),
                   Text(
                     request.createdAt.toString().substring(0, 16),
                     style: TextStyle(fontSize: 12, color: Colors.grey),
                   ),
                 ],
               ),
               SizedBox(height: 12),
               Text(
                 'Request ID: ${request.requestId}',
                 style: TextStyle(fontWeight: FontWeight.bold),
               ),
               SizedBox(height: 4),
               Text('Target User: ${request.targetUserId}'),
               SizedBox(height: 4),
               Text('Admin: ${request.adminEmail}'),
               SizedBox(height: 4),
               Text('Reason: ${request.reason}'),
               if (request.restoredClassificationCount != null) ...[
                 SizedBox(height: 4),
                 Text('Restored: ${request.restoredClassificationCount} classifications'),
               ],
               if (isPending) ...[
                 SizedBox(height: 16),
                 Row(
                   children: [
                     ElevatedButton.icon(
                       onPressed: () => _processRecoveryRequest(request),
                       icon: Icon(Icons.play_arrow),
                       label: Text('Process'),
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                     ),
                     SizedBox(width: 12),
                     OutlinedButton.icon(
                       onPressed: () => _cancelRecoveryRequest(request),
                       icon: Icon(Icons.cancel),
                       label: Text('Cancel'),
                     ),
                   ],
                 ),
               ],
             ],
           ),
         ),
       );
     }
     
     Color _getStatusColor(String status) {
       switch (status.toLowerCase()) {
         case 'pending':
           return Colors.orange;
         case 'completed':
           return Colors.green;
         case 'failed':
           return Colors.red;
         case 'cancelled':
           return Colors.grey;
         default:
           return Colors.blue;
       }
     }
     
     Future<void> _loadRecoveryRequests() async {
       setState(() => _isLoading = true);
       
       try {
         final pending = await AdminDataRecoveryService.getPendingRecoveryRequests();
         final recent = await AdminDataRecoveryService.getAllRecoveryRequests(limit: 20);
         
         setState(() {
           _pendingRequests = pending;
           _recentRequests = recent.where((r) => r.status != 'pending').toList();
           _isLoading = false;
         });
         
       } catch (e) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Failed to load recovery requests: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
     
     Future<void> _processRecoveryRequest(RecoveryRequest request) async {
       // Navigate to detailed recovery processing screen
       final result = await Navigator.of(context).push<bool>(
         MaterialPageRoute(
           builder: (context) => ProcessRecoveryScreen(request: request),
         ),
       );
       
       if (result == true) {
         _loadRecoveryRequests(); // Refresh the list
       }
     }
   }
   ```

### **Task 5.6: Create Admin Settings and Access Control**

#### **File: `lib/features/admin/widgets/admin_access_widget.dart`**

**Action Items:**
1. **Add admin dashboard access to settings**
   ```dart
   class AdminAccessWidget extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return FutureBuilder<bool>(
         future: _checkAdminAccess(),
         builder: (context, snapshot) {
           if (!snapshot.hasData || !snapshot.data!) {
             return SizedBox(); // Hide if not admin
           }
           
           return Card(
             color: Colors.deepPurple.withOpacity(0.1),
             child: ListTile(
               leading: Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
               title: Text(
                 'Admin Dashboard',
                 style: TextStyle(fontWeight: FontWeight.bold),
               ),
               subtitle: Text('System management and data oversight'),
               trailing: Icon(Icons.arrow_forward_ios),
               onTap: () => _openAdminDashboard(context),
             ),
           );
         },
       );
     }
     
     Future<bool> _checkAdminAccess() async {
       final user = FirebaseAuth.instance.currentUser;
       return user?.email == 'pranaysuyash@gmail.com';
     }
     
     void _openAdminDashboard(BuildContext context) {
       Navigator.of(context).push(
         MaterialPageRoute(
           builder: (context) => AdminDashboardScreen(),
         ),
       );
     }
   }
   ```

2. **Update main settings screen to include admin access**
   ```dart
   // In lib/features/settings/screens/settings_screen.dart
   // Add this widget to the settings list:
   
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(title: Text('Settings')),
       body: ListView(
         children: [
           // Existing settings sections...
           
           // NEW: Admin access section
           AdminAccessWidget(),
           
           // Continue with existing settings...
         ],
       ),
     );
   }
   ```

### **Task 5.7: Create Admin Services and Models**

#### **File: `lib/core/services/ml_data_analytics_service.dart`**

**Action Items:**
1. **Create ML data analytics service**
   ```dart
   class MLDataAnalyticsService {
     static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
     
     static Future<MLDataAnalytics> getMLDataAnalytics() async {
       await _verifyAdminAccess();
       
       try {
         // Get all ML classifications
         final classificationsQuery = await _firestore
             .collection('admin_classifications')
             .get();
             
         final docs = classificationsQuery.docs;
         
         // Calculate analytics
         final totalClassifications = docs.length;
         final guestClassifications = docs
             .where((doc) => doc.data()['userType'] == 'guest')
             .length;
         final signedInClassifications = totalClassifications - guestClassifications;
         
         // Calculate category distribution
         final categoryDistribution = <String, int>{};
         for (final doc in docs) {
           final category = doc.data()['category'] as String?;
           if (category != null) {
             categoryDistribution[category] = 
                 (categoryDistribution[category] ?? 0) + 1;
           }
         }
         
         return MLDataAnalytics(
           totalClassifications: totalClassifications,
           guestClassifications: guestClassifications,
           signedInClassifications: signedInClassifications,
           categoryDistribution: categoryDistribution,
           averageQualityScore: 85.0, // TODO: Implement quality scoring
           lastUpdated: DateTime.now(),
         );
         
       } catch (e) {
         debugPrint('Error getting ML analytics: $e');
         rethrow;
       }
     }
     
     static Future<void> _verifyAdminAccess() async {
       final user = FirebaseAuth.instance.currentUser;
       if (user?.email != 'pranaysuyash@gmail.com') {
         throw Exception('Unauthorized: Admin access required');
       }
     }
   }
   
   class MLDataAnalytics {
     final int totalClassifications;
     final int guestClassifications;
     final int signedInClassifications;
     final Map<String, int> categoryDistribution;
     final double averageQualityScore;
     final DateTime lastUpdated;
     
     MLDataAnalytics({
       required this.totalClassifications,
       required this.guestClassifications,
       required this.signedInClassifications,
       required this.categoryDistribution,
       required this.averageQualityScore,
       required this.lastUpdated,
     });
   }
   ```

### **Task 5.8: Add Navigation and Routing**

#### **File: `lib/core/routes/admin_routes.dart`**

**Action Items:**
1. **Create admin routing system**
   ```dart
   class AdminRoutes {
     static const String dashboard = '/admin/dashboard';
     static const String userManagement = '/admin/users';
     static const String mlDataManagement = '/admin/ml-data';
     static const String recoveryManagement = '/admin/recovery';
     static const String systemMonitoring = '/admin/system';
     
     static Map<String, WidgetBuilder> getRoutes() {
       return {
         dashboard: (context) => AdminDashboardScreen(),
         userManagement: (context) => UserManagementScreen(),
         mlDataManagement: (context) => MLDataManagementScreen(),
         recoveryManagement: (context) => RecoveryManagementScreen(),
         systemMonitoring: (context) => SystemMonitoringScreen(),
       };
     }
   }
   ```

2. **Update main app routing**
   ```dart
   // In lib/main.dart or lib/app.dart
   MaterialApp(
     routes: {
       // Existing routes...
       ...AdminRoutes.getRoutes(),
     },
   )
   ```

## 🔍 **VERIFICATION CHECKLIST**

### **Functional Verification:**
- [ ] Admin dashboard loads with correct authentication
- [ ] All five main sections (Overview, Users, ML Data, Recovery, System) work
- [ ] User lookup works with privacy-preserving search
- [ ] ML data analytics show correct statistics
- [ ] Recovery request management functions properly
- [ ] Admin access is properly secured and logged

### **UI/UX Verification:**
- [ ] Dashboard is responsive and user-friendly
- [ ] Navigation between sections is smooth
- [ ] Data loading states are handled gracefully
- [ ] Error messages are informative and helpful
- [ ] Refresh functionality works on all screens

### **Security Verification:**
- [ ] Only admin email can access dashboard
- [ ] All admin actions are logged and auditable
- [ ] Personal user data is never displayed to admin
- [ ] Authentication is verified for each admin operation

## 🚨 **CRITICAL SUCCESS FACTORS**

1. **Security First**: Strict admin authentication and authorization
2. **Privacy Protection**: No personal data exposure in admin interface
3. **User-Friendly Design**: Intuitive interface for complex admin operations
4. **Comprehensive Coverage**: Access to all ML and user data management features

## 📈 **SUCCESS METRICS**

- **Admin Productivity**: <5 minutes average time for common admin tasks
- **Security Compliance**: 100% of admin actions properly authenticated and logged
- **Data Access**: 100% coverage of all user and ML data types
- **User Experience**: Intuitive interface requiring minimal training

## 🔄 **NEXT STEPS**
After completing this step:
1. All 5 implementation steps are complete
2. Test the complete admin workflow end-to-end
3. Train admin users on new dashboard capabilities
4. Monitor admin usage and gather feedback for improvements

## 💡 **NOTES FOR AI AGENTS**

- **Security Critical**: Every admin operation must be authenticated and logged
- **Privacy Protection**: Admin interface must never show personal user data
- **User Experience**: Design for efficiency and clarity in admin workflows
- **Error Handling**: Graceful failure with informative error messages
- **Performance**: Optimize for large datasets and concurrent admin users
- **Testing Essential**: Test all admin operations thoroughly before deployment

---

## 🎯 **COMPLETE IMPLEMENTATION SUMMARY**

With the completion of Step 5, you will have:

### **✅ ML Training Data Collection (Step 1)**
- Automatic collection from all users (guest + signed-in)
- Privacy-preserving anonymization
- Recovery metadata correlation

### **✅ Enhanced Deletion with ML Preservation (Step 2)**
- GDPR-compliant account deletion
- ML training data preservation
- Multiple reset options

### **✅ Privacy-Preserving Admin Recovery (Step 3)**
- Hashed user lookup system
- Complete data recovery workflows
- Privacy-protected admin operations

### **✅ Guest User ML Data Collection (Step 4)**
- Anonymous guest classification collection
- Admin access to all guest data
- Enhanced guest user experience

### **✅ Comprehensive Admin Dashboard (Step 5)**
- Complete admin interface for all operations
- ML data management and analytics
- User recovery management
- System monitoring and oversight

**Result**: A complete ML training data collection system with world-class privacy protection, comprehensive admin tools, and full GDPR compliance.
