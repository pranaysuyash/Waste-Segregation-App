  Future<void> _refreshAllImages(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Refreshing all images...'),
              SizedBox(height: 8),
              Text('Checking and refreshing image availability.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

      // Get the data sync provider and force refresh all images
      final dataSyncProvider = Provider.of<DataSyncProvider>(context, listen: false);
      await dataSyncProvider.forceRefreshAllImages();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Image refresh completed! Missing images have been identified.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Image refresh failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
