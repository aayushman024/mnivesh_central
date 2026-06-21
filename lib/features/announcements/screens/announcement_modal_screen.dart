import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mnivesh_central/core/api/api_service.dart';
import 'package:mnivesh_central/features/announcements/models/announcement.dart';
import 'package:mnivesh_central/features/team_status/models/user_details_model.dart';
import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/announcements/view_models/announcement_view_model.dart';

extension _PriorityColorX on AnnouncementPriority {
  Color get accent => switch (this) {
        AnnouncementPriority.critical => const Color(0xFFE05C6A),
        AnnouncementPriority.high => const Color(0xFFE8A045),
        AnnouncementPriority.normal => const Color(0xFF3B82F6),
      };

  List<Color> get darkGradient => switch (this) {
        AnnouncementPriority.critical => [
            const Color(0xFF2A1A1C),
            const Color(0xFF1F2130),
          ],
        AnnouncementPriority.high => [
            const Color(0xFF221C10),
            const Color(0xFF1F2130),
          ],
        AnnouncementPriority.normal => [
            const Color(0xFF1A202C),
            const Color(0xFF1F2130),
          ],
      };

  List<Color> get lightGradient => switch (this) {
        AnnouncementPriority.critical => [
            const Color(0xFFFFF5F6),
            const Color(0xFFFCFCFD),
          ],
        AnnouncementPriority.high => [
            const Color(0xFFFFF8EE),
            const Color(0xFFFCFCFD),
          ],
        AnnouncementPriority.normal => [
            const Color(0xFFF0F6FF),
            const Color(0xFFFCFCFD),
          ],
      };
}

class AnnouncementModal extends ConsumerWidget {
  const AnnouncementModal({
    required this.initialItems,
    this.expandId,
    super.key,
  });

  final List<Announcement> initialItems;
  final String? expandId;

  static void show(
    BuildContext context, {
    required List<Announcement> initialItems,
    String? expandId,
  }) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(announcementViewModelProvider.notifier).fetchAnnouncements(
      forceRefresh: true,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => AnnouncementModal(
        initialItems: initialItems,
        expandId: expandId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(announcementViewModelProvider);
    final items = state.hasLoadedOnce ? state.items : initialItems;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => _SheetBody(
        scrollController: scrollController,
        items: items,
        isLoading: state.isLoading && items.isEmpty,
        expandId: expandId,
      ),
    );
  }
}

void _openAddAnnouncementDialog(BuildContext context) {
  Navigator.pop(context);
  showDialog(
    context: context,
    builder: (context) => const _AddAnnouncementDialog(),
  );
}

class _AddAnnouncementDialog extends ConsumerStatefulWidget {
  const _AddAnnouncementDialog();

