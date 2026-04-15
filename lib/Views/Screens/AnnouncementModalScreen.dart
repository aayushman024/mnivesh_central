import 'package:flutter/material.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../Utils/Dimensions.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------
class Announcement {
  final String message;
  final String uploadedBy;
  final DateTime uploadedOn;
  final DateTime expiryDate;
  final AnnouncementPriority priority;

  Announcement({
    required this.message,
    required this.uploadedBy,
    required this.uploadedOn,
    required this.expiryDate,
    this.priority = AnnouncementPriority.normal,
  });

  bool get isUrgent => expiryDate.difference(DateTime.now()).inDays <= 2;
}

enum AnnouncementPriority { normal, high, critical }

// ---------------------------------------------------------------------------
// Priority helpers  (static, theme-independent accent colours)
// ---------------------------------------------------------------------------
extension _PriorityX on AnnouncementPriority {
  Color get accent => switch (this) {
    AnnouncementPriority.critical => const Color(0xFFE05C6A),
    AnnouncementPriority.high     => const Color(0xFFE8A045),
    AnnouncementPriority.normal   => const Color(0xFF3B82F6),
  };

  String get label => switch (this) {
    AnnouncementPriority.critical => 'CRITICAL',
    AnnouncementPriority.high     => 'HIGH',
    AnnouncementPriority.normal   => 'INFO',
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
      const Color(0xFF1A202C), // Blue tint
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
      const Color(0xFFF0F6FF), // Blue tint
      const Color(0xFFFCFCFD),
    ],
  };
}

// ---------------------------------------------------------------------------
// Sheet entry point
// ---------------------------------------------------------------------------
class AnnouncementModal extends StatefulWidget {
  const AnnouncementModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => const AnnouncementModal(),
    );
  }

  @override
  State<AnnouncementModal> createState() => _AnnouncementModalState();
}

