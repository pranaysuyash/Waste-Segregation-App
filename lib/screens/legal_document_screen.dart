import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/constants.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  String _documentContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final String content = await rootBundle.loadString(widget.assetPath);
      setState(() {
        _documentContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _documentContent = 'Error loading document: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement sharing functionality (optional)
              // share.Share.share(_documentContent, subject: widget.title);
            },
            tooltip: 'Share Document',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
              data: _documentContent,
              selectable: true,
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              styleSheet: MarkdownStyleSheet(
                h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                p: Theme.of(context).textTheme.bodyMedium,
                strong: const TextStyle(fontWeight: FontWeight.bold),
                blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                tableHead: const TextStyle(fontWeight: FontWeight.w600),
                tableBody: Theme.of(context).textTheme.bodySmall,
              ),
            ),
    );
  }
}