  @override
  ConsumerState<_AddAnnouncementDialog> createState() =>
      _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState
    extends ConsumerState<_AddAnnouncementDialog> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  DateTime? _expiryDate;
  bool _isRecipientsLoading = true;
  final List<UserDetail> _users = [];
  final Set<String> _departmentOptions = {'all_users'};
  final Set<String> _selectedDepartments = {'all_users'};
  final Set<String> _selectedEmails = {};

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    setState(() => _isRecipientsLoading = true);
    try {
      final users = await ApiService.getUserDetails();
      if (!mounted) return;
      _users
        ..clear()
        ..addAll(users);
      for (final user in users) {
        final dept = user.department.trim().toLowerCase();
        if (dept.isNotEmpty && dept != 'n/a') {
          _departmentOptions.add(dept);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load users/departments')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRecipientsLoading = false);
    }
  }

  Future<void> _openMultiSelect({
    required String title,
    required Set<String> allOptions,
    required Set<String> selected,
    required IconData icon,
    bool isUser = false,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        String query = '';
        final temp = {...selected};
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = allOptions
                .where((e) => e.toLowerCase().contains(query.toLowerCase()))
                .toList()
              ..sort();
            final selCount = temp.length;
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.78,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Handle bar ──
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 6),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(icon, size: 20, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTextStyle.bold.custom(17.ssp, colorScheme.onSurface)),
                              if (selCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '$selCount selected',
                                    style: AppTextStyle.normal.custom(11.ssp, colorScheme.primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(PhosphorIconsBold.x, size: 18, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Search ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchCtrl,
                      style: AppTextStyle.normal.custom(14.ssp, colorScheme.onSurface),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 8),
                          child: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20, color: colorScheme.onSurfaceVariant),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: isUser ? 'Search by name or email…' : 'Search departments…',
                        hintStyle: AppTextStyle.normal.custom(13.ssp, colorScheme.onSurfaceVariant.withValues(alpha: 0.55)),
                        filled: true,
                        fillColor: isDark
                            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: isDark ? 0.18 : 0.14),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) => setModalState(() => query = v),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── List ──
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, ignored) => Divider(
                        height: 1, indent: 52,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.12),
                      ),
                      itemBuilder: (_, index) {
                        final option = filtered[index];
                        final checked = temp.contains(option);

                        Widget titleWidget;
                        if (isUser && option.contains('<') && option.contains('>')) {
                          final name = option.split('<')[0].trim();
                          final email = option.split('<')[1].replaceAll('>', '').trim();
                          titleWidget = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTextStyle.bold.custom(14.ssp, colorScheme.onSurface)),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(email, style: AppTextStyle.normal.custom(10.ssp, colorScheme.primary)),
                              ),
                            ],
                          );
                        } else {
                          titleWidget = Text(
                            isUser ? option : option.toUpperCase(),
                            style: AppTextStyle.bold.custom(14.ssp, colorScheme.onSurface),
                          );
                        }

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setModalState(() {
                              checked ? temp.remove(option) : temp.add(option);
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: checked ? colorScheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: checked ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: checked
                                        ? Icon(Icons.check_rounded, size: 16, color: colorScheme.onPrimary)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: titleWidget),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // ── Bottom actions ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.12))),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setModalState(() => temp.clear()),
                              icon: Icon(PhosphorIconsBold.eraser, size: 16),
                              label: Text('Clear All', style: AppTextStyle.bold.custom(13.ssp, colorScheme.onSurface)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(ctx, temp),
                              icon: Icon(PhosphorIconsBold.checkCircle, size: 16, color: colorScheme.onPrimary),
                              label: Text('Apply', style: AppTextStyle.bold.custom(13.ssp, colorScheme.onPrimary)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        selected
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _expiryDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    final selectedEmailValues = _selectedEmails
        .map(_extractEmail)
        .where((email) => email.isNotEmpty)
        .toList();
    final created = await ref
        .read(announcementViewModelProvider.notifier)
        .submitAnnouncement(
          title: _titleCtrl.text,
          message: _msgCtrl.text,
          priority: _priority,
          expiryDate: _expiryDate,
          selectedDepartments: _selectedDepartments.toList(),
          selectedEmails: selectedEmailValues,
        );

    if (created && mounted) {
      Navigator.pop(context);
      AnnouncementModal.show(
        context,
        initialItems: ref.read(announcementViewModelProvider).items,
      );
    }
  }

  String _extractEmail(String value) {
    final start = value.indexOf('<');
    final end = value.indexOf('>');
    if (start >= 0 && end > start) {
      return value.substring(start + 1, end).trim();
    }
    return value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(announcementViewModelProvider);
    final selectedEmailValues = _selectedEmails
        .map(_extractEmail)
        .where((email) => email.isNotEmpty)
        .toList();
    final canSubmit = ref
        .read(announcementViewModelProvider.notifier)
        .canSubmitAnnouncement(
          title: _titleCtrl.text,
          message: _msgCtrl.text,
          expiryDate: _expiryDate,
          selectedDepartments: _selectedDepartments.toList(),
          selectedEmails: selectedEmailValues,
        );

    // ── Shared input decoration ──
    InputDecoration inputDeco({
      required String label,
      required IconData icon,
      bool alignHint = false,
    }) =>
        InputDecoration(
          labelText: label,
          labelStyle: AppTextStyle.normal.custom(14.ssp, colorScheme.onSurfaceVariant),
          alignLabelWithHint: alignHint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              width: 1,
              color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.12),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        );

    // ── Section header builder ──
    Widget sectionHeader(String label, IconData icon) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyle.bold.custom(13.ssp, colorScheme.onSurface),
              ),
            ],
          ),
        );

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      surfaceTintColor: Colors.transparent,
      backgroundColor: colorScheme.surface,
      // ── Title ──
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PhosphorIconsFill.megaphoneSimple,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          SizedBox(width: 12.sdp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Announcement', style: AppTextStyle.bold.custom(18.ssp, colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  'Broadcast to your team',
                  style: AppTextStyle.normal.custom(11.ssp, colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: state.isSubmitting ? null : () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIconsBold.x,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      // ── Content ──
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: math.min(MediaQuery.of(context).size.width * 0.92, 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title input ──
            TextField(
              controller: _titleCtrl,
              maxLines: 1,
              keyboardType: TextInputType.text,
              onChanged: (_) => setState(() {}),
              style: AppTextStyle.normal.custom(14.ssp, colorScheme.onSurface),
              decoration: inputDeco(
                label: 'Announcement Title',
                icon: PhosphorIconsBold.textT,
              ),
            ),
            SizedBox(height: 14.sdp),
            // ── Message input ──
            TextField(
              controller: _msgCtrl,
              maxLines: 5,
              minLines: 2,
              keyboardType: TextInputType.text,
              onChanged: (_) => setState(() {}),
              style: AppTextStyle.normal.custom(14.ssp, colorScheme.onSurface),
              decoration: inputDeco(
                label: 'Message Body',
                icon: PhosphorIconsBold.chatText,
                alignHint: true,
              ),
            ),

            // ── Divider ──
            Padding(
              padding: EdgeInsets.symmetric(vertical: 18.sdp),
              child: Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.12)),
            ),

            // ── Recipients section ──
            sectionHeader('RECIPIENTS', PhosphorIconsFill.usersThree),
            if (_isRecipientsLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(minHeight: 3),
                ),
              )
            else ...[
              _MultiSelectField(
                label: 'Departments',
                icon: PhosphorIconsBold.buildings,
                selectedItems: _selectedDepartments,
                onTap: () => _openMultiSelect(
                  title: 'Select Departments',
                  allOptions: _departmentOptions,
                  selected: _selectedDepartments,
                  icon: PhosphorIconsFill.buildings,
                ),
                onRemove: (item) => setState(() => _selectedDepartments.remove(item)),
              ),
              SizedBox(height: 14.sdp),
              _MultiSelectField(
                label: 'Individual Users',
                icon: PhosphorIconsBold.userCircle,
                selectedItems: _selectedEmails,
                isUser: true,
                onTap: () => _openMultiSelect(
                  title: 'Select Users',
                  allOptions: _users
                      .map((u) => '${u.username} <${u.email}>')
                      .toSet(),
                  selected: _selectedEmails,
                  isUser: true,
                  icon: PhosphorIconsFill.userCircle,
                ),
                onRemove: (item) => setState(() => _selectedEmails.remove(item)),
              ),
            ],

            // ── Divider ──
            Padding(
              padding: EdgeInsets.symmetric(vertical: 18.sdp),
              child: Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.12)),
            ),

            // ── Priority ──
            sectionHeader('TYPE', PhosphorIconsFill.flag),
            Wrap(
              spacing: 8.sdp,
              runSpacing: 8.sdp,
              children: AnnouncementPriority.values.map((priority) {
                final isSelected = _priority == priority;
                final IconData pIcon = switch (priority) {
                  AnnouncementPriority.critical => PhosphorIconsFill.warning,
                  AnnouncementPriority.high => PhosphorIconsBold.arrowUp,
                  AnnouncementPriority.normal => PhosphorIconsFill.info,
                };
                return GestureDetector(
                  onTap: () => setState(() => _priority = priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? priority.accent
                          : priority.accent.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? priority.accent
                            : priority.accent.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: priority.accent.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(pIcon, size: 14, color: isSelected ? Colors.white : priority.accent),
                        const SizedBox(width: 6),
                        Text(
                          priority.label,
                          style: AppTextStyle.bold.custom(
                            11.ssp,
                            isSelected ? Colors.white : priority.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 24.sdp),

            // ── Expiry ──
            sectionHeader('EXPIRES IN', PhosphorIconsFill.clock),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.12),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: isDark ? 0.08 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsBold.calendarBlank,
                      size: 20,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 10.sdp),
                    Expanded(
                      child: Text(
                        _expiryDate == null
                            ? 'Optional — defaults to 1 day from now'
                            : '${_expiryDate!.day.toString().padLeft(2, '0')}/${_expiryDate!.month.toString().padLeft(2, '0')}/${_expiryDate!.year}  •  ${_expiryDate!.hour.toString().padLeft(2, '0')}:${_expiryDate!.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyle.normal.custom(
                          13.ssp,
                          _expiryDate == null
                              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (_expiryDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: Icon(
                          PhosphorIconsFill.xCircle,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 18.sdp),

            // ── Disclaimer ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.primaryContainer.withValues(alpha: 0.12)
                    : colorScheme.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    PhosphorIconsFill.lightbulb,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyle.normal.custom(11.ssp, colorScheme.onSurfaceVariant),
                        children: [
                          const TextSpan(text: 'This will send a notification to all selected recipients. Select '),
                          TextSpan(
                            text: 'ALL USERS',
                            style: AppTextStyle.bold.custom(11.ssp, colorScheme.primary),
                          ),
                          const TextSpan(text: ' in department field to broadcast to everyone.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.sdp),
          ],
        ),
      ),
      // ── Actions ──
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
                icon: Icon(
                  PhosphorIconsBold.trash,
                  size: 16,
                  color: state.isSubmitting ? colorScheme.onSurfaceVariant : colorScheme.error,
                ),
                label: Text(
                  'Discard',
                  style: AppTextStyle.bold.custom(
                    13.ssp,
                    state.isSubmitting ? colorScheme.onSurfaceVariant : colorScheme.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(
                    color: (state.isSubmitting ? colorScheme.onSurfaceVariant : colorScheme.error)
                        .withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: state.isSubmitting
                    ? SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                      )
                    : Icon(
                        PhosphorIconsFill.paperPlaneTilt,
                        size: 16,
                        color: canSubmit ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                label: Text(
                  'Publish',
                  style: AppTextStyle.bold.custom(
                    13.ssp,
                    canSubmit ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MultiSelectField extends StatelessWidget {
  const _MultiSelectField({
    required this.label,
    required this.icon,
    required this.selectedItems,
    required this.onTap,
    required this.onRemove,
    this.isUser = false,
  });

  final String label;
  final IconData icon;
  final Set<String> selectedItems;
  final VoidCallback onTap;
  final void Function(String) onRemove;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmpty = selectedItems.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyle.bold.custom(13.ssp, colorScheme.onSurface)),
            const Spacer(),
            if (!isEmpty)
              GestureDetector(
                onTap: onTap,
                child: Text(
                  '+ Add more',
                  style: AppTextStyle.normal.custom(11.ssp, colorScheme.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Container
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border.all(
                color: isEmpty
                    ? colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.12)
                    : colorScheme.primary.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isEmpty
                ? Row(
                    children: [
                      Icon(
                        PhosphorIconsBold.plus,
                        size: 15,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to select users',
                        style: AppTextStyle.normal.custom(
                          13.ssp,
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedItems.map((item) {
                      if (isUser && item.contains('<') && item.contains('>')) {
                        final name = item.split('<')[0].trim();
                        final email = item.split('<')[1].replaceAll('>', '').trim();
                        return _UserPill(
                          name: name,
                          email: email,
                          onRemove: () => onRemove(item),
                          colorScheme: colorScheme,
                          isDark: isDark,
                        );
                      } else {
                        return _DeptPill(
                          label: item.toUpperCase(),
                          onRemove: () => onRemove(item),
                          colorScheme: colorScheme,
                          isDark: isDark,
                        );
                      }
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

// User pill
class _UserPill extends StatelessWidget {
  const _UserPill({
    required this.name,
    required this.email,
    required this.onRemove,
    required this.colorScheme,
    required this.isDark,
  });

  final String name;
  final String email;
  final VoidCallback onRemove;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsFill.userCircle,
            size: 14,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyle.bold.custom(11.ssp, colorScheme.onSurface)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  email,
                  style: AppTextStyle.normal.custom(9.ssp, colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                PhosphorIconsBold.x,
                size: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Department pill
class _DeptPill extends StatelessWidget {
  const _DeptPill({
    required this.label,
    required this.onRemove,
    required this.colorScheme,
    required this.isDark,
  });

  final String label;
  final VoidCallback onRemove;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.secondary.withValues(alpha: 0.12)
            : colorScheme.secondary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsFill.buildings,
            size: 12,
            color: colorScheme.secondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyle.bold.custom(10.ssp, colorScheme.onSurface),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                PhosphorIconsBold.x,
                size: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.scrollController,
    required this.items,
    required this.isLoading,
    this.expandId,
  });

  final ScrollController scrollController;
  final List<Announcement> items;
  final bool isLoading;
  final String? expandId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Container(
              width: 40.sdp,
              height: 4.sdp,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Row(
              children: [
                Text(
                  'NOTIFICATIONS',
                  style: AppTextStyle.bold.normal().copyWith(letterSpacing: 1.5),
                ),
                const Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${items.length}',
                      style: AppTextStyle.bold.custom(
                        14.ssp,
                        colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.05),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Text(
                          'No announcements yet.',
                          style: AppTextStyle.normal.normal(
                            colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(items[index].id.isEmpty
                                ? '${items[index].uploadedOn.microsecondsSinceEpoch}-$index'
                                : items[index].id),
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 260 + (index * 60)),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 24 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _AnnouncementCard(
                                item: items[index],
                                initiallyExpanded: items[index].id == expandId,
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 18.sdp, vertical: 15.sdp),
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _openAddAnnouncementDialog(context),
              // onPressed: () => SnackbarService.showComingSoon(),
              style: TextButton.styleFrom(
                elevation: 0,
                backgroundColor: colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 15.sdp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.sdp),
                ),
              ),
              icon: Icon(
                PhosphorIconsBold.megaphone,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Add New Announcement',
                style: AppTextStyle.bold.normal(colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatefulWidget {
  const _AnnouncementCard({
    required this.item,
    this.initiallyExpanded = false,
  });

  final Announcement item;
  final bool initiallyExpanded;

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  late bool _expanded = widget.initiallyExpanded;

  Announcement get item => widget.item;
  Color get accent => item.priority.accent;

  String _fmt(DateTime value) {
    return DateFormat('hh:mm a, dd MMMM yyyy').format(value);
  }

  String _fmtTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get _expiryLabel {
    if (item.expiryDate == null) return 'No expiry date';

    final now = DateTime.now();
    final difference = item.expiryDate!.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (hours > 0) {
        return 'Expires in $hours ${hours == 1 ? 'hour' : 'hours'} (${_fmtTime(item.expiryDate!)})';
      } else {
        final minutes = difference.inMinutes;
        return 'Expires in $minutes ${minutes == 1 ? 'minute' : 'minutes'} (${_fmtTime(item.expiryDate!)})';
      }
    }

    return 'Expires ${_fmt(item.expiryDate!)} at ${_fmtTime(item.expiryDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
        isDark ? item.priority.darkGradient : item.priority.lightGradient;
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.42);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.07 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: accent.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.uploadedBy,
                            style: AppTextStyle.bold.custom(13.5.ssp, accent),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmt(item.uploadedOn),
                            style: AppTextStyle.normal.custom(
                              10.5.ssp,
                              mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.isNew)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 10.sdp),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'NEW',
                          style: AppTextStyle.bold.custom(9.5.ssp, Colors.blue),
                        ),
                      ),
                    _PriorityChip(priority: item.priority, accent: accent),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          item.title,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.bold.custom(
                            14.ssp,
                            colorScheme.onSurface,
                          ),
                        ),
                      ),
                    AnimatedCrossFade(
                      firstChild: Text(
                        item.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.normal.custom(
                          14.ssp,
                          colorScheme.onSurface,
                        ),
                      ),
                      secondChild: Text(
                        item.message,
                        style: AppTextStyle.normal.custom(
                          14.ssp,
                          colorScheme.onSurface,
                        ),
                      ),
                      crossFadeState: _expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    if (_expanded) ...[
                      Icon(
                        item.isUrgent
                            ? PhosphorIconsFill.warning
                            : PhosphorIconsRegular.clockCounterClockwise,
                        size: 12,
                        color: item.isUrgent
                            ? accent.withValues(alpha: 0.6)
                            : colorScheme.onSurface.withValues(alpha: 0.38),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _expiryLabel,
                          style: AppTextStyle.normal.custom(
                            11.ssp,
                            item.isUrgent
                                ? accent.withValues(alpha: 0.6)
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expanded ? 'Collapse' : 'Expand',
                            style: AppTextStyle.normal.custom(10.ssp, mutedColor),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              PhosphorIconsBold.caretDown,
                              size: 13,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.accent,
  });

  final AnnouncementPriority priority;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Text(
        priority.label,
        style: AppTextStyle.bold.custom(9.5.ssp, accent),
      ),
    );
  }
}
