import 'package:flutter/material.dart';
import '../../widgets/dev_mode_banner.dart';
import '../../providers/onboarding_provider.dart';

/// Photos Screen - Final onboarding step
/// Grid of photo upload placeholders (Tinder-style 2x3 grid)
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  // Track which slots have "photos" (indices 0-5)
  final List<bool> _photoSlots = List.filled(6, false);

  int get _photoCount => _photoSlots.where((s) => s).length;
  bool get _isValid => _photoCount >= 2; // Require at least 2 photos

  void _addPhoto(int index) {
    // TODO: Integrate with photo-service for real uploads
    setState(() => _photoSlots[index] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo ${index + 1} added (placeholder)'),
        backgroundColor: const Color(0xFFFF6B6B),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() => _photoSlots[index] = false);
  }

  void _finish() {
    // Navigate to home, clearing the entire onboarding stack
    

    OnboardingProvider.of(context).goNext(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => OnboardingProvider.of(context).abort(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: OnboardingProvider.of(context).progress(context),
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B6B)),
                  minHeight: 4,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add photos",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add at least 2 photos to continue. Your first photo is your profile photo.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // 2x3 photo grid
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: 6,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final hasPhoto = _photoSlots[index];
                            return GestureDetector(
                              onTap: () => hasPhoto ? _removePhoto(index) : _addPhoto(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: hasPhoto ? Colors.grey[300] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: hasPhoto ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
                                    width: hasPhoto ? 2 : 1,
                                  ),
                                ),
                                child: hasPhoto
                                    ? Stack(
                                        children: [
                                          // Placeholder "photo"
                                          Center(
                                            child: Icon(
                                              Icons.person,
                                              size: 48,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          // Remove button
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF6B6B),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                                            ),
                                          ),
                                          // Slot number
                                          if (index == 0)
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF6B6B),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'Main',
                                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                        ],
                                      )
                                    : Center(
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B6B),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(25),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        '$_photoCount/6 photos · ${_isValid ? "Ready!" : "Add ${2 - _photoCount} more"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isValid ? const Color(0xFF00C878) : Colors.grey[600],
                          fontWeight: _isValid ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isValid ? _finish : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isValid ? const Color(0xFFFF6B6B) : Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                          ),
                          child: const Text("Continue", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          DevModeSkipButton(
            onSkip: () {  OnboardingProvider.of(context).goNext(context); },
            label: 'Skip Photos',
          ),
        ],
      ),
    );
  }
}
