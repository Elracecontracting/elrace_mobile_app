import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../chat/chat.dart';
import '../../../resources/app_colors.dart';

/// Message bubble widget for displaying a single message
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60 : 8,
          right: isMe ? 8 : 60,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildBubble(context),
            _buildStatus(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    final bgColor = isMe 
        ? AppColors.primaryBlackLight 
        : AppColors.chatReceiverColor;
    final textColor = isMe ? AppColors.primaryColor : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        child: _buildContent(context, textColor),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (message.type) {
      case MessageType.text:
        return _TextContent(message: message, textColor: textColor, isMe: isMe);
      case MessageType.image:
        return _ImageContent(message: message, isMe: isMe);
      case MessageType.audio:
        return _AudioContent(message: message, isMe: isMe);
      case MessageType.video:
        return _VideoContent(message: message, isMe: isMe);
      case MessageType.file:
        return _FileContent(message: message, textColor: textColor, isMe: isMe);
    }
  }

  Widget _buildStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            _buildReadReceipt(),
          ],
        ],
      ),
    );
  }

  Widget _buildReadReceipt() {
    switch (message.status) {
      case MessageStatus.sending:
        // Clock icon for pending message
        return Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey[400],
        );
      case MessageStatus.failed:
        // Error icon for failed message
        return Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red[400],
        );
      case MessageStatus.sent:
        // Single check for sent
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.grey[400],
        );
      case MessageStatus.delivered:
        // Double check gray for delivered
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.grey[400],
        );
      case MessageStatus.read:
        // Double check blue for read
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.blue[400],
        );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _TextContent extends StatelessWidget {
  final Message message;
  final Color textColor;
  final bool isMe;

  const _TextContent({
    required this.message,
    required this.textColor,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        message.text ?? '',
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.3,
        ),
      ),
    );
  }
}

class _ImageContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _ImageContent({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.mediaUrl != null)
            Image.network(
              message.mediaUrl!,
              fit: BoxFit.cover,
              width: 250,
              height: 200,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  width: 250,
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stack) => Container(
                width: 250,
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 40),
              ),
            ),
          if (message.text != null && message.text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                message.text!,
                style: TextStyle(
                  color: isMe ? AppColors.primaryColor : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    if (message.mediaUrl == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: InteractiveViewer(
            child: Center(
              child: Image.network(message.mediaUrl!),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioContent extends StatefulWidget {
  final Message message;
  final bool isMe;

  const _AudioContent({
    required this.message,
    required this.isMe,
  });

  @override
  State<_AudioContent> createState() => _AudioContentState();
}

class _AudioContentState extends State<_AudioContent> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.message.mediaUrl == null) return;

    try {
      await _player.setUrl(widget.message.mediaUrl!);
      _duration = _player.duration ?? Duration.zero;
      
      if (widget.message.durationMs != null) {
        _duration = Duration(milliseconds: widget.message.durationMs!);
      }

      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isMe ? AppColors.primaryColor : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isMe 
                    ? AppColors.primaryColor.withValues(alpha: 0.2) 
                    : Colors.grey[300],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: widget.isMe ? AppColors.primaryColor : AppColors.primaryColor,
                      inactiveTrackColor: widget.isMe 
                          ? AppColors.primaryColor.withValues(alpha: 0.3) 
                          : Colors.grey[400],
                      thumbColor: widget.isMe ? AppColors.primaryColor : AppColors.primaryColor,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble(),
                      max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      onChanged: (value) {
                        _player.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.mic,
            size: 20,
            color: textColor.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _VideoContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _VideoContent({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideo(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 250,
            height: 150,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (message.thumbUrl != null)
                  Image.network(
                    message.thumbUrl!,
                    fit: BoxFit.cover,
                    width: 250,
                    height: 150,
                  ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                if (message.durationMs != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(message.durationMs!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (message.text != null && message.text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                message.text!,
                style: TextStyle(
                  color: isMe ? AppColors.primaryColor : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openVideo(BuildContext context) async {
    if (message.mediaUrl == null) return;
    
    final uri = Uri.parse(message.mediaUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _FileContent extends StatelessWidget {
  final Message message;
  final Color textColor;
  final bool isMe;

  const _FileContent({
    required this.message,
    required this.textColor,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isMe 
                    ? AppColors.primaryColor.withValues(alpha: 0.2) 
                    : Colors.grey[300],
              ),
              child: Icon(
                _getFileIcon(),
                color: textColor,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'ملف',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSize != null)
                    Text(
                      _formatFileSize(message.fileSize!),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download,
              color: textColor.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    final mimeType = message.mimeType?.toLowerCase() ?? '';
    
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('doc')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('sheet')) return Icons.table_chart;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return Icons.slideshow;
    if (mimeType.contains('zip') || mimeType.contains('rar')) return Icons.folder_zip;
    if (mimeType.contains('text')) return Icons.article;
    
    return Icons.insert_drive_file;
  }

  void _openFile() async {
    if (message.mediaUrl == null) return;
    
    final uri = Uri.parse(message.mediaUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
