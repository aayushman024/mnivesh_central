import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/Models/announcement.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../Utils/Dimensions.dart';
import '../../ViewModels/announcement_viewModel.dart';

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
    super.key,
  });

  final List<Announcement> initialItems;

  static void show(
    BuildContext context, {
    required List<Announcement> initialItems,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => AnnouncementModal(initialItems: initialItems),
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
  final _msgCtrl = TextEditingController();
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
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
    final message = _msgCtrl.text.trim();
    if (message.isEmpty || _expiryDate == null) return;

    final created = await ref
        .read(announcementViewModelProvider.notifier)
        .createAnnouncement(
          message: message,
          priority: _priority,
          expiryDate: _expiryDate!,
        );

    if (created && mounted) {
      Navigator.pop(context);
      AnnouncementModal.show(
        context,
        initialItems: ref.read(announcementViewModelProvider).items,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(announcementViewModelProvider);
    final canSubmit = _msgCtrl.text.trim().isNotEmpty &&
        _expiryDate != null &&
        !state.isSubmitting;

    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.megaphoneSimple(PhosphorIconsStyle.bold),
            color: colorScheme.primary,
          ),
          SizedBox(width: 10.sdp),
          Expanded(
            child: Text(
              'New Announcement',
              style: AppTextStyle.bold.large(),
            ),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(30, 30, 30, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: TextField(
              controller: _msgCtrl,
              maxLines: 6,
              minLines: 2,
              keyboardType: TextInputType.text,
              onChanged: (_) => setState(() {}),
              style: AppTextStyle.normal.normal(),
              decoration: InputDecoration(
                labelText: 'Announcement',
                alignLabelWithHint: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    width: 1,
                    color: colorScheme.outline.withAlpha(30),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(width: 1),
                ),
              ),
            ),
          ),
          SizedBox(height: 30.sdp),
          Text('Type', style: AppTextStyle.bold.normal()),
          SizedBox(height: 10.sdp),
          Wrap(
            spacing: 8.sdp,
            runSpacing: 8.sdp,
            children: AnnouncementPriority.values.map((priority) {
              final isSelected = _priority == priority;
              return GestureDetector(
                onTap: () => setState(() => _priority = priority),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? priority.accent
                        : priority.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? priority.accent
                          : priority.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    priority.label,
                    style: AppTextStyle.bold.custom(
                      12.ssp,
                      isSelected ? Colors.white : priority.accent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 30.sdp),
          Text('Expires On', style: AppTextStyle.bold.normal()),
          SizedBox(height: 10.sdp),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.calendarBlank(),
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 10.sdp),
                  Expanded(
                    child: Text(
                      _expiryDate == null
                          ? 'Select expiry date & time'
                          : '${_expiryDate!.day.toString().padLeft(2, '0')}/${_expiryDate!.month.toString().padLeft(2, '0')}/${_expiryDate!.year}, ${_expiryDate!.hour.toString().padLeft(2, '0')}:${_expiryDate!.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyle.normal.custom(
                        14.ssp,
                        _expiryDate == null
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            'Discard',
            style: AppTextStyle.normal.normal(colorScheme.error),
          ),
        ),
        SizedBox(width: 12.sdp),
        ElevatedButton(
          onPressed: canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 8.sdp, horizontal: 40.sdp),
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: state.isSubmitting
              ? SizedBox(
                  width: 18.sdp,
                  height: 18.sdp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(
                  'Add',
                  style: AppTextStyle.bold.normal(colorScheme.onPrimary),
                ),
        ),
      ],
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.scrollController,
    required this.items,
    required this.isLoading,
  });

  final ScrollController scrollController;
  final List<Announcement> items;
  final bool isLoading;

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
                  'ANNOUNCEMENTS',
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
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _AnnouncementCard(item: items[index]),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 18.sdp, vertical: 15.sdp),
            width: double.infinity,
            child: TextButton.icon(
              // onPressed: () => _openAddAnnouncementDialog(context),
              onPressed: () => SnackbarService.showComingSoon(),
              style: TextButton.styleFrom(
                elevation: 0,
                backgroundColor: colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 15.sdp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.sdp),
                ),
              ),
              icon: PhosphorIcon(
                PhosphorIcons.megaphone(PhosphorIconsStyle.bold),
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
  const _AnnouncementCard({required this.item});

  final Announcement item;

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _expanded = false;

  Announcement get item => widget.item;
  Color get accent => item.priority.accent;

  String _fmt(DateTime value) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month]} ${value.year}';
  }

  String get _expiryLabel {
    if (item.expiryDate == null) return 'No expiry date';

    final days = item.expiryDate!.difference(DateTime.now()).inDays;
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    return 'Expires ${_fmt(item.expiryDate!)}';
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
                child: AnimatedCrossFade(
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      item.isUrgent
                          ? PhosphorIcons.warning(PhosphorIconsStyle.fill)
                          : PhosphorIcons.clockCounterClockwise(
                              PhosphorIconsStyle.regular,
                            ),
                      size: 12,
                      color: item.isUrgent ? accent : mutedColor,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _expiryLabel,
                        style: AppTextStyle.bold.custom(
                          11.ssp,
                          item.isUrgent ? accent : mutedColor,
                        ),
                      ),
                    ),
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
                              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
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
