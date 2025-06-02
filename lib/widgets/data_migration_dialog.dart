import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class DataMigrationDialog extends StatefulWidget {
  final int guestDataCount;
  final VoidCallback? onMigrationComplete;

  const DataMigrationDialog({
    super.key,
    required this.guestDataCount,
    this.onMigrationComplete,
  });

  @override
  State<DataMigrationDialog> createState() => _DataMigrationDialogState();

  /// Show the migration dialog if there's guest data to migrate
  static Future<void> showIfNeeded(BuildContext context) async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final guestDataCount = await storageService.getGuestDataMigrationCount();
    
    if (guestDataCount > 0 && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DataMigrationDialog(
          guestDataCount: guestDataCount,
          onMigrationComplete: () {
            // Refresh any data that might be showing in the UI
            // This could trigger a rebuild of classification lists
          },
        ),
      );
    }
  }
}

class _DataMigrationDialogState extends State<DataMigrationDialog> {
  bool _isMigrating = false;
  bool _migrationComplete = false;
  int _migratedCount = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _migrationComplete ? Icons.check_circle : Icons.cloud_upload,
            color: _migrationComplete ? Colors.green : AppTheme.primaryColor,
          ),
          const SizedBox(width: AppTheme.paddingSmall),
          Expanded(
            child: Text(
              _migrationComplete ? 'Migration Complete!' : 'Keep Your Data?',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_migrationComplete) ...[
            Text(
              'We found ${widget.guestDataCount} waste classification${widget.guestDataCount == 1 ? '' : 's'} from when you used the app as a guest.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.paddingSmall),
                  const Expanded(
                    child: Text(
                      'Would you like to keep this data in your signed-in account?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            if (_isMigrating) ...[
              const SizedBox(height: AppTheme.paddingRegular),
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppTheme.paddingSmall),
                  Text('Migrating your data...'),
                ],
              ),
            ],
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.paddingSmall),
                Expanded(
                  child: Text(
                    'Successfully migrated $_migratedCount classification${_migratedCount == 1 ? '' : 's'} to your account!',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.cloud_done,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.paddingSmall),
                  Expanded(
                    child: Text(
                      'Your data is now linked to your account and will sync across devices.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_migrationComplete && !_isMigrating) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: _performMigration,
            child: const Text('Keep Data'),
          ),
        ] else if (_migrationComplete) ...[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onMigrationComplete?.call();
            },
            child: const Text('Continue'),
          ),
        ],
      ],
    );
  }

  Future<void> _performMigration() async {
    setState(() {
      _isMigrating = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final migratedCount = await storageService.migrateGuestDataToCurrentUser();
      
      setState(() {
        _isMigrating = false;
        _migrationComplete = true;
        _migratedCount = migratedCount;
      });
    } catch (e) {
      setState(() {
        _isMigrating = false;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 