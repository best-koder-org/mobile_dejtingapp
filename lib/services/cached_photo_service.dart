import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'photo_service.dart';

/// Smart photo caching service that implements Tinder-like behavior:
/// 1. Show photos immediately from local files during upload
/// 2. Cache server photos locally after first download
/// 3. Show cached photos for better performance
/// 4. Handle cross-device sync intelligently
class CachedPhotoService {
  final PhotoService _photoService = PhotoService();
  late Directory _cacheDir;
  bool _initialized = false;

  /// Cache metadata for tracking photo state
  final Map<String, PhotoCacheMetadata> _cacheMetadata = {};

  Future<void> initialize() async {
    if (_initialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'photo_cache'));

    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }

    await _loadCacheMetadata();
    _initialized = true;

    debugPrint('📸 CachedPhotoService initialized: ${_cacheDir.path}');
  }

  /// Upload photo with immediate local caching
  Future<CachedPhotoUploadResult> uploadPhotoWithCache({
    required File imageFile,
    required String authToken,
    bool isPrimary = false,
    int? displayOrder,
    String? description,
  }) async {
    await initialize();

    // 1. Immediately cache the local file for instant display
    final localCacheKey =
        _generateCacheKey('local_${path.basename(imageFile.path)}');
    final localCachePath = path.join(_cacheDir.path, '$localCacheKey.jpg');

    // Copy to cache for immediate display
    await imageFile.copy(localCachePath);
    final localImageBytes = await imageFile.readAsBytes();

    debugPrint('📱 Local photo cached for immediate display: $localCachePath');

    try {
      // 2. Upload to server in background
      debugPrint('⬆️ Starting background upload...');
      final uploadResult = await _photoService.uploadPhoto(
        imageFile: imageFile,
        authToken: authToken,
        isPrimary: isPrimary,
        displayOrder: displayOrder,
        description: description,
      );

      if (uploadResult.success && uploadResult.photo != null) {
        // 3. Cache server photo metadata
        final serverCacheKey =
            _generateCacheKey('server_${uploadResult.photo!.id}');
        await _saveCacheMetadata(
            serverCacheKey,
            PhotoCacheMetadata(
              photoId: uploadResult.photo!.id,
              userId: uploadResult.photo!.userId,
              localPath: localCachePath,
              serverUrls: uploadResult.photo!.urls,
              cachedAt: DateTime.now(),
              isUserOwned: true,
              originalFileName: uploadResult.photo!.originalFileName,
            ));

        debugPrint('✅ Photo uploaded & cached: ID ${uploadResult.photo!.id}');

        return CachedPhotoUploadResult(
          success: true,
          localImageBytes: localImageBytes,
          localCachePath: localCachePath,
          uploadResult: uploadResult,
          photo: uploadResult.photo,
        );
      } else {
        // Upload failed, but we still have local image
        debugPrint('⚠️ Upload failed, but local image available');
        return CachedPhotoUploadResult(
          success: false,
          localImageBytes: localImageBytes,
          localCachePath: localCachePath,
          uploadResult: uploadResult,
          errorMessage: uploadResult.errorMessage,
        );
      }
    } catch (e) {
      debugPrint('❌ Upload error, but local image available: $e');
      return CachedPhotoUploadResult(
        success: false,
        localImageBytes: localImageBytes,
        localCachePath: localCachePath,
        errorMessage: 'Upload failed: $e',
      );
    }
  }

  /// Get user photos with smart caching
  Future<CachedUserPhotos?> getUserPhotosWithCache({
    required String authToken,
    required int userId,
    bool forceRefresh = false,
  }) async {
    await initialize();

    try {
      // First, get server data
      final serverPhotos = await _photoService.getUserPhotos(
        authToken: authToken,
        userId: userId,
      );

      if (serverPhotos == null) {
        debugPrint('❌ Failed to get user photos from server');
        return null;
      }

      // Build cached photo list
      final List<CachedPhoto> cachedPhotos = [];

      for (final photo in serverPhotos.photos) {
        final cacheKey = _generateCacheKey('server_${photo.id}');
        final metadata = _cacheMetadata[cacheKey];

        Uint8List? imageBytes;
        String? localPath;

        // Check if we have local cache
        if (metadata?.localPath != null &&
            await File(metadata!.localPath).exists()) {
          imageBytes = await File(metadata.localPath).readAsBytes();
          localPath = metadata.localPath;
          debugPrint('📱 Using cached image for photo ${photo.id}');
        } else {
          // Download and cache
          imageBytes = await _downloadAndCachePhoto(photo, authToken);
          if (imageBytes != null) {
            localPath = await _getCachePathForPhoto(photo.id);
            debugPrint('⬇️ Downloaded & cached photo ${photo.id}');
          }
        }

        cachedPhotos.add(CachedPhoto(
          photoResponse: photo,
          localImageBytes: imageBytes,
          localPath: localPath,
          isFromCache: metadata != null,
        ));
      }

      return CachedUserPhotos(
        userId: serverPhotos.userId,
        totalPhotos: serverPhotos.totalPhotos,
        photos: cachedPhotos,
        hasReachedPhotoLimit: serverPhotos.hasReachedPhotoLimit,
      );
    } catch (e) {
      debugPrint('❌ Error getting cached user photos: $e');
      return null;
    }
  }

  /// Download photo and cache locally
  Future<Uint8List?> _downloadAndCachePhoto(
      PhotoResponse photo, String authToken) async {
    try {
      // Use medium size for better performance
      final response = await _photoService.getPhotoBytes(
        photoUrl:
            photo.urls.medium.isNotEmpty ? photo.urls.medium : photo.urls.full,
        authToken: authToken,
      );

      if (response != null) {
        // Cache the downloaded image
        final cacheKey = _generateCacheKey('server_${photo.id}');
        final cachePath = path.join(_cacheDir.path, '$cacheKey.jpg');
        await File(cachePath).writeAsBytes(response);

        // Save metadata
        await _saveCacheMetadata(
            cacheKey,
            PhotoCacheMetadata(
              photoId: photo.id,
              userId: photo.userId,
              localPath: cachePath,
              serverUrls: photo.urls,
              cachedAt: DateTime.now(),
              isUserOwned: false, // Assume other user's photo
              originalFileName: photo.originalFileName,
            ));

        return response;
      }
    } catch (e) {
      debugPrint('❌ Failed to download photo ${photo.id}: $e');
    }
    return null;
  }

  /// Clear old cache entries
  Future<void> clearOldCache(
      {Duration maxAge = const Duration(days: 7)}) async {
    await initialize();

    final cutoffTime = DateTime.now().subtract(maxAge);
    final keysToRemove = <String>[];

    for (final entry in _cacheMetadata.entries) {
      if (entry.value.cachedAt.isBefore(cutoffTime) &&
          !entry.value.isUserOwned) {
        // Don't clear user's own photos, only others
        keysToRemove.add(entry.key);

        // Delete file
        final file = File(entry.value.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    // Remove from metadata
    for (final key in keysToRemove) {
      _cacheMetadata.remove(key);
    }

    await _saveCacheMetadataToFile();
    debugPrint('🧹 Cleared ${keysToRemove.length} old cache entries');
  }

  /// Generate cache key from content
  String _generateCacheKey(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  Future<String> _getCachePathForPhoto(int photoId) async {
    final cacheKey = _generateCacheKey('server_$photoId');
    return path.join(_cacheDir.path, '$cacheKey.jpg');
  }

  /// Load cache metadata from storage
  Future<void> _loadCacheMetadata() async {
    try {
      final metadataFile =
          File(path.join(_cacheDir.path, 'cache_metadata.json'));
      if (await metadataFile.exists()) {
        final json = await metadataFile.readAsString();
        final Map<String, dynamic> data = jsonDecode(json);

        for (final entry in data.entries) {
          _cacheMetadata[entry.key] = PhotoCacheMetadata.fromJson(entry.value);
        }

        debugPrint('📋 Loaded ${_cacheMetadata.length} cache metadata entries');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load cache metadata: $e');
    }
  }

  /// Save cache metadata entry
  Future<void> _saveCacheMetadata(
      String key, PhotoCacheMetadata metadata) async {
    _cacheMetadata[key] = metadata;
    await _saveCacheMetadataToFile();
  }

  /// Save all cache metadata to file
  Future<void> _saveCacheMetadataToFile() async {
    try {
      final metadataFile =
          File(path.join(_cacheDir.path, 'cache_metadata.json'));
      final Map<String, dynamic> data = {};

      for (final entry in _cacheMetadata.entries) {
        data[entry.key] = entry.value.toJson();
      }

      await metadataFile.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('❌ Failed to save cache metadata: $e');
    }
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    await initialize();

    int totalFiles = 0;
    int totalSizeBytes = 0;
    int userOwnedCount = 0;
    int othersPhotosCount = 0;

    for (final metadata in _cacheMetadata.values) {
      final file = File(metadata.localPath);
      if (await file.exists()) {
        totalFiles++;
        totalSizeBytes += await file.length();

        if (metadata.isUserOwned) {
          userOwnedCount++;
        } else {
          othersPhotosCount++;
        }
      }
    }

    return CacheStats(
      totalFiles: totalFiles,
      totalSizeBytes: totalSizeBytes,
      userOwnedPhotos: userOwnedCount,
      othersPhotos: othersPhotosCount,
      cacheDirectory: _cacheDir.path,
    );
  }
}

/// Add to PhotoService to get image bytes
extension PhotoServiceImageBytes on PhotoService {
  Future<Uint8List?> getPhotoBytes({
    required String photoUrl,
    required String authToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(photoUrl),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('❌ Failed to get photo bytes: $e');
    }
    return null;
  }
}

// Data classes

class CachedPhotoUploadResult {
  final bool success;
  final Uint8List? localImageBytes;
  final String? localCachePath;
  final PhotoUploadResult? uploadResult;
  final PhotoResponse? photo;
  final String? errorMessage;

  CachedPhotoUploadResult({
    required this.success,
    this.localImageBytes,
    this.localCachePath,
    this.uploadResult,
    this.photo,
    this.errorMessage,
  });
}

class CachedUserPhotos {
  final int userId;
  final int totalPhotos;
  final List<CachedPhoto> photos;
  final bool hasReachedPhotoLimit;

  CachedUserPhotos({
    required this.userId,
    required this.totalPhotos,
    required this.photos,
    required this.hasReachedPhotoLimit,
  });
}

class CachedPhoto {
  final PhotoResponse photoResponse;
  final Uint8List? localImageBytes;
  final String? localPath;
  final bool isFromCache;

  CachedPhoto({
    required this.photoResponse,
    this.localImageBytes,
    this.localPath,
    required this.isFromCache,
  });
}

class PhotoCacheMetadata {
  final int photoId;
  final int userId;
  final String localPath;
  final PhotoUrls serverUrls;
  final DateTime cachedAt;
  final bool isUserOwned;
  final String originalFileName;

  PhotoCacheMetadata({
    required this.photoId,
    required this.userId,
    required this.localPath,
    required this.serverUrls,
    required this.cachedAt,
    required this.isUserOwned,
    required this.originalFileName,
  });

  Map<String, dynamic> toJson() => {
        'photoId': photoId,
        'userId': userId,
        'localPath': localPath,
        'serverUrls': serverUrls.toJson(),
        'cachedAt': cachedAt.toIso8601String(),
        'isUserOwned': isUserOwned,
        'originalFileName': originalFileName,
      };

  factory PhotoCacheMetadata.fromJson(Map<String, dynamic> json) =>
      PhotoCacheMetadata(
        photoId: json['photoId'],
        userId: json['userId'],
        localPath: json['localPath'],
        serverUrls: PhotoUrls.fromJson(json['serverUrls']),
        cachedAt: DateTime.parse(json['cachedAt']),
        isUserOwned: json['isUserOwned'] ?? false,
        originalFileName: json['originalFileName'] ?? '',
      );
}

class CacheStats {
  final int totalFiles;
  final int totalSizeBytes;
  final int userOwnedPhotos;
  final int othersPhotos;
  final String cacheDirectory;

  CacheStats({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.userOwnedPhotos,
    required this.othersPhotos,
    required this.cacheDirectory,
  });

  String get formattedSize {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = totalSizeBytes.toDouble();
    int suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }
}
