import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Protocol (interface) for generic storage operations
abstract class StorageService {
  /// Save data with a key
  Future<void> save(String key, String data);

  /// Read data by key
  Future<String?> read(String key);

  /// Delete data by key
  Future<void> delete(String key);

  /// Check if key exists
  Future<bool> exists(String key);

  /// Clear all data
  Future<void> clear();

  /// List all stored keys (for cleanup operations)
  Future<List<String>> listKeys();
}

/// File-based storage service implementation
class FileStorageService implements StorageService {
  FileStorageService({String? directoryName})
    : _directoryName = directoryName ?? 'app_storage';

  final String _directoryName;
  Directory? _storageDirectory;

  /// Get or create storage directory
  Future<Directory> _getStorageDirectory() async {
    if (_storageDirectory != null) return _storageDirectory!;

    final appDocDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${appDocDir.path}/$_directoryName');

    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    _storageDirectory = storageDir;
    return _storageDirectory!;
  }

  /// Get file path for a key
  Future<String> _getFilePath(String key) async {
    final dir = await _getStorageDirectory();
    // Sanitize key to be file-system safe
    final sanitizedKey = key.replaceAll(RegExp(r'[^\w\-.]'), '_');
    return '${dir.path}/$sanitizedKey.json';
  }

  @override
  Future<void> save(String key, String data) async {
    try {
      final filePath = await _getFilePath(key);
      final file = File(filePath);
      await file.writeAsString(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final filePath = await _getFilePath(key);
      final file = File(filePath);

      if (!await file.exists()) {
        return null;
      }

      final data = await file.readAsString();
      return data;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final filePath = await _getFilePath(key);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently handle delete errors
    }
  }

  @override
  Future<bool> exists(String key) async {
    try {
      final filePath = await _getFilePath(key);
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _getStorageDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _storageDirectory = null;
      }
    } catch (e) {
      // Silently handle clear errors
    }
  }

  @override
  Future<List<String>> listKeys() async {
    try {
      final dir = await _getStorageDirectory();
      if (!await dir.exists()) {
        return [];
      }

      final files = dir.listSync();
      final keys = <String>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          // Extract key from filename (remove .json extension)
          final fileName = file.path.split('/').last;
          final key = fileName.replaceAll('.json', '');
          keys.add(key);
        }
      }

      return keys;
    } catch (e) {
      return [];
    }
  }
}
