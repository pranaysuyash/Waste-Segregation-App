import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/disposal_location.dart';
import '../models/user_contribution.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';

class ContributionSubmissionScreen extends StatefulWidget {

  const ContributionSubmissionScreen({
    super.key,
    this.facilityId,
    this.facility,
    required this.contributionType,
  });
  final String? facilityId;
  final DisposalLocation? facility;
  final ContributionType contributionType;

  @override
  State<ContributionSubmissionScreen> createState() => _ContributionSubmissionScreenState();
}

class _ContributionSubmissionScreenState extends State<ContributionSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNotesController = TextEditingController();
  
  // Controllers for different edit types
  final Map<String, TextEditingController> _operatingHoursControllers = {};
  final Map<String, TextEditingController> _contactInfoControllers = {};
  final List<String> _acceptedMaterials = [];
  final TextEditingController _materialController = TextEditingController();
  
  // For new facility
  final _facilityNameController = TextEditingController();
  final _facilityAddressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  final List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.facility != null) {
      // Initialize with existing facility data
      switch (widget.contributionType) {
        case ContributionType.editHours:
          _initializeOperatingHours();
          break;
        case ContributionType.editContact:
          _initializeContactInfo();
          break;
        case ContributionType.editAcceptedMaterials:
          _initializeAcceptedMaterials();
          break;
        case ContributionType.newFacility:
          // No initialization needed for new facility
          break;
        case ContributionType.reportClosure:
          // No additional initialization needed for report closure
          break;
        case ContributionType.addPhoto:
          // No additional initialization needed for add photo
          break;
        case ContributionType.otherCorrection:
          // No additional initialization needed for other correction
          break;
        default:
          break;
      }
    }
  }

  void _initializeOperatingHours() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (final day in days) {
      _operatingHoursControllers[day] = TextEditingController(
        text: widget.facility?.operatingHours[day] ?? '',
      );
    }
  }

  void _initializeContactInfo() {
    final contactTypes = ['phone', 'email', 'website'];
    for (final type in contactTypes) {
      _contactInfoControllers[type] = TextEditingController(
        text: widget.facility?.contactInfo[type] ?? '',
      );
    }
  }

  void _initializeAcceptedMaterials() {
    _acceptedMaterials.clear();
    if (widget.facility?.acceptedMaterials != null) {
      _acceptedMaterials.addAll(widget.facility!.acceptedMaterials);
    }
  }

  @override
  void dispose() {
    _userNotesController.dispose();
    for (final controller in _operatingHoursControllers.values) {
      controller.dispose();
    }
    for (final controller in _contactInfoControllers.values) {
      controller.dispose();
    }
    _materialController.dispose();
    _facilityNameController.dispose();
    _facilityAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionCard(),
              const SizedBox(height: AppTheme.paddingRegular),
              _buildMainFormContent(),
              const SizedBox(height: AppTheme.paddingRegular),
              _buildPhotoSection(),
              const SizedBox(height: AppTheme.paddingRegular),
              _buildUserNotesSection(),
              const SizedBox(height: AppTheme.paddingLarge),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              _getInstructionText(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFormContent() {
    switch (widget.contributionType) {
      case ContributionType.editHours:
        return _buildOperatingHoursForm();
      case ContributionType.editContact:
        return _buildContactInfoForm();
      case ContributionType.editAcceptedMaterials:
        return _buildAcceptedMaterialsForm();
      case ContributionType.newFacility:
        return _buildNewFacilityForm();
      case ContributionType.reportClosure:
        return _buildReportClosureForm();
      case ContributionType.addPhoto:
        return _buildAddPhotoForm();
      case ContributionType.otherCorrection:
        return _buildOtherCorrectionForm();
    }
  }

  Widget _buildOperatingHoursForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operating Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            ..._operatingHoursControllers.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
              child: TextFormField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: _capitalizeFirstLetter(entry.key),
                  hintText: 'e.g., 9:00 AM - 5:00 PM or Closed',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter operating hours for ${entry.key}';
                  }
                  return null;
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            ..._contactInfoControllers.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
              child: TextFormField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: _capitalizeFirstLetter(entry.key),
                  hintText: _getContactHint(entry.key),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: entry.key == 'phone' ? TextInputType.phone : 
                             entry.key == 'email' ? TextInputType.emailAddress : 
                             TextInputType.url,
                validator: (value) {
                  if (entry.key == 'email' && value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedMaterialsForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accepted Materials',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _materialController,
                    decoration: const InputDecoration(
                      labelText: 'Add Material',
                      hintText: 'e.g., Plastic bottles, Paper, Electronics',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (value) => _addMaterial(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addMaterial,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            if (_acceptedMaterials.isNotEmpty) ...[
              Text(
                'Materials List:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _acceptedMaterials.map((material) => Chip(
                  label: Text(material),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeMaterial(material),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewFacilityForm() {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                TextFormField(
                  controller: _facilityNameController,
                  decoration: const InputDecoration(
                    labelText: 'Facility Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter facility name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                TextFormField(
                  controller: _facilityAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter facility address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        _buildOperatingHoursForm(),
        const SizedBox(height: AppTheme.paddingRegular),
        _buildContactInfoForm(),
        const SizedBox(height: AppTheme.paddingRegular),
        _buildAcceptedMaterialsForm(),
      ],
    );
  }

  Widget _buildReportClosureForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Report Facility Closure',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Text(
              'You are reporting that "${widget.facility?.name}" is permanently closed. Please provide details about when you discovered this and any additional information.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Text(
              'Upload photos of the facility to help other users find and identify it.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherCorrectionForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Other Correction',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Text(
              'Please describe the issue or correction needed. Be as specific as possible to help administrators understand and address your concern.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Photos (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.paddingRegular),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose Photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            TextFormField(
              controller: _userNotesController,
              decoration: const InputDecoration(
                hintText: 'Add any additional information, context, or rationale for your contribution...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitContribution,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Submit Contribution',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (widget.contributionType) {
      case ContributionType.editHours:
        return 'Update Operating Hours';
      case ContributionType.editContact:
        return 'Update Contact Info';
      case ContributionType.editAcceptedMaterials:
        return 'Update Materials';
      case ContributionType.newFacility:
        return 'Add New Facility';
      case ContributionType.addPhoto:
        return 'Add Photos';
      case ContributionType.reportClosure:
        return 'Report Closure';
      case ContributionType.otherCorrection:
        return 'Report Issue';
    }
  }

  String _getInstructionText() {
    switch (widget.contributionType) {
      case ContributionType.editHours:
        return 'Please update the operating hours for this facility. Make sure to include all days of the week. Use "Closed" for days when the facility is not open.';
      case ContributionType.editContact:
        return 'Please provide updated contact information for this facility. Include phone numbers, email addresses, and website URLs where available.';
      case ContributionType.editAcceptedMaterials:
        return 'Please update the list of materials accepted at this facility. Add materials that are accepted but not listed, or note if any listed materials are no longer accepted.';
      case ContributionType.newFacility:
        return 'Please provide complete information about this new disposal facility. Include as much detail as possible to help other users find and use this facility.';
      case ContributionType.addPhoto:
        return 'Upload photos of this facility to help other users identify and locate it. Include photos of the building, signage, and any relevant features.';
      case ContributionType.reportClosure:
        return 'You are reporting that this facility is permanently closed. Please provide details about when and how you discovered this closure.';
      case ContributionType.otherCorrection:
        return 'Please describe any other issues or corrections needed for this facility. Be specific about what needs to be updated or corrected.';
    }
  }

  String _getContactHint(String type) {
    switch (type) {
      case 'phone':
        return '+91 XXXXXXXXXX';
      case 'email':
        return 'contact@facility.com';
      case 'website':
        return 'https://facility-website.com';
      default:
        return '';
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _addMaterial() {
    final material = _materialController.text.trim();
    if (material.isNotEmpty && !_acceptedMaterials.contains(material)) {
      setState(() {
        _acceptedMaterials.add(material);
        _materialController.clear();
      });
    }
  }

  void _removeMaterial(String material) {
    setState(() {
      _acceptedMaterials.remove(material);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitContribution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload photos if any (placeholder for now)
      final photoUrls = <String>[];
      if (_selectedImages.isNotEmpty) {
        // TODO: Implement photo upload functionality
        // For now, we'll just simulate the URLs
        for (var i = 0; i < _selectedImages.length; i++) {
          photoUrls.add('placeholder_photo_url_$i');
        }
      }

      // Prepare suggested data based on contribution type
      final suggestedData = _prepareSuggestedData();

      // Create contribution
      final contribution = UserContribution(
        userId: 'current_user_id', // TODO: Get from auth provider
        facilityId: widget.facilityId,
        contributionType: widget.contributionType,
        suggestedData: suggestedData,
        userNotes: _userNotesController.text.trim().isEmpty ? null : _userNotesController.text.trim(),
        photoUrls: photoUrls.isEmpty ? null : photoUrls,
        timestamp: Timestamp.now(),
        status: ContributionStatus.pendingReview,
      );

      // Submit to Firestore (TODO: Implement cloud function call)
      await _submitToFirestore(contribution);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contribution submitted successfully! It will be reviewed by our team.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting contribution: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic> _prepareSuggestedData() {
    switch (widget.contributionType) {
      case ContributionType.editHours:
        return {
          'operatingHours': Map.fromEntries(
            _operatingHoursControllers.entries
                .where((entry) => entry.value.text.isNotEmpty)
                .map((entry) => MapEntry(entry.key, entry.value.text)),
          ),
        };
      case ContributionType.editContact:
        return {
          'contactInfo': Map.fromEntries(
            _contactInfoControllers.entries
                .where((entry) => entry.value.text.isNotEmpty)
                .map((entry) => MapEntry(entry.key, entry.value.text)),
          ),
        };
      case ContributionType.editAcceptedMaterials:
        return {
          'acceptedMaterials': _acceptedMaterials,
        };
      case ContributionType.newFacility:
        return {
          'name': _facilityNameController.text,
          'address': _facilityAddressController.text,
          'coordinates': {
            'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
            'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
          },
          'operatingHours': Map.fromEntries(
            _operatingHoursControllers.entries
                .where((entry) => entry.value.text.isNotEmpty)
                .map((entry) => MapEntry(entry.key, entry.value.text)),
          ),
          'contactInfo': Map.fromEntries(
            _contactInfoControllers.entries
                .where((entry) => entry.value.text.isNotEmpty)
                .map((entry) => MapEntry(entry.key, entry.value.text)),
          ),
          'acceptedMaterials': _acceptedMaterials,
        };
      case ContributionType.reportClosure:
        return {
          'reported_closure': true,
          'closure_date': DateTime.now().toIso8601String(),
        };
      case ContributionType.addPhoto:
        return {
          'photo_contribution': true,
        };
      case ContributionType.otherCorrection:
        return {
          'correction_type': 'other',
          'description': _userNotesController.text,
        };
      // Default case removed as all ContributionType enum values should be handled.
    }
    // Add a fallback or error if not all paths return a value.
  }

  Future<void> _submitToFirestore(UserContribution contribution) async {
    await FirebaseFirestore.instance
        .collection('user_contributions')
        .add(contribution.toJson());
  }
} 