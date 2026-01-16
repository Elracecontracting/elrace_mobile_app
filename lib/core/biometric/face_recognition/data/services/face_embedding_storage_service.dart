import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import '../../domain/entities/face_embedding.dart';

/// Enhanced Face Embedding Storage Service
///
/// NEW FEATURES:
/// - Binary storage (Float32List -> bytes) instead of JSON
/// - AES-256-GCM encryption for embedding files
/// - Encryption keys stored in flutter_secure_storage
/// - Versioning support (model, alignment, liveness versions)
/// - Multi-sample storage (front, left15, right15)
/// - Device binding (optional security)
///
/// Architecture:
/// - Embedding data: Encrypted binary files in app documents directory
/// - Metadata: Stored in flutter_secure_storage (file paths, versions, createdAt)
/// - Encryption keys: Stored in keychain/keystore (flutter_secure_storage)
class FaceEmbeddingStorageService {
  final FlutterSecureStorage _secureStorage;

  // Storage keys
  static const String _keyPrefix = 'face_meta_';
  static const String _encryptionKeyPrefix = 'face_key_';

  // Versioning
  static const String modelVersion = 'mobilefacenet_v1';
  static const int embeddingDim = 192;
  static const int alignmentVersion = 1;
  static const int livenessVersion = 2;

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

  /// Save a face embedding (encrypted binary file)
  ///
  /// Process:
  /// 1. Convert Float32List to bytes
  /// 2. Encrypt bytes with AES-256-GCM
  /// 3. Write encrypted file
  /// 4. Save metadata to secure storage
  Future<void> saveEmbedding(FaceEmbedding embedding) async {
    try {
      print('\n💾 ===== SAVING EMBEDDING =====');
      print('👤 User ID: ${embedding.userId}');
      print('🏷️ Label: ${embedding.label ?? "default"}');
      print('📊 Embedding dimensions: ${embedding.embedding.length}');

      // Get or create encryption key for this user
      final encryptionKey = await _getOrCreateEncryptionKey(embedding.userId);

      // Convert embedding to binary (Float32List -> Uint8List)
      final embeddingBytes = _embeddingToBytes(embedding.embedding);

      // Encrypt
      final encryptedData = _encryptData(embeddingBytes, encryptionKey);

      // Write encrypted file
      final filePath = await _getEmbeddingFilePath(
        embedding.userId,
        embedding.label ?? 'default',
      );
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(encryptedData);

      print('✅ Embedding saved to: $filePath');
      print('🔐 Encrypted data size: ${encryptedData.length} bytes');

      // Save metadata
      await _saveMetadata(embedding, filePath);
      print('✅ Metadata saved\n');
    } catch (e) {
      print('❌ ERROR saving embedding: $e\n');
      throw StorageException('Failed to save embedding: $e');
    }
  }

  /// Save multiple embeddings (batch operation)
  Future<void> saveEmbeddings(List<FaceEmbedding> embeddings) async {
    for (final embedding in embeddings) {
      await saveEmbedding(embedding);
    }
  }

  /// Get all embeddings for a user
  Future<List<FaceEmbedding>> getEmbeddings(String userId) async {
    try {
      print('\n🔍 ===== GETTING EMBEDDINGS =====');
      print('👤 User ID: $userId');

      // DEBUG: List ALL stored embeddings keys to see what's available
      final allKeys = await _secureStorage.readAll();
      final faceMetaKeys =
          allKeys.keys.where((k) => k.startsWith(_keyPrefix)).toList();
      print('📋 ALL stored face metadata keys:');
      for (final key in faceMetaKeys) {
        print('   - $key');
      }
      print('📋 Total keys: ${faceMetaKeys.length}');

      final metadataList = await _getAllMetadata(userId);
      print(
          '📦 Found ${metadataList.length} metadata entries for userId: $userId');

      final embeddings = <FaceEmbedding>[];

      for (final metadata in metadataList) {
        try {
          print('   Loading: ${metadata["label"] ?? "default"}');
          final embedding = await _loadEmbeddingFromMetadata(metadata, userId);
          embeddings.add(embedding);
          print('   ✅ Loaded successfully');
        } catch (e) {
          print(
              '   ⚠️ Warning: Failed to load embedding from ${metadata['filePath']}: $e');
        }
      }

      print('✅ Total embeddings loaded: ${embeddings.length}\n');
      return embeddings;
    } catch (e) {
      print('❌ ERROR getting embeddings: $e\n');
      throw StorageException('Failed to get embeddings: $e');
    }
  }

