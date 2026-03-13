import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../config/environment.dart';

/// PhotoService API client that matches the C# PhotoService DTOs
class PhotoService {
  String get baseUrl => EnvironmentConfig.settings.photoServiceUrl;

  /// Upload a photo using PhotoUploadDto
  Future<PhotoUploadResult> uploadPhoto({
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    required String authToken,
    Object? userId, // backwards compatibility, ignored by the API
    bool isPrimary = false,
    int? displayOrder,
    String? description,
  }) async {
    try {
      if (imageFile == null && imageBytes == null) {
        return PhotoUploadResult(
          success: false,
          errorMessage: 'No image data provided',
        );
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/photos'),
      );

      // Add JWT token
      request.headers['Authorization'] = 'Bearer $authToken';

      http.MultipartFile photoPart;
      String resolvedFileName;

      if (imageFile != null) {
        // Add photo file - matches PhotoUploadDto.Photo property
        resolvedFileName = fileName ?? path.basename(imageFile.path);
        String? mimeType = lookupMimeType(imageFile.path);
        photoPart = await http.MultipartFile.fromPath(
          'Photo', // Must match PhotoUploadDto property name
          imageFile.path,
          filename: resolvedFileName,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
      } else {
        resolvedFileName = fileName ?? 'upload.jpg';
        String? mimeType = lookupMimeType(resolvedFileName);
        photoPart = http.MultipartFile.fromBytes(
          'Photo',
          imageBytes!,
          filename: resolvedFileName,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
      }

      request.files.add(photoPart);

      // Add metadata fields to match PhotoUploadDto
      request.fields['IsPrimary'] = isPrimary.toString();
      if (displayOrder != null) {
        request.fields['DisplayOrder'] = displayOrder.toString();
      }
      if (description != null && description.isNotEmpty) {
        request.fields['Description'] = description;
      }

      debugPrint('📤 Uploading photo: $resolvedFileName');
      if (imageFile != null) {
        debugPrint('📤 File size: ${await imageFile.length()} bytes');
      } else if (imageBytes != null) {
        debugPrint('📤 File size: ${imageBytes.lengthInBytes} bytes');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('📥 Upload response: ${response.statusCode}');
      debugPrint('📥 Response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(responseBody);
        return PhotoUploadResult.fromJson(jsonData);
      } else {
        return PhotoUploadResult(
          success: false,
          errorMessage: 'Upload failed: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      debugPrint('❌ Photo upload error: $e');
      return PhotoUploadResult(
        success: false,
        errorMessage: 'Upload failed: $e',
      );
    }
  }

  /// Get user's photos using UserPhotoSummaryDto endpoint
  Future<UserPhotoSummary?> getUserPhotos({
    required String authToken,
    Object? userId, // backwards compatibility, ignored by the API
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/photos'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserPhotoSummary.fromJson(jsonData);
      } else {
        debugPrint('❌ Failed to get user photos: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting user photos: $e');
      return null;
    }
  }

  /// Delete a photo
  Future<bool> deletePhoto({
    required int photoId,
    required String authToken,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/photos/$photoId'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('❌ Error deleting photo: $e');
      return false;
    }
  }

  /// Update photo metadata using PhotoUpdateDto
  Future<PhotoResponse?> updatePhoto({
    required int photoId,
    required String authToken,
    int? displayOrder,
    bool? isPrimary,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (displayOrder != null) updateData['DisplayOrder'] = displayOrder;
      if (isPrimary != null) updateData['IsPrimary'] = isPrimary;

      final response = await http.put(
        Uri.parse('$baseUrl/api/photos/$photoId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PhotoResponse.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error updating photo: $e');
      return null;
    }
  }

  /// Reorder photos using PhotoReorderDto
  Future<bool> reorderPhotos({
    required String authToken,
    required List<PhotoOrderItem> photos,
  }) async {
    try {
      final reorderData = {
        'Photos': photos.map((photo) => photo.toJson()).toList(),
      };

      final response = await http.put(
        Uri.parse('$baseUrl/api/photos/reorder'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(reorderData),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error reordering photos: $e');
      return false;
    }
  }

  /// Check PhotoService health
  Future<bool> isServiceHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ PhotoService health check failed: $e');
      return false;
    }
  }
}

// DTOs matching C# PhotoDTOs exactly

/// Matches PhotoUploadResultDto from C#
class PhotoUploadResult {
  final bool success;
  final String? errorMessage;
  final List<String> warnings;
  final PhotoResponse? photo;
  final PhotoProcessingInfo? processingInfo;

  PhotoUploadResult({
    required this.success,
    this.errorMessage,
    this.warnings = const [],
    this.photo,
    this.processingInfo,
  });

  factory PhotoUploadResult.fromJson(Map<String, dynamic> json) {
    return PhotoUploadResult(
      success: json['success'] ?? false,
      errorMessage: json['errorMessage'],
      warnings: List<String>.from(json['warnings'] ?? []),
      photo:
          json['photo'] != null ? PhotoResponse.fromJson(json['photo']) : null,
      processingInfo: json['processingInfo'] != null
          ? PhotoProcessingInfo.fromJson(json['processingInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'errorMessage': errorMessage,
      'warnings': warnings,
      'photo': photo?.toJson(),
      'processingInfo': processingInfo?.toJson(),
    };
  }
}

/// Matches PhotoResponseDto from C#
class PhotoResponse {
  final int id;
  final int userId;
  final String originalFileName;
  final int displayOrder;
  final bool isPrimary;
  final DateTime createdAt;
  final int width;
  final int height;
  final int fileSizeBytes;
  final String moderationStatus;
  final int qualityScore;
  final PhotoUrls urls;

  PhotoResponse({
    required this.id,
    required this.userId,
    required this.originalFileName,
    required this.displayOrder,
    required this.isPrimary,
    required this.createdAt,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.moderationStatus,
    required this.qualityScore,
    required this.urls,
  });

  factory PhotoResponse.fromJson(Map<String, dynamic> json) {
    return PhotoResponse(
      id: json['id'],
      userId: json['userId'],
      originalFileName: json['originalFileName'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
      isPrimary: json['isPrimary'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      fileSizeBytes: json['fileSizeBytes'] ?? 0,
      moderationStatus: json['moderationStatus'] ?? '',
      qualityScore: json['qualityScore'] ?? 0,
      urls: PhotoUrls.fromJson(json['urls'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'originalFileName': originalFileName,
      'displayOrder': displayOrder,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
      'width': width,
      'height': height,
      'fileSizeBytes': fileSizeBytes,
      'moderationStatus': moderationStatus,
      'qualityScore': qualityScore,
      'urls': urls.toJson(),
    };
  }

  String get fileSizeFormatted {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = fileSizeBytes.toDouble();
    int suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }
}

/// Matches PhotoUrlsDto from C#
class PhotoUrls {
  final String full;
  final String medium;
  final String thumbnail;

  PhotoUrls({
    required this.full,
    required this.medium,
    required this.thumbnail,
  });

  factory PhotoUrls.fromJson(Map<String, dynamic> json) {
    return PhotoUrls(
      full: json['full'] ?? '',
      medium: json['medium'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full': full,
      'medium': medium,
      'thumbnail': thumbnail,
    };
  }
}

/// Matches PhotoProcessingInfoDto from C#
class PhotoProcessingInfo {
  final bool wasResized;
  final int originalWidth;
  final int originalHeight;
  final int finalWidth;
  final int finalHeight;
  final bool formatConverted;
  final String originalFormat;
  final String finalFormat;
  final int processingTimeMs;

  PhotoProcessingInfo({
    required this.wasResized,
    required this.originalWidth,
    required this.originalHeight,
    required this.finalWidth,
    required this.finalHeight,
    required this.formatConverted,
    required this.originalFormat,
    required this.finalFormat,
    required this.processingTimeMs,
  });

  factory PhotoProcessingInfo.fromJson(Map<String, dynamic> json) {
    return PhotoProcessingInfo(
      wasResized: json['wasResized'] ?? false,
      originalWidth: json['originalWidth'] ?? 0,
      originalHeight: json['originalHeight'] ?? 0,
      finalWidth: json['finalWidth'] ?? 0,
      finalHeight: json['finalHeight'] ?? 0,
      formatConverted: json['formatConverted'] ?? false,
      originalFormat: json['originalFormat'] ?? '',
      finalFormat: json['finalFormat'] ?? '',
      processingTimeMs: json['processingTimeMs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wasResized': wasResized,
      'originalWidth': originalWidth,
      'originalHeight': originalHeight,
      'finalWidth': finalWidth,
      'finalHeight': finalHeight,
      'formatConverted': formatConverted,
      'originalFormat': originalFormat,
      'finalFormat': finalFormat,
      'processingTimeMs': processingTimeMs,
    };
  }
}

/// Matches UserPhotoSummaryDto from C#
class UserPhotoSummary {
  final int userId;
  final int totalPhotos;
  final bool hasPrimaryPhoto;
  final PhotoResponse? primaryPhoto;
  final List<PhotoResponse> photos;
  final int totalStorageBytes;
  final int remainingPhotoSlots;
  final bool hasReachedPhotoLimit;

  UserPhotoSummary({
    required this.userId,
    required this.totalPhotos,
    required this.hasPrimaryPhoto,
    this.primaryPhoto,
    required this.photos,
    required this.totalStorageBytes,
    required this.remainingPhotoSlots,
    required this.hasReachedPhotoLimit,
  });

  factory UserPhotoSummary.fromJson(Map<String, dynamic> json) {
    return UserPhotoSummary(
      userId: json['userId'] ?? 0,
      totalPhotos: json['totalPhotos'] ?? 0,
      hasPrimaryPhoto: json['hasPrimaryPhoto'] ?? false,
      primaryPhoto: json['primaryPhoto'] != null
          ? PhotoResponse.fromJson(json['primaryPhoto'])
          : null,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((photo) => PhotoResponse.fromJson(photo))
              .toList() ??
          [],
      totalStorageBytes: json['totalStorageBytes'] ?? 0,
      remainingPhotoSlots: json['remainingPhotoSlots'] ?? 6,
      hasReachedPhotoLimit: json['hasReachedPhotoLimit'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalPhotos': totalPhotos,
      'hasPrimaryPhoto': hasPrimaryPhoto,
      'primaryPhoto': primaryPhoto?.toJson(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'totalStorageBytes': totalStorageBytes,
      'remainingPhotoSlots': remainingPhotoSlots,
      'hasReachedPhotoLimit': hasReachedPhotoLimit,
    };
  }

  String get totalStorageFormatted {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = totalStorageBytes.toDouble();
    int suffixIndex = 0;

    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }
}

/// Matches PhotoOrderItemDto from C# for bulk reordering
class PhotoOrderItem {
  final int photoId;
  final int displayOrder;

  PhotoOrderItem({
    required this.photoId,
    required this.displayOrder,
  });

  factory PhotoOrderItem.fromJson(Map<String, dynamic> json) {
    return PhotoOrderItem(
      photoId: json['photoId'],
      displayOrder: json['displayOrder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PhotoId': photoId, // C# expects PascalCase
      'DisplayOrder': displayOrder,
    };
  }
}
