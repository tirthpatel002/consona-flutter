/// Consona Media Item & Types — Uniform representation of images, documents, audio, and binary files.
library;

import 'dart:typed_data';

/// High-level classification of media and file types.
enum ConsonaMediaType {
  image,
  video,
  audio,
  document,
  code,
  archive,
  generic;

  /// Returns a clean uppercase label for badge rendering (e.g. 'PDF', 'IMG', 'CODE').
  String get badgeLabel => switch (this) {
        ConsonaMediaType.image => 'IMG',
        ConsonaMediaType.video => 'VID',
        ConsonaMediaType.audio => 'AUD',
        ConsonaMediaType.document => 'DOC',
        ConsonaMediaType.code => 'CODE',
        ConsonaMediaType.archive => 'ZIP',
        ConsonaMediaType.generic => 'FILE',
      };
}

/// Immutable descriptor for an inspectable media asset or file.
class ConsonaMediaItem {
  const ConsonaMediaItem({
    required this.id,
    required this.name,
    this.uri,
    this.type,
    this.sizeLabel,
    this.caption,
    this.textContent,
    this.bytes,
    this.thumbnailUri,
    this.metadata = const {},
  });

  /// Unique identifier for this media item.
  final String id;

  /// Display name of the file (e.g. 'quarterly-report.pdf', 'hero-header.webp').
  final String name;

  /// Remote URL, local file path, or bundled asset path.
  final String? uri;

  /// Explicit media type. If omitted, [resolvedType] infers it from [name].
  final ConsonaMediaType? type;

  /// Human-readable file size (e.g. '1.4 MB', '450 KB').
  final String? sizeLabel;

  /// Optional descriptive caption or alt text.
  final String? caption;

  /// Optional plain-text content for code, logs, markdown, or JSON files.
  final String? textContent;

  /// Optional raw bytes for in-memory files.
  final Uint8List? bytes;

  /// Optional thumbnail URI used for filmstrip galleries or low-res previews.
  final String? thumbnailUri;

  /// Arbitrary custom metadata dictionary.
  final Map<String, dynamic> metadata;

  /// Infers file extension in lowercase without leading dot (e.g. 'png', 'pdf').
  String get fileExtension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex + 1).toLowerCase();
    }
    return '';
  }

  /// Resolves the effective [ConsonaMediaType], inferring from extension if not explicitly set.
  ConsonaMediaType get resolvedType {
    if (type != null) return type!;
    final ext = fileExtension;
    return switch (ext) {
      'png' || 'jpg' || 'jpeg' || 'webp' || 'gif' || 'svg' || 'bmp' || 'avif' =>
        ConsonaMediaType.image,
      'mp4' || 'mov' || 'webm' || 'mkv' || 'avi' => ConsonaMediaType.video,
      'mp3' || 'wav' || 'aac' || 'm4a' || 'ogg' || 'flac' =>
        ConsonaMediaType.audio,
      'pdf' || 'doc' || 'docx' || 'ppt' || 'pptx' || 'xls' || 'xlsx' || 'rtf' =>
        ConsonaMediaType.document,
      'dart' ||
      'json' ||
      'yaml' ||
      'yml' ||
      'xml' ||
      'csv' ||
      'sql' ||
      'js' ||
      'ts' ||
      'html' ||
      'css' ||
      'md' ||
      'txt' ||
      'log' ||
      'sh' =>
        ConsonaMediaType.code,
      'zip' || 'tar' || 'gz' || '7z' || 'rar' || 'bz2' =>
        ConsonaMediaType.archive,
      _ => ConsonaMediaType.generic,
    };
  }

  /// Whether this media item is an image that can be rendered natively.
  bool get isImage => resolvedType == ConsonaMediaType.image;

  /// Whether this media item is playable video.
  bool get isVideo => resolvedType == ConsonaMediaType.video;

  /// Whether this media item has inspectable text content.
  bool get hasTextContent =>
      textContent != null && textContent!.isNotEmpty ||
      resolvedType == ConsonaMediaType.code;

  /// Whether this media item is playable audio.
  bool get isAudio => resolvedType == ConsonaMediaType.audio;

  ConsonaMediaItem copyWith({
    String? id,
    String? name,
    String? uri,
    ConsonaMediaType? type,
    String? sizeLabel,
    String? caption,
    String? textContent,
    Uint8List? bytes,
    String? thumbnailUri,
    Map<String, dynamic>? metadata,
  }) {
    return ConsonaMediaItem(
      id: id ?? this.id,
      name: name ?? this.name,
      uri: uri ?? this.uri,
      type: type ?? this.type,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      caption: caption ?? this.caption,
      textContent: textContent ?? this.textContent,
      bytes: bytes ?? this.bytes,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      metadata: metadata ?? this.metadata,
    );
  }
}