  /// Get a specific embedding by label
  Future<FaceEmbedding?> getEmbedding(String userId, String? label) async {
    try {
      final metadata = await _getMetadata(userId, label);
      if (metadata == null) return null;

      return await _loadEmbeddingFromMetadata(metadata, userId);
    } catch (e) {
      throw StorageException('Failed to get embedding: $e');
    }
  }

  /// Delete all embeddings for a user
  Future<void> deleteEmbeddings(String userId) async {
    try {
      // Get all metadata
      final metadataList = await _getAllMetadata(userId);

      // Delete files
      for (final metadata in metadataList) {
        final filePath = metadata['filePath'] as String?;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      // Delete metadata from secure storage
      final allKeys = await _secureStorage.readAll();
      final userPrefix = _buildMetadataKey(userId, null);

      for (final key in allKeys.keys) {
        if (key.startsWith(userPrefix)) {
          await _secureStorage.delete(key: key);
        }
      }

      // Delete encryption key
      final encKeyId = _buildEncryptionKeyId(userId);
      await _secureStorage.delete(key: encKeyId);
    } catch (e) {
      throw StorageException('Failed to delete embeddings: $e');
    }
  }

  /// Delete a specific embedding
  Future<void> deleteEmbedding(String userId, String? label) async {
    try {
      final metadata = await _getMetadata(userId, label);
      if (metadata != null) {
        // Delete file
        final filePath = metadata['filePath'] as String?;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }

        // Delete metadata
        final key = _buildMetadataKey(userId, label);
        await _secureStorage.delete(key: key);
      }
    } catch (e) {
      throw StorageException('Failed to delete embedding: $e');
    }
  }

