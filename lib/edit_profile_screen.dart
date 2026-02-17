import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dejtingapp/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';

import 'api_services.dart';
import 'components/photo_grid_card.dart';
import 'models.dart';
import 'services/photo_service.dart';
import 'utils/profile_completion_calculator.dart';
import 'services/api_service.dart' as session_api;

class EditProfileScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final bool isFirstTime;

  const EditProfileScreen({
    super.key,
    this.userProfile,
    this.isFirstTime = false,
  });

  @override
  _EditProfileScreenState createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final PhotoService _photoService = PhotoService();

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();

  // Form data
  DateTime? _selectedDate;
  String? _selectedEducation;
  String? _selectedGender;
  String? _selectedLookingFor;
  String? _selectedRelationshipType;
  String? _selectedDrinking;
  String? _selectedSmoking;
  String? _selectedWorkout;
  List<String> _interests = [];
  List<String> _languages = [];
  List<String> _photoUrls = [];
  List<_PhotoSlot> _photoSlots = [];

  // State
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  int _profileCompletionPercentage = 0;
  int? _uploadingIndex;
  Map<String, String>? _imageHeaders;

  Future<String?> _getAuthToken() async {
    final token = await userApi.getAuthToken();
    if (token != null && token.trim().isNotEmpty) {
      return token;
    }

    final fallbackToken = session_api.AppState().authToken;
    if (fallbackToken != null && fallbackToken.trim().isNotEmpty) {
      debugPrint('🔁 Falling back to AppState auth token.');
      return fallbackToken;
    }

    debugPrint('⚠️ No authentication token available for photo operations.');
    return null;
  }

  // Options
  final List<String> _educationOptions = [
    'High School',
    'Some College',
    'Undergraduate Degree',
    'Graduate Degree',
    'PhD',
    'Trade School',
    'Prefer not to say',
  ];

  final List<String> _genderOptions = [
    'Woman',
    'Man',
    'Non-binary',
    'Prefer not to say',
  ];

  final List<String> _lookingForOptions = ['Women', 'Men', 'Everyone'];

  final List<String> _relationshipTypeOptions = [
    'Long-term partner',
    'Long-term, open to short',
    'Short-term, open to long',
    'Short-term fun',
    'New friends',
    'Still figuring it out',
  ];

  final List<String> _drinkingOptions = [
    'Not for me',
    'Sober',
    'Sober curious',
    'On special occasions',
    'Socially on weekends',
    'Most nights',
  ];

  final List<String> _smokingOptions = [
    'Non-smoker',
    'Smoker when drinking',
    'Social smoker',
    'Regular smoker',
    'Trying to quit',
  ];

  final List<String> _workoutOptions = [
    'Every day',
    'Often',
    'Sometimes',
    'Never',
  ];

  final List<String> _availableInterests = [
    'Photography',
    'Cooking',
    'Travel',
    'Music',
    'Movies',
    'Reading',
    'Fitness',
    'Yoga',
    'Dancing',
    'Art',
    'Gaming',
    'Sports',
    'Hiking',
    'Swimming',
    'Running',
    'Cycling',
    'Tennis',
    'Soccer',
    'Basketball',
    'Volleyball',
    'Climbing',
    'Skiing',
    'Surfing',
    'Fashion',
    'Shopping',
    'Beauty',
    'Technology',
    'Nature',
    'Animals',
    'Coffee',
    'Food',
    'Volunteering',
    'Writing',
    'Comedy',
  ];

  final List<String> _languageOptions = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Russian',
    'Hindi',
    'Dutch',
    'Swedish',
    'Norwegian',
    'Danish',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isFirstTime || widget.userProfile == null;
    _loadProfile();
    _calculateProfileCompletion();
  }

  @override
  void didUpdateWidget(EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh photos when widget updates (e.g., returning from another screen)
    _loadPhotosFromPhotoService();
  }

  void _loadProfile() {
    if (widget.userProfile != null) {
      final profile = widget.userProfile!;
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _bioController.text = profile.bio ?? '';
      _cityController.text = profile.city ?? '';
      _occupationController.text = profile.occupation ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _selectedDate = profile.dateOfBirth;
      _selectedEducation = profile.education;
      _interests = List.from(profile.interests);

      // Load extended fields
      _selectedGender = profile.gender;
      _selectedLookingFor = profile.preferences;
      _selectedRelationshipType = profile.relationshipGoals;
      _selectedDrinking = profile.drinking;
      _selectedSmoking = profile.smoking;
      _selectedWorkout = profile.workout;
      _languages = List.from(profile.languages);

      if (profile.photoUrls.isNotEmpty) {
        final initialSlots = List.generate(
          profile.photoUrls.length,
          (index) => _PhotoSlot(
            id: null,
            url: profile.photoUrls[index],
            displayOrder: index + 1,
            isPrimary: index == 0,
          ),
        );
        _updatePhotoState(initialSlots);
      }

      // Always load photos from PhotoService for grid display
      _loadPhotosFromPhotoService();
    }
  }

  void _calculateProfileCompletion() {
    setState(() {
      _profileCompletionPercentage =
          ProfileCompletionCalculator.calculateProfileCompletion(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        bio: _bioController.text,
        photoUrls: _photoUrls,
        interests: _interests,
        city: _cityController.text,
        occupation: _occupationController.text,
        education: _selectedEducation,
        gender: _selectedGender,
        lookingFor: _selectedLookingFor,
        relationshipType: _selectedRelationshipType,
        drinking: _selectedDrinking,
        smoking: _selectedSmoking,
        workout: _selectedWorkout,
        height: _heightController.text,
        languages: _languages,
      );
    });
  }

  Future<void> _loadPhotosFromPhotoService() async {
    try {
      final token = await _getAuthToken();
      final appStateUserId = session_api.AppState().userId;
      final fallbackUserId = widget.userProfile?.userId;
      final userId = int.tryParse(appStateUserId ?? fallbackUserId ?? '');

      if (token != null && userId != null) {
        final dotSegments = token.split('.').length;
        debugPrint(
          '🔄 Fetching photo summary for grid (token segments: $dotSegments, '
          'length: ${token.length})',
        );
        final summary = await _photoService.getUserPhotos(
          authToken: token,
          userId: userId,
        );

        if (!mounted) return;
        setState(() {
          _imageHeaders = {'Authorization': 'Bearer $token'};
          debugPrint('📥 Stored image headers: $_imageHeaders');

          if (summary != null && summary.photos.isNotEmpty) {
            debugPrint(
              '✅ PhotoService returned ${summary.photos.length} photos '
              '(primary: ${summary.hasPrimaryPhoto})',
            );
            final photos = List<PhotoResponse>.from(summary.photos);
            photos.sort((a, b) {
              if (a.isPrimary != b.isPrimary) {
                return a.isPrimary ? -1 : 1;
              }
              return a.displayOrder.compareTo(b.displayOrder);
            });

            final slots = photos
                .map(
                  (photo) => _PhotoSlot(
                    id: photo.id,
                    url: _preferredPhotoUrl(photo.urls),
                    displayOrder: photo.displayOrder,
                    isPrimary: photo.isPrimary,
                  ),
                )
                .toList();
            for (final slot in slots) {
              debugPrint(
                '   ↳ Photo ${slot.id} | order ${slot.displayOrder} | '
                'primary: ${slot.isPrimary} | url: ${slot.url}',
              );
            }
            _updatePhotoState(slots);
          } else {
            debugPrint('⚠️ PhotoService returned no photos, using fallback.');
            final profile = widget.userProfile;
            final fallbackSlots = (profile?.photoUrls ?? [])
                .asMap()
                .entries
                .map(
                  (entry) => _PhotoSlot(
                    id: null,
                    url: entry.value,
                    displayOrder: entry.key + 1,
                    isPrimary: entry.key == 0,
                  ),
                )
                .toList();
            _updatePhotoState(fallbackSlots);
          }
        });

        _calculateProfileCompletion();
      } else {
        debugPrint(
          '⚠️ Missing authentication details. Token present: ${token != null}, '
          'userId parsed: ${userId != null}',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to load photos from PhotoService: $e');
      // Fallback to UserService photos if available
      final profile = widget.userProfile;
      if (!mounted) return;
      setState(() {
        final fallbackSlots = (profile?.photoUrls ?? [])
            .asMap()
            .entries
            .map(
              (entry) => _PhotoSlot(
                id: null,
                url: entry.value,
                displayOrder: entry.key + 1,
                isPrimary: entry.key == 0,
              ),
            )
            .toList();
        _updatePhotoState(fallbackSlots);
      });
      _calculateProfileCompletion();
    }
  }

  String _preferredPhotoUrl(PhotoUrls urls) {
    final chosen = urls.full.isNotEmpty
        ? urls.full
        : (urls.medium.isNotEmpty ? urls.medium : urls.thumbnail);
    debugPrint(
      '🎯 Preferred URL selected -> full: ${urls.full.isNotEmpty}, '
      'medium: ${urls.medium.isNotEmpty}, thumbnail: ${urls.thumbnail.isNotEmpty}, '
      'chosen: $chosen',
    );
    return chosen;
  }

  void _updatePhotoState(List<_PhotoSlot> slots) {
    debugPrint('🧮 Updating photo state with ${slots.length} slots');
    slots.sort((a, b) {
      if (a.isPrimary != b.isPrimary) {
        return a.isPrimary ? -1 : 1;
      }
      return a.displayOrder.compareTo(b.displayOrder);
    });

    _photoSlots = List<_PhotoSlot>.generate(
      slots.length,
      (index) => slots[index].copyWith(displayOrder: index + 1),
    );

    if (_photoSlots.isNotEmpty && !_photoSlots.any((slot) => slot.isPrimary)) {
      _photoSlots = _photoSlots
          .asMap()
          .entries
          .map(
            (entry) => entry.value.copyWith(isPrimary: entry.key == 0),
          )
          .toList();
    }

    _photoUrls = _photoSlots.map((slot) => slot.url).toList();
    for (final slot in _photoSlots) {
      debugPrint(
        '   • Slot order ${slot.displayOrder} | primary: ${slot.isPrimary} | '
        'id: ${slot.id} | url: ${slot.url}',
      );
    }
    debugPrint('📊 Current photo URL list: $_photoUrls');
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _calculateProfileCompletion();
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_interests.contains(interest)) {
        _interests.remove(interest);
      } else if (_interests.length < 10) {
        _interests.add(interest);
      }
    });
    _calculateProfileCompletion();
  }

  void _toggleLanguage(String language) {
    setState(() {
      if (_languages.contains(language)) {
        _languages.remove(language);
      } else if (_languages.length < 5) {
        _languages.add(language);
      }
    });
    _calculateProfileCompletion();
  }

  Future<void> _pickImage(int index) async {
    debugPrint('🖱️ Pick image tapped for slot $index');
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (image != null) {
      debugPrint('📸 Picked image ${image.name} (path: ${image.path})');
      setState(() {
        _isLoading = true;
        _uploadingIndex = index;
        _errorMessage = null;
      });

      try {
        final token = await _getAuthToken();
        if (token == null) {
          throw Exception('Missing authentication token');
        }

        _imageHeaders = {'Authorization': 'Bearer $token'};
        debugPrint('🔑 Updated image headers for upload: $_imageHeaders');

        final result = await _photoService.uploadPhoto(
          imageFile: File(image.path),
          authToken: token,
          isPrimary: _photoSlots.isEmpty || index == 0,
          displayOrder: index + 1,
        );

        if (!result.success || result.photo == null) {
          throw Exception(result.errorMessage ?? 'Unknown upload error');
        }

        final uploadedPhoto = result.photo!;
        debugPrint(
          '✅ Upload succeeded -> id: ${uploadedPhoto.id}, '
          'displayOrder: ${uploadedPhoto.displayOrder}, '
          'isPrimary: ${uploadedPhoto.isPrimary}',
        );

        if (!mounted) return;
        setState(() {
          final updatedSlots = List<_PhotoSlot>.from(_photoSlots);
          final newSlot = _PhotoSlot(
            id: uploadedPhoto.id,
            url: _preferredPhotoUrl(uploadedPhoto.urls),
            displayOrder: uploadedPhoto.displayOrder,
            isPrimary: uploadedPhoto.isPrimary,
          );

          if (index < updatedSlots.length) {
            updatedSlots[index] = newSlot;
          } else {
            updatedSlots.add(newSlot);
          }

          _updatePhotoState(updatedSlots);
        });
        _calculateProfileCompletion();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.warnings.isNotEmpty
                    ? result.warnings.join('\n')
                    : 'Photo uploaded successfully!',
              ),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to upload photo: ${e.toString()}';
        });
        debugPrint('❌ Photo upload failed: $e');
      } finally {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _uploadingIndex = null;
        });
        _loadPhotosFromPhotoService();
      }
    }
  }

  Future<void> _removePhoto(int index) async {
    if (index >= _photoSlots.length) {
      return;
    }

    final slot = _photoSlots[index];
    debugPrint(
        '🗑️ Removing photo at index $index -> id: ${slot.id}, url: ${slot.url}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Missing authentication token');
      }

      _imageHeaders = {'Authorization': 'Bearer $token'};

      bool success = true;
      if (slot.id != null) {
        success = await _photoService.deletePhoto(
          photoId: slot.id!,
          authToken: token,
        );
        debugPrint(
            '🧾 Delete request sent to PhotoService -> success: $success');
      } else {
        await userApi.deletePhoto(slot.url);
        debugPrint(
            '🧾 Delete request sent to legacy UserService for URL ${slot.url}');
      }

      if (!success) {
        throw Exception('Photo service rejected the delete request');
      }

      if (!mounted) return;
      setState(() {
        final updatedSlots = List<_PhotoSlot>.from(_photoSlots)
          ..removeAt(index);
        _updatePhotoState(updatedSlots);
      });
      _calculateProfileCompletion();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted successfully!')),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to delete photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: ${e.toString()}')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Please select your birth date';
      });
      return;
    }

    if (_photoUrls.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one photo';
      });
      return;
    }

    if (_interests.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one interest';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = UserProfile(
        id: widget.userProfile?.id,
        userId: widget.userProfile?.userId ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _selectedDate!,
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        occupation: _occupationController.text.trim(),
        interests: _interests,
        height: int.tryParse(_heightController.text.trim()),
        education: _selectedEducation,
        photoUrls: _photoUrls,
        primaryPhotoUrl: _photoUrls.isNotEmpty ? _photoUrls.first : null,
        relationshipGoals: _selectedRelationshipType,
        preferences: _selectedLookingFor,
        gender: _selectedGender,
        drinking: _selectedDrinking,
        smoking: _selectedSmoking,
        workout: _selectedWorkout,
        languages: _languages,
      );

      if (widget.userProfile == null) {
        await userApi.createProfile(profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile created successfully!')),
          );
          if (widget.isFirstTime) {
            Navigator.of(context).pop();
          }
        }
      } else {
        await userApi.updateProfile(profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      }

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing && widget.userProfile != null) {
      return _buildDisplayMode();
    } else {
      return _buildEditMode();
    }
  }

  Widget _buildDisplayMode() {
    final profile = widget.userProfile!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildPhotoGrid(false),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_profileCompletionPercentage < 100) ...[
                    _buildProfileCompletionCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildProfileInfo(profile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFirstTime ? 'Create Your Profile' : 'Edit Profile',
        ),
        // Uses theme AppBar defaults
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCompletionCard(),
              const SizedBox(height: 24),
              _buildPhotosSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildAboutSection(),
              const SizedBox(height: 24),
              _buildLifestyleSection(),
              const SizedBox(height: 24),
              _buildInterestsSection(),
              const SizedBox(height: 24),
              _buildLanguagesSection(),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                _buildErrorCard(),
                const SizedBox(height: 16),
              ],
              _buildManagePhotosButton(),
              const SizedBox(height: 16),
              _buildSaveButton(),
              if (!widget.isFirstTime && widget.userProfile != null) ...[
                const SizedBox(height: 12),
                _buildCancelButton(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    Color progressColor = ProfileCompletionCalculator.getCompletionColor(
      _profileCompletionPercentage,
    );
    String message = ProfileCompletionCalculator.getProfileCompletionMessage(
      _profileCompletionPercentage,
    );
    String matchBonus = ProfileCompletionCalculator.getMatchQualityBonus(
      _profileCompletionPercentage,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surfaceElevated, AppTheme.surfaceColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Profile Strength: $_profileCompletionPercentage%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _profileCompletionPercentage / 100,
            backgroundColor: AppTheme.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            matchBonus,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${_photoSlots.length}/9',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Add at least 2 photos. First photo will be your main photo.',
        ),
        const SizedBox(height: 16),
        _buildPhotoGrid(true),
      ],
    );
  }

  Widget _buildPhotoGrid(bool isEditing) {
    final photos = _photoSlots;
    debugPrint(
      '🧩 Building photo grid (editing: $isEditing, slots: ${photos.length}, '
      'itemCount: ${isEditing ? 9 : photos.length})',
    );
    for (var i = 0; i < photos.length; i++) {
      final slot = photos[i];
      debugPrint(
        '   [grid] index $i -> order ${slot.displayOrder}, '
        'primary: ${slot.isPrimary}, url: ${slot.url}',
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: isEditing ? 9 : photos.length,
      itemBuilder: (context, index) {
        if (index < photos.length) {
          final slot = photos[index];
          return PhotoGridCard(
            photoUrl: slot.url,
            isMainPhoto: slot.isPrimary || index == 0,
            isEditing: isEditing,
            onDelete: isEditing ? () => _removePhoto(index) : null,
            onTap: isEditing ? () => _pickImage(index) : null,
            imageHeaders: _imageHeaders,
          );
        } else if (isEditing) {
          return PhotoGridCard(
            isEditing: true,
            onTap: () => _pickImage(index),
            isLoading: _isLoading && _uploadingIndex == index,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      icon: Icons.person,
      title: 'Basic Information',
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
                onChanged: (_) => _calculateProfileCompletion(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
                onChanged: (_) => _calculateProfileCompletion(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDateSelector(),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedGender,
          label: 'I am *',
          options: _genderOptions,
          onChanged: (value) {
            setState(() => _selectedGender = value);
            _calculateProfileCompletion();
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedLookingFor,
          label: 'Show me *',
          options: _lookingForOptions,
          onChanged: (value) {
            setState(() => _selectedLookingFor = value);
            _calculateProfileCompletion();
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      icon: Icons.edit_note,
      title: 'About Me',
      children: [
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio (50+ characters recommended)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            helperText:
                'Tell people about yourself, your interests, what makes you unique!',
          ),
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => _calculateProfileCompletion(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculateProfileCompletion(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateProfileCompletion(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _occupationController,
          decoration: const InputDecoration(
            labelText: 'Job Title',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _calculateProfileCompletion(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _schoolController,
          decoration: const InputDecoration(
            labelText: 'School',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _calculateProfileCompletion(),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedEducation,
          label: 'Education',
          options: _educationOptions,
          onChanged: (value) {
            setState(() => _selectedEducation = value);
            _calculateProfileCompletion();
          },
        ),
      ],
    );
  }

  Widget _buildLifestyleSection() {
    return _buildSection(
      icon: Icons.favorite_border,
      title: 'Lifestyle',
      children: [
        _buildDropdown(
          value: _selectedRelationshipType,
          label: 'Looking for',
          options: _relationshipTypeOptions,
          onChanged: (value) {
            setState(() => _selectedRelationshipType = value);
            _calculateProfileCompletion();
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedDrinking,
          label: 'Drinking',
          options: _drinkingOptions,
          onChanged: (value) {
            setState(() => _selectedDrinking = value);
            _calculateProfileCompletion();
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedSmoking,
          label: 'Smoking',
          options: _smokingOptions,
          onChanged: (value) {
            setState(() => _selectedSmoking = value);
            _calculateProfileCompletion();
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedWorkout,
          label: 'Workout',
          options: _workoutOptions,
          onChanged: (value) {
            setState(() => _selectedWorkout = value);
            _calculateProfileCompletion();
          },
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return _buildSection(
      icon: Icons.favorite,
      title: 'Interests (${_interests.length}/10)',
      subtitle: 'Choose interests to show on your profile',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableInterests.map((interest) {
            final isSelected = _interests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) => _toggleInterest(interest),
              selectedColor: AppTheme.primarySubtle,
              checkmarkColor: AppTheme.primaryDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return _buildSection(
      icon: Icons.language,
      title: 'Languages (${_languages.length}/5)',
      subtitle: 'Select languages you speak',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languageOptions.map((language) {
            final isSelected = _languages.contains(language);
            return FilterChip(
              label: Text(language),
              selected: isSelected,
              onSelected: (selected) => _toggleLanguage(language),
              selectedColor: AppTheme.infoColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.infoColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle)],
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'Select Birth Date *',
              style: TextStyle(
                color: _selectedDate != null ? AppTheme.textPrimary : AppTheme.textTertiary,
              ),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(value: option, child: Text(option)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.isFirstTime ? 'Create Profile' : 'Save Changes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildManagePhotosButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Navigate to photos and refresh when returning
          await Navigator.pushNamed(context, '/photos');
          // Reload photos from PhotoService when returning from photo upload
          _loadPhotosFromPhotoService();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.photo_library),
        label: const Text(
          'Manage Photos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          setState(() {
            _isEditing = false;
            _loadProfile();
          });
        },
        child: const Text('Cancel'),
      ),
    );
  }

  Widget _buildProfileInfo(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${profile.firstName} ${profile.lastName}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(
          '${profile.age} years old',
          style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        if (profile.bio?.isNotEmpty == true) ...[
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(profile.bio!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
        ],
        if (profile.interests.isNotEmpty) ...[
          const Text(
            'Interests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.interests
                .map(
                  (interest) => Chip(
                    label: Text(interest),
                    backgroundColor: AppTheme.primarySubtle,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        _buildProfileDetails(profile),
      ],
    );
  }

  Widget _buildProfileDetails(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (profile.occupation?.isNotEmpty == true)
          _buildDetailRow(Icons.work, 'Job', profile.occupation!),
        if (profile.education?.isNotEmpty == true)
          _buildDetailRow(Icons.school, 'Education', profile.education!),
        if (profile.height != null)
          _buildDetailRow(Icons.height, 'Height', '${profile.height} cm'),
        if (profile.city?.isNotEmpty == true)
          _buildDetailRow(Icons.location_on, 'Lives in', profile.city!),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textTertiary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _occupationController.dispose();
    _heightController.dispose();
    _schoolController.dispose();
    super.dispose();
  }
}

class _PhotoSlot {
  final int? id;
  final String url;
  final int displayOrder;
  final bool isPrimary;

  const _PhotoSlot({
    this.id,
    required this.url,
    required this.displayOrder,
    required this.isPrimary,
  });

  _PhotoSlot copyWith({
    int? id,
    String? url,
    int? displayOrder,
    bool? isPrimary,
  }) {
    return _PhotoSlot(
      id: id ?? this.id,
      url: url ?? this.url,
      displayOrder: displayOrder ?? this.displayOrder,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
