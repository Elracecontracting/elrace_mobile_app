import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../../domain/entities/face_embedding.dart';

/// Secure storage service for face embeddings
///
/// Uses flutter_secure_storage for encrypted storage
/// All data is encrypted at rest on the device
///
/// Security features:
/// - AES encryption (handled by secure storage)
/// - Isolated storage per app
/// - Keychain (iOS) / KeyStore (Android) backed
class FaceEmbeddingStorageService {
  final FlutterSecureStorage _secureStorage;
  static const String _keyPrefix = 'face_embedding_';

  FaceEmbeddingStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Save a face embedding for a user
  ///
  /// Parameters:
  /// - embedding: The face embedding to store
  ///
  /// Storage format:
  /// Key: face_embedding_{userId}_{label}
  /// Value: JSON string with embedding data
  Future<void> saveEmbedding(FaceEmbedding embedding) async {
    try {
      final key = _buildKey(embedding.userId, embedding.label);
      final jsonString = jsonEncode(embedding.toJson());

      await _secureStorage.write(key: key, value: jsonString);
    } catch (e) {
      throw StorageException('Failed to save embedding: $e');
    }
  }

  /// Save multiple embeddings for a user (batch operation)
  ///
  /// Useful for storing multiple angles/conditions during registration
  Future<void> saveEmbeddings(List<FaceEmbedding> embeddings) async {
    try {
      for (final embedding in embeddings) {
        await saveEmbedding(embedding);
      }
    } catch (e) {
      throw StorageException('Failed to save embeddings: $e');
    }
  }

  /// Get all embeddings for a user
  ///
  /// Returns a list of all stored face embeddings for the user
  Future<List<FaceEmbedding>> getEmbeddings(String userId) async {
    try {
      final allKeys = await _secureStorage.readAll();
      final userPrefix = _buildKey(userId, null);
      final embeddings = <FaceEmbedding>[];

      for (final entry in allKeys.entries) {
        if (entry.key.startsWith(userPrefix)) {
          try {
            final jsonMap = jsonDecode(entry.value) as Map<String, dynamic>;
            embeddings.add(FaceEmbedding.fromJson(jsonMap));
          } catch (e) {
            print(
                'Warning: Failed to parse embedding from key ${entry.key}: $e');
          }
        }
      }

      return embeddings;
    } catch (e) {
      throw StorageException('Failed to get embeddings: $e');
    }
  }

  /// Get a specific embedding by user ID and label
  Future<FaceEmbedding?> getEmbedding(String userId, String? label) async {
    try {
      final key = _buildKey(userId, label);
      final jsonString = await _secureStorage.read(key: key);

      if (jsonString == null) {
        return null;
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return FaceEmbedding.fromJson(jsonMap);
    } catch (e) {
      throw StorageException('Failed to get embedding: $e');
    }
  }

  /// Delete all embeddings for a user
  ///
  /// Use this when user logs out or unregisters biometric auth
  Future<void> deleteEmbeddings(String userId) async {
    try {
      final allKeys = await _secureStorage.readAll();
      final userPrefix = _buildKey(userId, null);

      for (final key in allKeys.keys) {
        if (key.startsWith(userPrefix)) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      throw StorageException('Failed to delete embeddings: $e');
    }
  }

  /// Delete a specific embedding
  Future<void> deleteEmbedding(String userId, String? label) async {
    try {
      final key = _buildKey(userId, label);
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw StorageException('Failed to delete embedding: $e');
    }
  }

  /// Check if user has any stored embeddings
  Future<bool> hasEmbeddings(String userId) async {
    try {
      final embeddings = await getEmbeddings(userId);
      return embeddings.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get count of stored embeddings for a user
  Future<int> getEmbeddingCount(String userId) async {
    try {
      final embeddings = await getEmbeddings(userId);
      return embeddings.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all face embeddings (use with caution!)
  Future<void> clearAll() async {
    try {
      final allKeys = await _secureStorage.readAll();

      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix)) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      throw StorageException('Failed to clear all embeddings: $e');
    }
  }

  /// Build storage key from user ID and label
  ///
  /// Format: face_embedding_{userId}_{label}
  /// If label is null, returns prefix for all embeddings of user
  String _buildKey(String userId, String? label) {
    // Hash the user ID for additional privacy
    final hashedUserId = _hashUserId(userId);

    if (label == null || label.isEmpty) {
      return '$_keyPrefix$hashedUserId';
    }

    return '${_keyPrefix}${hashedUserId}_$label';
  }

  /// Hash user ID using SHA256 for additional privacy
  ///
  /// This prevents direct exposure of user IDs in storage keys
  String _hashUserId(String userId) {
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Use first 16 chars
  }
}

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
