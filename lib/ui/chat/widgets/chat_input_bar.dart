import 'dart:async';

import 'package:flutter/material.dart';

import '../../../chat/chat.dart';
import '../../../resources/app_colors.dart';

/// Chat input bar with text field and attachment buttons
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isRecording;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.isRecording,
    required this.onSendText,
    required this.onPickImage,
    required this.onPickFile,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  bool _hasText = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  late AnimationController _recordingAnimController;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _recordingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recordingTimer?.cancel();
    _recordingAnimController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle recording state changes
    if (widget.isRecording && !oldWidget.isRecording) {
      _startRecordingTimer();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _stopRecordingTimer();
    }
  }

  void _startRecordingTimer() {
    _recordingDuration = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDuration++);
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingDuration = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: widget.isRecording ? _buildRecordingBar() : _buildInputBar(),
    );
  }

  Widget _buildInputBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attachment button
        _AttachmentButton(
          onPickImage: widget.onPickImage,
          onPickFile: widget.onPickFile,
          isLoading: widget.isLoading,
        ),
        
        const SizedBox(width: 8),
        
        // Text input field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => widget.onSendText(),
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Send or voice button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _hasText
                  ? _buildSendButton()
                  : _buildMicButton(),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: widget.onSendText,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: const Icon(
            Icons.send,
            color: AppColors.primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: widget.onStartRecording, // Allow tap to start recording
      onLongPressStart: (_) => widget.onStartRecording(),
      onLongPressEnd: (_) => widget.onStopRecording(),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: const Icon(
            Icons.mic,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        // Cancel button
        TextButton.icon(
          onPressed: widget.onCancelRecording,
          icon: const Icon(Icons.delete, color: Colors.red),
          label: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        
        const Spacer(),
        
        // Recording indicator
        AnimatedBuilder(
          animation: _recordingAnimController,
          builder: (context, child) {
            return Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.5 + _recordingAnimController.value * 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        
        const Spacer(),
        
        // Stop and send button
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: widget.onStopRecording,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: const Icon(
                Icons.stop,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _AttachmentButton extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final bool isLoading;

  const _AttachmentButton({
    required this.onPickImage,
    required this.onPickFile,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: !isLoading,
      onSelected: (value) {
        switch (value) {
          case 'image':
            onPickImage();
            break;
          case 'file':
            onPickFile();
            break;
        }
      },
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'image',
          child: Row(
            children: [
              Icon(Icons.image, color: Colors.green[600]),
              const SizedBox(width: 12),
              const Text('Image'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'file',
          child: Row(
            children: [
              Icon(Icons.insert_drive_file, color: Colors.blue[600]),
              const SizedBox(width: 12),
              const Text('File'),
            ],
          ),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          Icons.add,
          color: Colors.grey[700],
          size: 26,
        ),
      ),
    );
  }
}