class _AnnouncementModalState extends State<AnnouncementModal>
    with TickerProviderStateMixin {
  late final List<AnimationController> _cardCtrls;

  final List<Announcement> _items = [
    Announcement(
      message:
      'Quarterly compliance training is due. Please complete all mandatory modules before the deadline — failure to do so may affect your access.',
      uploadedBy: 'Ishika Raheja',
      uploadedOn: DateTime.now().subtract(const Duration(days: 1)),
      expiryDate: DateTime.now().add(const Duration(days: 5)),
      priority: AnnouncementPriority.high,
    ),
    Announcement(
      message:
      'Scheduled server maintenance this Saturday from 2:00 AM – 4:00 AM IST. Brief service interruptions are expected.',
      uploadedBy: 'Himanshu Singh Dhanik',
      uploadedOn: DateTime.now().subtract(const Duration(days: 2)),
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      priority: AnnouncementPriority.critical,
    ),
    Announcement(
      message:
      'New investment portfolios are now live for enterprise clients. Explore the updated catalog in the Portfolios section.',
      uploadedBy: 'Vilakshan Bhutani',
      uploadedOn: DateTime.now().subtract(const Duration(days: 4)),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      priority: AnnouncementPriority.normal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cardCtrls = List.generate(
      _items.length,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    for (var i = 0; i < _cardCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 160 + i * 100), () {
        if (mounted) _cardCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _cardCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => _SheetBody(
        scrollController: scrollController,
        items: _items,
        cardCtrls: _cardCtrls,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Announcement Dialog
// ---------------------------------------------------------------------------
void _openAddAnnouncementDialog(BuildContext context) {
  Navigator.pop(context);
  showDialog(
    context: context,
    builder: (context) => const _AddAnnouncementDialog(),
  );
}

class _AddAnnouncementDialog extends StatefulWidget {
  const _AddAnnouncementDialog({super.key});

  @override
  State<_AddAnnouncementDialog> createState() => _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends State<_AddAnnouncementDialog> {
  final _msgCtrl = TextEditingController();
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    // 1. pick date first
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      // 2. if date is selected, pick time
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          // combine date and time into a single DateTime
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              "New Announcement",
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
          // ── Message field ──────────────────────────────────────────
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: TextField(
              controller: _msgCtrl,
              maxLines: 6,
              minLines: 2,
              keyboardType: TextInputType.text,
              style: AppTextStyle.normal.normal(),
              decoration: InputDecoration(
                labelText: 'Announcement',
                alignLabelWithHint: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    width: 1,
                    color: colorScheme.outline.withAlpha(30),
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    width: 1,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30.sdp),

          // ── Priority selector ──────────────────────────────────────
          Text("Type", style: AppTextStyle.bold.normal()),
          SizedBox(height: 10.sdp),
          Wrap(
            spacing: 8.sdp,
            runSpacing: 8.sdp,
            children: AnnouncementPriority.values.map((p) {
              final isSelected = _priority == p;
              return GestureDetector(
                onTap: () => setState(() => _priority = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? p.accent : p.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? p.accent
                          : p.accent.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    p.label,
                    style: AppTextStyle.bold.custom(
                      12.ssp,
                      isSelected ? Colors.white : p.accent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 30.sdp),

          // ── Expiry date picker ─────────────────────────────────────
          Text("Expires On", style: AppTextStyle.bold.normal()),
          SizedBox(height: 10.sdp),
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
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
                  Text(
                    _expiryDate == null
                        ? "Select expiry date & time"
                        : "${_expiryDate!.day.toString().padLeft(2, '0')}/${_expiryDate!.month.toString().padLeft(2, '0')}/${_expiryDate!.year}, ${_expiryDate!.hour.toString().padLeft(2, '0')}:${_expiryDate!.minute.toString().padLeft(2, '0')}",
                    style: AppTextStyle.normal.custom(
                      14.ssp,
                      _expiryDate == null
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
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
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Discard",
            style: AppTextStyle.normal.normal(colorScheme.error),
          ),
        ),
        SizedBox(width: 12.sdp),
        ElevatedButton(
          onPressed: () {
            // stub - plug api hook here
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 8.sdp, horizontal: 40.sdp),
            backgroundColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Add",
            style: AppTextStyle.bold.normal(colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet body
// ---------------------------------------------------------------------------
class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.scrollController,
    required this.items,
    required this.cardCtrls,
  });

  final ScrollController scrollController;
  final List<Announcement> items;
  final List<AnimationController> cardCtrls;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Container(
              width: 40.sdp,
              height: 4.sdp,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'ANNOUNCEMENTS',
                  style: AppTextStyle.bold.normal(
                  ).copyWith(
                    letterSpacing: 1.5
                  ),
                ),
                const Spacer(),
                // Count badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.35),
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

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withOpacity(0.05),
          ),

          // ── Cards ──────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: cardCtrls[index],
                  builder: (context, child) {
                    final t = CurvedAnimation(
                      parent: cardCtrls[index],
                      curve: Curves.easeOutQuart,
                    );
                    return Opacity(
                      opacity: t.value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - t.value)),
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
            margin: EdgeInsets.symmetric(
              horizontal: 12.sdp,
              vertical: 15.sdp,
            ),
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () =>_openAddAnnouncementDialog(context),
              style: TextButton.styleFrom(
                elevation: 0,
                backgroundColor: colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 15.sdp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.sdp),
                ),
              ),
              icon: PhosphorIcon(PhosphorIcons.megaphone(PhosphorIconsStyle.bold),
              color: colorScheme.onPrimary,),
              label: Text(
                "Add New Announcement",
                style: AppTextStyle.bold.normal(colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------
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

  String _fmt(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
  }

  String get _expiryLabel {
    final days = item.expiryDate.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Expired';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    return 'Expires ${_fmt(item.expiryDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
    isDark ? item.priority.darkGradient : item.priority.lightGradient;
    final mutedColor = colorScheme.onSurface.withOpacity(0.42);

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
            color: accent.withOpacity(isDark ? 0.18 : 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(isDark ? 0.07 : 0.06),
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
              // ── Author row ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: accent.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Static priority dot — no animation on any priority
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
                            style: AppTextStyle.bold.custom(
                              13.5.ssp,
                              accent,
                            ),
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
                    _PriorityChip(priority: item.priority, accent: accent),
                  ],
                ),
              ),

              // ── Message ─────────────────────────────────────────────
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

              // ── Footer: expiry + expand toggle ───────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Expiry icon
                    Icon(
                      item.isUrgent
                          ? PhosphorIcons.warning(PhosphorIconsStyle.fill)
                          : PhosphorIcons.clockCounterClockwise(
                          PhosphorIconsStyle.regular),
                      size: 12,
                      color: item.isUrgent ? accent : mutedColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _expiryLabel,
                      style: AppTextStyle.bold.custom(
                        11.ssp,
                        item.isUrgent ? accent : mutedColor,
                      ),
                    ),
                    const Spacer(),
                    // "expand / collapse" hint + animated caret
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _expanded ? 'Collapse' : 'Expand',
                            style: AppTextStyle.normal.custom(
                              10.ssp,
                              mutedColor,
                            ),
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

// ---------------------------------------------------------------------------
// Priority chip
// ---------------------------------------------------------------------------
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
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accent.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: Text(
        priority.label,
        style: AppTextStyle.bold.custom(
          9.5.ssp,
          accent,
        ),
      ),
    );
  }
}