  /// Delete ALL embeddings (for debugging/cleanup)
  Future<void> deleteAllEmbeddings() async {
    try {
      print('\n🗑️ ===== DELETING ALL EMBEDDINGS =====');
      final allKeys = await _secureStorage.readAll();

      int deleted = 0;
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix) ||
            key.startsWith(_encryptionKeyPrefix)) {
          // Try to get and delete the file first
          if (key.startsWith(_keyPrefix)) {
            try {
              final metadata =
                  jsonDecode(allKeys[key]!) as Map<String, dynamic>;
              final filePath = metadata['filePath'] as String?;
              if (filePath != null) {
                final file = File(filePath);
                if (await file.exists()) {
                  await file.delete();
                  print('   🗑️ Deleted file: $filePath');
                }
              }
            } catch (e) {
              print('   ⚠️ Could not parse/delete file for key: $key');
            }
          }
          await _secureStorage.delete(key: key);
          print('   🗑️ Deleted key: $key');
          deleted++;
        }
      }
      print('✅ Deleted $deleted keys/files\n');
    } catch (e) {
      print('❌ Error deleting all embeddings: $e');
      throw StorageException('Failed to delete all embeddings: $e');
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

  /// Get count of stored embeddings
  Future<int> getEmbeddingCount(String userId) async {
    try {
      final embeddings = await getEmbeddings(userId);
      return embeddings.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all face embeddings (dangerous!)
  Future<void> clearAll() async {
    try {
      // Delete all embedding files
      final directory = await _getEmbeddingsDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }

      // Clear secure storage
      final allKeys = await _secureStorage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix) ||
            key.startsWith(_encryptionKeyPrefix)) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      throw StorageException('Failed to clear all embeddings: $e');
    }
  }

  // ======================== PRIVATE HELPERS ========================

  /// Get or create encryption key for user
  Future<String> _getOrCreateEncryptionKey(String userId) async {
    final keyId = _buildEncryptionKeyId(userId);
    String? key = await _secureStorage.read(key: keyId);

    if (key == null) {
      // Generate new 32-byte (256-bit) key
      key = encrypt.Key.fromSecureRandom(32).base64;
      await _secureStorage.write(key: keyId, value: key);
    }

    return key;
  }

  /// Convert Float64 embedding to bytes (Float32)
  Uint8List _embeddingToBytes(List<double> embedding) {
    final float32List = Float32List(embedding.length);
    for (int i = 0; i < embedding.length; i++) {
      float32List[i] = embedding[i];
    }
    return float32List.buffer.asUint8List();
  }

  /// Convert bytes back to Float64 embedding
  List<double> _bytesToEmbedding(Uint8List bytes) {
    final float32List = Float32List.view(bytes.buffer);
    return List<double>.from(float32List);
  }

  /// Encrypt data using AES-256-GCM
  Uint8List _encryptData(Uint8List data, String base64Key) {
    final key = encrypt.Key.fromBase64(base64Key);
    final iv = encrypt.IV.fromSecureRandom(16); // 16 bytes for GCM

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encryptBytes(data, iv: iv);

    // Prepend IV to encrypted data (IV is needed for decryption)
    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setRange(0, iv.bytes.length, iv.bytes);
    combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);

    return combined;
  }

  /// Decrypt data using AES-256-GCM
  Uint8List _decryptData(Uint8List encryptedData, String base64Key) {
    final key = encrypt.Key.fromBase64(base64Key);

    // Extract IV (first 16 bytes)
    final iv = encrypt.IV(encryptedData.sublist(0, 16));

    // Extract encrypted data (rest)
    final encrypted = encrypt.Encrypted(encryptedData.sublist(16));

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    return Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: iv));
  }

  /// Get embeddings directory
  Future<Directory> _getEmbeddingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/face_embeddings');
  }

  /// Get file path for embedding
  Future<String> _getEmbeddingFilePath(String userId, String label) async {
    final dir = await _getEmbeddingsDirectory();
    final hashedUserId = _hashUserId(userId);
    return '${dir.path}/${hashedUserId}_$label.bin';
  }

  /// Save metadata to secure storage
  Future<void> _saveMetadata(FaceEmbedding embedding, String filePath) async {
    final metadata = {
      'filePath': filePath,
      'createdAt': embedding.createdAt.toIso8601String(),
      'modelVersion': modelVersion,
      'embeddingDim': embeddingDim,
      'alignmentVersion': alignmentVersion,
      'livenessVersion': livenessVersion,
      'label': embedding.label ?? 'default',
    };

    final key = _buildMetadataKey(embedding.userId, embedding.label);
    await _secureStorage.write(key: key, value: jsonEncode(metadata));
  }

  /// Get metadata for specific embedding
  Future<Map<String, dynamic>?> _getMetadata(
      String userId, String? label) async {
    final key = _buildMetadataKey(userId, label);
    final jsonString = await _secureStorage.read(key: key);

    if (jsonString == null) return null;

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Get all metadata for user
  Future<List<Map<String, dynamic>>> _getAllMetadata(String userId) async {
    final allKeys = await _secureStorage.readAll();
    final userPrefix = _buildMetadataKey(userId, null);
    final metadataList = <Map<String, dynamic>>[];

    for (final entry in allKeys.entries) {
      if (entry.key.startsWith(userPrefix)) {
        try {
          final metadata = jsonDecode(entry.value) as Map<String, dynamic>;
          metadataList.add(metadata);
        } catch (e) {
          print('Warning: Failed to parse metadata from ${entry.key}: $e');
        }
      }
    }

    return metadataList;
  }

  /// Load embedding from metadata
  Future<FaceEmbedding> _loadEmbeddingFromMetadata(
    Map<String, dynamic> metadata,
    String userId,
  ) async {
    final filePath = metadata['filePath'] as String;
    final file = File(filePath);

    if (!await file.exists()) {
      throw StorageException('Embedding file not found: $filePath');
    }

    // Read encrypted file
    final encryptedData = await file.readAsBytes();

    // Decrypt
    final encryptionKey = await _getOrCreateEncryptionKey(userId);
    final decryptedBytes = _decryptData(encryptedData, encryptionKey);

    // Convert bytes to embedding
    final embedding = _bytesToEmbedding(decryptedBytes);

    return FaceEmbedding(
      embedding: embedding,
      userId: userId,
      createdAt: DateTime.parse(metadata['createdAt'] as String),
      label: metadata['label'] as String?,
    );
  }

  /// Build metadata key
  String _buildMetadataKey(String userId, String? label) {
    final hashedUserId = _hashUserId(userId);
    return label != null
        ? '$_keyPrefix${hashedUserId}_$label'
        : '$_keyPrefix$hashedUserId';
  }

  /// Build encryption key ID
  String _buildEncryptionKeyId(String userId) {
    final hashedUserId = _hashUserId(userId);
    return '$_encryptionKeyPrefix$hashedUserId';
  }

  /// Hash user ID for privacy
  String _hashUserId(String userId) {
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Use first 16 chars
  }
}

/// Storage exception
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
