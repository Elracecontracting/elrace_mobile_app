import 'dart:convert';

import 'package:el_race/core/services/notification_storage_service.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/hr_details_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/invoice_details_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/pettycash_details_screen.dart';
import 'package:el_race/ui/presentation/Email%20Approval/screens/rfq_details_screen.dart';
import 'package:el_race/ui/presentation/Notification/notification_mute_settings_screen.dart';
import 'package:el_race/ui/presentation/circular_announcement/data/circular_announcement_api_service.dart';
import 'package:el_race/ui/presentation/circular_announcement/data/circular_announcement_model.dart';
import 'package:el_race/ui/presentation/circular_announcement/widgets/circular_announcement_file_viewer.dart';
import 'package:el_race/utils/Util.dart';
import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:el_race/utils/safe_insets.dart';
import 'package:intl/intl.dart';

import '../../widgets/header_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationTabConfig {
  final String category;
  final String title;
  final String icon;

  const _NotificationTabConfig({
    required this.category,
    required this.title,
    required this.icon,
  });
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const List<_NotificationTabConfig> _fixedNotificationTabs = [
    _NotificationTabConfig(
      category: 'circular',
      title: 'Circulars',
      icon: 'assets/png/urgent_icon.png',
    ),
    _NotificationTabConfig(
      category: 'announcement',
      title: 'Announcements',
      icon: 'assets/png/announcement.png',
    ),
  ];

  int currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _tabKeys = <GlobalKey>[];
  List<_NotificationTabConfig> _notificationTabs = const [];
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;

  // Circular/Announcement API data
  final CircularAnnouncementApiService _circularApiService =
      CircularAnnouncementApiService();
  CircularAnnouncementResponse? _circularAnnouncementData;
  bool _isLoadingCircularAnnouncement = false;
  String? _circularAnnouncementError;
  Map<String, bool> _muteSettings = const {};
  bool _isMuteSettingsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDynamicCategories();
    _loadMuteSettings();
    _loadNotifications();
    _loadCircularAnnouncements(); // Load from API
  }

  String _normalizeCategory(String value) {
    return value.trim().toLowerCase();
  }

  String _humanizeCategory(String value) {
    final category = value.trim();
    if (category.isEmpty) return 'Notifications';

    final parts = category
        .split(RegExp(r'[._-]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
      final p = part.trim();
      return '${p[0].toUpperCase()}${p.substring(1)}';
    }).toList(growable: false);

    if (parts.isEmpty) return 'Notifications';
    return parts.join(' ');
  }

  String _tabIconForCategory(String category) {
    final normalized = _normalizeCategory(category);
    if (normalized == 'announcement') {
      return 'assets/png/announcement.png';
    }
    if (normalized == 'circular') {
      return 'assets/png/urgent_icon.png';
    }
    return 'assets/png/notification_icon.png';
  }

  Future<void> _loadDynamicCategories({bool forceRefresh = false}) async {
    try {
      final categories =
          await NotificationStorageService.getNotificationCategories(
              forceRefresh: forceRefresh);

      final dynamicTabs = categories
          .map((item) {
            final category = _normalizeCategory(item.model);
            if (category == 'circular' || category == 'announcement') {
              return null;
            }
            final title = item.title.trim().isEmpty
                ? _humanizeCategory(category)
                : item.title.trim();

            return _NotificationTabConfig(
              category: category,
              title: title,
              icon: _tabIconForCategory(category),
            );
          })
          .whereType<_NotificationTabConfig>()
          .toList(growable: true);

      final tabs = <_NotificationTabConfig>[
        ..._fixedNotificationTabs,
        ...dynamicTabs,
      ];

      if (tabs.length == _fixedNotificationTabs.length) {
        tabs.add(
          const _NotificationTabConfig(
            category: 'notification',
            title: 'Notifications',
            icon: 'assets/png/notification_icon.png',
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _notificationTabs = tabs;
        _tabKeys = List.generate(tabs.length, (_) => GlobalKey());
        if (currentIndex >= tabs.length) {
          currentIndex = 0;
        }
      });
    } catch (e) {
      debugPrint('Error loading notification categories: $e');
      if (!mounted) return;
      setState(() {
        _notificationTabs = const [
          ..._fixedNotificationTabs,
          _NotificationTabConfig(
            category: 'notification',
            title: 'Notifications',
            icon: 'assets/png/notification_icon.png',
          ),
        ];
        _tabKeys = List.generate(_notificationTabs.length, (_) => GlobalKey());
        if (currentIndex >= _notificationTabs.length) {
          currentIndex = 0;
        }
      });
    }
  }

  Future<void> _loadMuteSettings() async {
    try {
      final settings = await NotificationStorageService.getMuteSettings();
      if (!mounted) return;
      setState(() {
        _muteSettings = settings;
        _isMuteSettingsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading mute settings: $e');
      if (!mounted) return;
      setState(() => _isMuteSettingsLoading = false);
    }
  }

  Future<void> _openMuteSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationMuteSettingsScreen(),
      ),
    );

    if (!mounted) return;
    await _loadMuteSettings();
    await _loadDynamicCategories(forceRefresh: true);
    await _loadNotifications();
    await _loadCircularAnnouncements();
  }

  Widget _buildMuteSettingsEntryCard() {
    final mutedCount =
        _muteSettings.entries.where((entry) => entry.value).length;

    final subtitle = _isMuteSettingsLoading
        ? 'Loading notification preferences...'
        : mutedCount == 0
            ? 'All categories are active.'
            : '$mutedCount categories are muted.';

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: _openMuteSettings,
      child: Ink(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF4F7FE),
              Color(0xFFEAF1FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFD0DAEC)),
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appFontColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: appFontColor,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Preferences',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0D1F47),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF5E6D88),
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.sp,
              color: const Color(0xFF2C4C91),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final loadedNotifications =
          await NotificationStorageService.getNotifications();
      final observedCategories = loadedNotifications
          .map(
            (item) => _normalizeCategory((item["category"] ?? "").toString()),
          )
          .where((category) => category.isNotEmpty)
          .toSet();

      if (mounted) {
        setState(() {
          notifications = loadedNotifications;

          for (final category in observedCategories) {
            final exists = _notificationTabs.any(
              (tab) => tab.category == category,
            );
            if (!exists) {
              if (category == 'circular' || category == 'announcement') {
                continue;
              }
              _notificationTabs = [
                ..._notificationTabs,
                _NotificationTabConfig(
                  category: category,
                  title: _humanizeCategory(category),
                  icon: _tabIconForCategory(category),
                ),
              ];
              _tabKeys =
                  List.generate(_notificationTabs.length, (_) => GlobalKey());
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCircularAnnouncements() async {
    setState(() {
      _isLoadingCircularAnnouncement = true;
      _circularAnnouncementError = null;
    });

    try {
      final response = await _circularApiService.fetchCircularAnnouncements();
      if (mounted) {
        setState(() {
          _circularAnnouncementData = response;
          _isLoadingCircularAnnouncement = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading circulars/announcements: $e');
      if (mounted) {
        setState(() {
          _circularAnnouncementError = e.toString();
          _isLoadingCircularAnnouncement = false;
        });
      }
    }
  }

  bool _isRead(Map<String, dynamic> item) {
    final value = item['isRead'] ?? item['is_read'] ?? false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString().toLowerCase() == 'true';
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    await NotificationStorageService.markAsRead(notificationId);
    if (!mounted) return;

    setState(() {
      notifications = notifications.map((notification) {
        if (notification['id']?.toString() == notificationId) {
          final updated = Map<String, dynamic>.from(notification);
          updated['isRead'] = true;
          updated['is_read'] = true;
          return updated;
        }
        return notification;
      }).toList();
    });
  }

  Future<bool> _dismissNotification(String notificationId) async {
    if (notificationId.trim().isEmpty) return false;
    try {
      await NotificationStorageService.markAsRead(notificationId);
    } catch (_) {}
    if (!mounted) return false;
    setState(() {
      notifications.removeWhere(
        (n) => n['id']?.toString() == notificationId,
      );
    });
    return true;
  }

  Map<String, dynamic> _extractNotificationData(Map<String, dynamic> item) {
    final rawData = item['data'];
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }
    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }
    if (rawData is String && rawData.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Ignore malformed JSON payload and fallback to empty map.
      }
    }
    return {};
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  int? _extractRecordId(Map<String, dynamic> item, Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['record_id'],
      data['recordId'],
      data['res_id'],
      data['resId'],
      data['request_id'],
      data['hr_request_id'],
      data['rfq_id'],
      data['invoice_id'],
      data['petty_cash_id'],
      data['expense_id'],
      data['po_id'],
      data['lpo_id'],
      data['id'],
      item['record_id'],
      item['recordId'],
      item['res_id'],
      item['resId'],
      item['request_id'],
      item['hr_request_id'],
      item['rfq_id'],
      item['invoice_id'],
      item['petty_cash_id'],
      item['expense_id'],
      item['po_id'],
      item['lpo_id'],
    ];

    for (final candidate in candidates) {
      final id = _toInt(candidate);
      if (id != null) return id;
    }

    return null;
  }

  String _normalizeType(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _resolveRecordType(
      Map<String, dynamic> item, Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['record_type'],
      data['target_type'],
      data['model_name'],
      data['model'],
      data['module'],
      data['entity'],
      data['resource_type'],
      data['type'],
      data['screen'],
      item['record_type'],
      item['target_type'],
      item['model_name'],
      item['model'],
      item['module'],
      item['entity'],
      item['resource_type'],
      item['type'],
      item['category'],
    ];

    bool hasLpoKey = false;
    bool hasRfqKey = false;
    bool hasInvoiceKey = false;
    bool hasHrKey = false;
    bool hasPettyKey = false;

    final keyPool = <dynamic>[
      ...data.keys,
      ...item.keys,
      data['po_id'],
      data['lpo_id'],
      data['rfq_id'],
      data['invoice_id'],
      data['request_id'],
      data['hr_request_id'],
      data['petty_cash_id'],
      data['expense_id'],
      item['po_id'],
      item['lpo_id'],
      item['rfq_id'],
      item['invoice_id'],
      item['request_id'],
      item['hr_request_id'],
      item['petty_cash_id'],
      item['expense_id'],
    ];

    for (final key in keyPool) {
      final normalized = _normalizeType(key);
      if (normalized.contains('lpo') || normalized.contains('poid')) {
        hasLpoKey = true;
      }
      if (normalized.contains('rfq')) {
        hasRfqKey = true;
      }
      if (normalized.contains('invoice')) {
        hasInvoiceKey = true;
      }
      if (normalized.contains('hrrequest') ||
          normalized == 'requestid' ||
          normalized.contains('employee')) {
        hasHrKey = true;
      }
      if (normalized.contains('pettycash') || normalized.contains('expense')) {
        hasPettyKey = true;
      }
    }

    for (final candidate in candidates) {
      final normalized = _normalizeType(candidate);
      if (normalized.isEmpty ||
          normalized == 'notification' ||
          normalized == 'announcement' ||
          normalized == 'circular') {
        continue;
      }

      if (normalized.contains('rfq') || normalized == 'purchasequotation') {
        return 'rfq';
      }
      if (normalized.contains('invoice') ||
          normalized.contains('accountmove')) {
        return 'invoice';
      }
      if (normalized.contains('pettycash') ||
          normalized.contains('hrexpensesheet') ||
          normalized == 'expense' ||
          normalized.contains('expense')) {
        return 'pettycash';
      }
      if (normalized == 'hr' ||
          normalized.contains('hrrequest') ||
          normalized.contains('leaverequest') ||
          normalized.contains('employeerequest')) {
        return 'hr';
      }
      if (normalized.contains('lpo') ||
          normalized == 'po' ||
          normalized.contains('purchaseorder')) {
        return hasRfqKey ? 'rfq' : 'lpo';
      }
    }

    if (hasRfqKey) return 'rfq';
    if (hasInvoiceKey) return 'invoice';
    if (hasPettyKey) return 'pettycash';
    if (hasLpoKey) return 'lpo';
    if (hasHrKey) return 'hr';

    final text =
        '${item['title'] ?? ''} ${item['body'] ?? ''}'.toString().toLowerCase();
    if (text.contains('rfq')) return 'rfq';
    if (text.contains('invoice')) return 'invoice';
    if (text.contains('petty cash') || text.contains('expense')) {
      return 'pettycash';
    }
    if (text.contains('lpo') || text.contains('purchase order')) return 'lpo';
    if (text.contains('hr request') ||
        text.contains('leave request') ||
        text.contains('hr')) {
      return 'hr';
    }

    return '';
  }

  Future<bool> _openLinkedRecord(Map<String, dynamic> item) async {
    final data = _extractNotificationData(item);
    final recordId = _extractRecordId(item, data);
    final recordType = _resolveRecordType(item, data);

    debugPrint(
      'Notification redirect - type: $recordType, recordId: $recordId',
    );

    if (!mounted || recordId == null) return false;

    switch (recordType) {
      case 'hr':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HrDetailsScreen(
              requestId: '$recordId',
              type: 'HR',
            ),
          ),
        );
        return true;
      case 'rfq':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RfqDetailsScreen(
              requestId: '$recordId',
              type: 'RFQ',
            ),
          ),
        );
        return true;
      case 'invoice':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceDetailsScreen(
              requestId: '$recordId',
              type: 'INVOICE',
            ),
          ),
        );
        return true;
      case 'pettycash':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PettyCashDetailsScreen(
              requestId: '$recordId',
              type: 'PETTYCASH',
            ),
          ),
        );
        return true;
      case 'lpo':
        return Util.openLpoPdfReport(context, recordId);
      default:
        return false;
    }
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  void _scrollToTab(int index) {
    final context = _tabKeys[index].currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final screenWidth = MediaQuery.of(this.context).size.width;
      final tabWidth = box.size.width;

      // Calculate offset to center the tab
      final targetOffset = _scrollController.offset +
          position.dx -
          (screenWidth / 2) +
          (tabWidth / 2);

      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (notifications.isEmpty) return [];
    if (_notificationTabs.isEmpty || currentIndex >= _notificationTabs.length) {
      return notifications;
    }

    final selectedCategory = _notificationTabs[currentIndex].category;

    // Filter notifications by category
    return notifications.where((notification) {
      final notificationCategory =
          (notification['category'] ?? 'notification').toString().toLowerCase();
      return notificationCategory == selectedCategory.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
      },
      child: Scaffold(
          appBar: const HeaderWidget(),
          extendBody: false,
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: context.systemBottomInset + 16,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 55.w,
                                child: ListView.separated(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  controller: _scrollController,
                                  itemCount: _notificationTabs.length,
                                  physics: const BouncingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    final tab = _notificationTabs[index];
                                    final notificationIcon = tab.icon;
                                    final notificationTitle = tab.title;
                                    return InkWell(
                                      key: _tabKeys[index],
                                      onTap: () {
                                        setState(() => currentIndex = index);
                                        // Scroll to center the selected tab
                                        _scrollToTab(index);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        margin: const EdgeInsets.only(top: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        decoration: BoxDecoration(
                                          //  color: index==currentIndex ? appFontColor : Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          gradient: index == currentIndex
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color.fromARGB(
                                                        255, 27, 27, 27),
                                                    appFontColor,
                                                  ],
                                                  stops: [
                                                    0.01,
                                                    0.9,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                )
                                              : const LinearGradient(
                                                  colors: [
                                                    Color(0xffD6D6D6),
                                                    Color(0xffADB2BD),
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                        ),

                                        // child: Stack(
                                        //   children: [
                                        //     Column(
                                        //       crossAxisAlignment: CrossAxisAlignment.start,
                                        //       children: [
                                        //         // Row(
                                        //         //   mainAxisAlignment:
                                        //         //       MainAxisAlignment.spaceBetween,
                                        //         //   children: [
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              notificationIcon,
                                              height: 25.w,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              notificationTitle.toUpperCase(),
                                              style: GoogleFonts.koulen(
                                                color: index == currentIndex
                                                    ? Colors.white
                                                    : const Color(0xFF1A237E),
                                                fontSize: 20.sp,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Container(
                                        //   padding: const EdgeInsets.symmetric(
                                        //       horizontal: 8, vertical: 4),
                                        //   decoration: BoxDecoration(
                                        //     color: Colors.white,
                                        //     borderRadius:
                                        //         BorderRadius.circular(10),
                                        //   ),
                                        //   child: const Icon(
                                        //     Icons.arrow_forward,
                                        //     size: 16,
                                        //     color: Color(0xFF2D2F81),
                                        //   ),
                                        // ),
                                        //   ],
                                        // ),
                                        // const SizedBox(height: 6),
                                        // Text(
                                        //   translate(
                                        //       'notification_screen.stay_updated'),
                                        //   style: const TextStyle(
                                        //     color: Colors.black87,
                                        //     fontSize: 11,
                                        //     fontWeight: FontWeight.bold,
                                        //     height: 1.4,
                                        //   ),
                                        // ),
                                        //       ],
                                        //     ),
                                        //   ],
                                        // ),
                                      ),
                                    );
                                  },
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          const SizedBox(
                                    width: 10,
                                  ),
                                ),
                              ),
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.center,
                              //   children: List.generate(3, (dotIndex) {
                              //     return Container(
                              //       margin: const EdgeInsets.symmetric(horizontal: 4),
                              //       width: 8,
                              //       height: 8,
                              //       decoration: BoxDecoration(
                              //         shape: BoxShape.circle,
                              //         color: dotIndex == currentIndex ? Colors.black : Colors.grey[400],
                              //       ),
                              //     );
                              //   }),
                              // ),

                              const SizedBox(height: 20),

                              // Show different content based on selected tab
                              _buildContentForTab(),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
              // const ArraowVisibalityBottomNav(
              //   bottomMargin: 125,
              // ),
            ],
          )),
    );
  }

  /// Build content based on selected tab
  Widget _buildContentForTab() {
    if (_notificationTabs.isEmpty || currentIndex >= _notificationTabs.length) {
      return _buildLocalNotificationsList();
    }

    final selectedCategory = _notificationTabs[currentIndex].category;

    // Circulars and announcements are rendered from dedicated API payload.
    if (selectedCategory == 'announcement' || selectedCategory == 'circular') {
      return _buildApiDataList(selectedCategory);
    }

    // All dynamic categories are rendered from notification storage.
    return _buildLocalNotificationsList();
  }

  /// Build local notifications list (from storage)
  Widget _buildLocalNotificationsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredNotifications = _getFilteredNotifications();

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState('No notifications yet', Icons.notifications_none);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final item = filteredNotifications[index];
        final currentNotificationIcon = _notificationTabs.isNotEmpty &&
                currentIndex < _notificationTabs.length
            ? _notificationTabs[currentIndex].icon
            : 'assets/png/notification_icon.png';
        final notificationId = (item['id'] ?? '').toString();

        return Dismissible(
          key: ValueKey('notification-$notificationId-$index'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _dismissNotification(notificationId),
          background: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.delete_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          child: _buildNotificationItem(item, currentNotificationIcon),
        );
      },
    );
  }

  /// Build API data list (Announcements/Circulars)
  Widget _buildApiDataList(String category) {
    if (_isLoadingCircularAnnouncement) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_circularAnnouncementError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load data',
                style: GoogleFonts.koulen(
                    fontSize: 18.sp, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadCircularAnnouncements,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appFontColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<CircularAnnouncementItem> items;
    if (category == 'announcement') {
      items = _circularAnnouncementData?.announcements ?? [];
    } else {
      items = _circularAnnouncementData?.circulars ?? [];
    }

    if (items.isEmpty) {
      final emptyMessage = category == 'announcement'
          ? 'No announcements yet'
          : 'No circulars yet';
      return _buildEmptyState(
          emptyMessage,
          category == 'announcement'
              ? Icons.campaign_outlined
              : Icons.assignment_outlined);
    }

    final currentNotificationIcon =
        _notificationTabs.isNotEmpty && currentIndex < _notificationTabs.length
            ? _notificationTabs[currentIndex].icon
            : 'assets/png/notification_icon.png';

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCircularAnnouncementItem(item, currentNotificationIcon);
      },
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style:
                  GoogleFonts.koulen(fontSize: 18.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Build notification item from local storage
  Widget _buildNotificationItem(Map<String, dynamic> item, String icon) {
    final isRead = _isRead(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final notificationId = (item['id'] ?? '').toString();
            if (!isRead && notificationId.isNotEmpty) {
              await _markNotificationAsRead(notificationId);
              if (!mounted) return;
            }

            final openedRecord = await _openLinkedRecord(item);
            if (!mounted || openedRecord) return;

            _showAnnouncementDialog(
              context,
              item['title'] ?? 'Notification',
              item['body'] ?? '',
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/png/bg_petty.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).toInt()),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(icon, width: 25.w, height: 25.w),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['title'] != null)
                          Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.bold,
                              color: isRead
                                  ? const Color(0xFF5A5A5A)
                                  : appFontColor,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          item['body'] ?? '',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight:
                                isRead ? FontWeight.w400 : FontWeight.w500,
                            color: isRead ? Colors.black54 : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            _formatTime(item['timestamp'] ?? ''),
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Build circular/announcement item from API
  Widget _buildCircularAnnouncementItem(
      CircularAnnouncementItem item, String icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showCircularAnnouncementDialog(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/png/bg_petty.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).toInt()),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(icon, width: 25.w, height: 25.w),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary title from API payload
                      Text(
                        item.displayTitle,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (item.displayBody.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.displayBody,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      if (item.date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(item.date!),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // File indicator
                if (item.hasFile)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appFontColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _showCircularAnnouncementDialog(
      CircularAnnouncementItem item) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha((0.6 * 255).toInt()),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.75,
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
                if (item.date != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd/MM/yyyy').format(item.date!),
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      item.displayBody.isNotEmpty
                          ? item.displayBody
                          : item.displayTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: item.hasFile
                        ? () {
                            Navigator.pop(dialogContext);
                            _openCircularAnnouncementFile(item);
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: item.hasFile
                            ? const Color(0xFF0A1133)
                            : const Color(0xFFB9BFCC),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'VIEW ATTACHMENT',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 24.sp,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Open file for circular/announcement
  void _openCircularAnnouncementFile(CircularAnnouncementItem item) {
    if (!item.hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file attached to this item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CircularAnnouncementFileViewer(item: item),
      ),
    );
  }

  void _showAnnouncementDialog(
      BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha((0.6 * 255).toInt()),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      content,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // View Attachment Button
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'VIEW ATTACHMENT',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showBabyGirlPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha((0.5 * 255).toInt()),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white.withAlpha((0.95 * 255).toInt()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "🎉 Congratulations ✨",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "Congratulations to",
                  style: TextStyle(fontSize: 13, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  "Eng. Hassan Abuebied",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 14),
                Text(
                  "on the arrival of his baby girl! 🎀✨ Wishing her a life filled with love, joy, and endless blessings. May she bring happiness and prosperity to the family! 💖👶🏼",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
