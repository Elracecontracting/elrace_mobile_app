import 'package:el_race/core/services/notification_storage_service.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationMuteSettingsScreen extends StatefulWidget {
  const NotificationMuteSettingsScreen({super.key});

  @override
  State<NotificationMuteSettingsScreen> createState() =>
      _NotificationMuteSettingsScreenState();
}

class _NotificationMuteSettingsScreenState
    extends State<NotificationMuteSettingsScreen> {
  static const List<_MuteOption> _centerFeedOptions = [
    _MuteOption(
      key: 'notification',
      title: 'Notification Center',
      subtitle: 'General alerts and app updates',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFF1565C0),
    ),
    _MuteOption(
      key: 'announcement',
      title: 'Announcements',
      subtitle: 'Official company announcements',
      icon: Icons.campaign_rounded,
      color: Color(0xFFEF6C00),
    ),
    _MuteOption(
      key: 'circular',
      title: 'Circulars',
      subtitle: 'Policy and circular documents',
      icon: Icons.policy_rounded,
      color: Color(0xFF00695C),
    ),
  ];

  static const List<_MuteOption> _workflowOptions = [
    _MuteOption(
      key: 'hr',
      title: 'HR Requests',
      subtitle: 'Leave, attendance and HR workflows',
      icon: Icons.badge_rounded,
      color: Color(0xFF00897B),
    ),
    _MuteOption(
      key: 'rfq',
      title: 'RFQ',
      subtitle: 'Request for quotation approvals',
      icon: Icons.request_quote_rounded,
      color: Color(0xFF2E7D32),
    ),
    _MuteOption(
      key: 'invoice',
      title: 'Invoices',
      subtitle: 'Invoice reviews and approvals',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF283593),
    ),
    _MuteOption(
      key: 'pettycash',
      title: 'Petty Cash',
      subtitle: 'Petty cash requests and responses',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFC62828),
    ),
    _MuteOption(
      key: 'lpo',
      title: 'LPO / PO',
      subtitle: 'Purchase order notifications',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF6D4C41),
    ),
  ];

  static const List<_MuteOption> _communicationOptions = [
    _MuteOption(
      key: 'chat',
      title: 'Chat Messages',
      subtitle: 'Direct and channel messages',
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFF0277BD),
    ),
  ];

  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await NotificationStorageService.getMuteSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load mute settings: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _setMute(String key, bool muted) async {
    setState(() => _settings[key] = muted);
    await NotificationStorageService.setMuteSetting(key, muted);
  }

  Future<void> _unmuteAll() async {
    final keys = _settings.keys.toList(growable: false);
    for (final key in keys) {
      if (_settings[key] == true) {
        await NotificationStorageService.setMuteSetting(key, false);
      }
    }

    if (!mounted) return;
    setState(() {
      for (final key in keys) {
        _settings[key] = false;
      }
    });
  }

  int _mutedChannelsCount() {
    return _settings.entries
        .where((entry) => entry.key != 'global' && entry.value)
        .length;
  }

  Widget _buildHeroCard() {
    final globalMuted = _settings['global'] == true;
    final mutedCount = _mutedChannelsCount();
    final statusText = globalMuted
        ? 'All notifications are muted right now.'
        : mutedCount == 0
            ? 'You are receiving all channels.'
            : '$mutedCount channels are muted.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26.r),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A1F4D),
            Color(0xFF1B3E86),
            Color(0xFF2D67BC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1F4D).withValues(alpha: 0.2),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -12,
            child: Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.11),
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: -25,
            child: Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.notifications_off_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Mute Controls',
                      style: GoogleFonts.koulen(
                        color: Colors.white,
                        fontSize: 28.sp,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalMuteCard() {
    final isGlobalMuted = _settings['global'] == true;

    return Container(
      margin: EdgeInsets.only(top: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFD7DFEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A53).withValues(alpha: 0.1),
            ),
            child: Icon(
              isGlobalMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: appFontColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mute Everything',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1736),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Pause all categories with one switch.',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF5E6C84),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isGlobalMuted,
            activeTrackColor: const Color(0xFFE27D7D),
            activeColor: const Color(0xFFC62828),
            onChanged: (value) => _setMute('global', value),
          )
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String subtitle,
    List<_MuteOption> options,
  ) {
    final globalMuted = _settings['global'] == true;

    return Container(
      margin: EdgeInsets.only(top: 14.h),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFD7DFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.koulen(
              fontSize: 22.sp,
              color: const Color(0xFF162B58),
              letterSpacing: 0.3,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF6E7B92),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.h),
          ...options.map(
            (option) => _buildChannelTile(
              option,
              disabledByGlobalMute: globalMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(
    _MuteOption option, {
    required bool disabledByGlobalMute,
  }) {
    final isMuted = _settings[option.key] == true;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabledByGlobalMute ? 0.55 : 1,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isMuted
              ? option.color.withValues(alpha: 0.08)
              : const Color(0xFFF7F9FC),
          border: Border.all(
            color: isMuted
                ? option.color.withValues(alpha: 0.5)
                : const Color(0xFFE1E7F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: option.color.withValues(alpha: 0.14),
              ),
              child: Icon(option.icon, color: option.color, size: 21.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111D3A),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    option.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5F6F89),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isMuted,
              activeTrackColor: option.color.withValues(alpha: 0.35),
              activeColor: option.color,
              onChanged: disabledByGlobalMute
                  ? null
                  : (value) => _setMute(option.key, value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF3F6FB),
        foregroundColor: appFontColor,
        title: Text(
          'Mute Notifications',
          style: GoogleFonts.koulen(
            color: appFontColor,
            fontSize: 28.sp,
          ),
        ),
        actions: [
          if (!_isLoading && _settings.values.any((value) => value))
            TextButton.icon(
              onPressed: _unmuteAll,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Unmute all',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E6BC3),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  _buildHeroCard(),
                  _buildGlobalMuteCard(),
                  _buildSection(
                    'Center Feed',
                    'Top-level notification streams in the app.',
                    _centerFeedOptions,
                  ),
                  _buildSection(
                    'Approvals and Workflows',
                    'Requests and financial process notifications.',
                    _workflowOptions,
                  ),
                  _buildSection(
                    'Communication',
                    'Conversation and messaging notifications.',
                    _communicationOptions,
                  ),
                ],
              ),
            ),
    );
  }
}

class _MuteOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MuteOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
