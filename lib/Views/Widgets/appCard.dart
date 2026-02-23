import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Models/appModel.dart';
import '../../Providers/download_state_provider.dart';
import '../../Themes/AppTextStyle.dart';
import 'download_button.dart';

class AppInfoCardUI extends StatefulWidget {
  final AppModel app;
  final bool isChecking;
  final bool isInstalled;
  final bool updateAvailable;
  final bool isActive;
  final String? installedVersion;
  final DownloadState? downloadState;

  final VoidCallback onDownload;
  final VoidCallback onCancelDownload;
  final VoidCallback onUninstall;
  final VoidCallback onOpenApp;

  const AppInfoCardUI({
    super.key,
    required this.app,
    required this.isChecking,
    required this.isInstalled,
    required this.updateAvailable,
    this.isActive = false,
    this.installedVersion,
    this.downloadState,
    required this.onDownload,
    required this.onCancelDownload,
    required this.onUninstall,
    required this.onOpenApp,
  });

  @override
  State<AppInfoCardUI> createState() => _AppInfoCardUIState();
}

class _AppInfoCardUIState extends State<AppInfoCardUI> {
  Color get activeColor {
    final Map<String, Color> colorMap = {
      'red': const Color(0xFFE57373),
      'yellow': const Color(0xFFFFE082),
      'green': const Color(0xFF81C784),
      'blue': const Color(0xFF64B5F6),
      'violet': const Color(0xFF9575CD),
      'magenta': const Color(0xFFCE93D8),
      'teal': const Color(0xFF4DB6AC),
      'cyan': const Color(0xFF4DD0E1),
      'orange': const Color(0xFFFFB74D),
      'amber': const Color(0xFFFFD54F),
      'indigo': const Color(0xFF7986CB),
      'pink': const Color(0xFFF06292),
      'lime': const Color(0xFFDCE775),
      'deepPurple': const Color(0xFF9575CD),
    };
    return colorMap[widget.app.colorKey.toLowerCase()] ?? colorMap['violet']!;
  }

  String _parseHtmlForPreview(String htmlString) {
    var text = htmlString.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'</p>'), '\n\n');
    text = text.replaceAll(RegExp(r'</li>'), '\n');
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return text.trim();
  }

  void _openExpandedView(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          // EDIT: Removed FadeTransition here.
          // We pass 'animation' directly to the widget.
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: FadeTransition(
                    // Fade ONLY the backdrop shadow
                    opacity: animation,
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 90,
                  ),
                  child: _ExpandedCardContent(
                    parentWidget: widget,
                    activeColor: activeColor,
                    animation: animation, // <--- ADD THIS PARAMETER
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _flightShuttleBuilder(
      BuildContext flightContext,
      Animation<double> animation,
      HeroFlightDirection flightDirection,
      BuildContext fromHeroContext,
      BuildContext toHeroContext,
      ) {
    final Hero toHero = toHeroContext.widget as Hero;
    return Material(type: MaterialType.transparency, child: toHero.child);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Base Background
    final Color baseBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    // Dynamic Button Background
    final Color darkButtonBg = isDark
        ? Color.alphaBlend(activeColor.withOpacity(0.1), const Color(0xFF151520))
        : Color.alphaBlend(activeColor.withOpacity(0.1), const Color(0xFFF0F0F3));

    final Color cardBgColor = Color.alphaBlend(
      activeColor.withOpacity(0.04),
      baseBg,
    );

    // Dynamic Text Content Color
    final Color lightContentColor = isDark
        ? Color.lerp(activeColor, Colors.white, 0.85)!
        : Color.lerp(activeColor, Colors.black, 1)!;

    final TextStyle descStyle = AppTextStyle.light.normal(
        isDark ? Colors.grey[300]! : Colors.black!
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          // 1. BACKGROUND HERO
          // This stays "behind" the text but morphs during navigation
          Positioned.fill(
            child: Hero(
              tag: '${widget.app.packageName}_bg',
              child: Material(
                color: cardBgColor,
                elevation: 4, // Matches default Card elevation
                shadowColor: isDark ? activeColor.withOpacity(0.2) : Colors.black38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: activeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                type: MaterialType.card,
              ),
            ),
          ),

          // 2. CONTENT LAYER
          // Wrapped in Material(transparency) to ensure Text/HTML styles look correct
          Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Hero
                      Hero(
                        tag: '${widget.app.packageName}_icon',
                        flightShuttleBuilder: _flightShuttleBuilder,
                        child: SizedBox(
                          height: 50,
                          width: 50,
                          child: CachedNetworkImage(
                            imageUrl: widget.app.icon,
                            memCacheHeight: 150,
                            memCacheWidth: 150,
                            placeholder: (context, url) =>
                                Container(color: isDark ? Colors.white10 : Colors.black12),
                            errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Hero
                            Hero(
                              tag: '${widget.app.packageName}_name',
                              flightShuttleBuilder: _flightShuttleBuilder,
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  widget.app.appName,
                                  style: AppTextStyle.bold.large(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Version Pill Hero
                            Hero(
                              tag: '${widget.app.packageName}_version',
                              flightShuttleBuilder: _flightShuttleBuilder,
                              child: Material(
                                type: MaterialType.transparency,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _VersionPill(
                                      label: "v${widget.app.version}",
                                      color: activeColor.withOpacity(0.15),
                                      border: activeColor.withOpacity(0.4),
                                      textColor: activeColor, // Intentionally kept colored
                                      icon: Icons.grid_view_rounded,
                                    ),
                                    if (widget.updateAvailable &&
                                        widget.installedVersion != null)
                                      _VersionPill(
                                        label:
                                        "Installed v${widget.installedVersion}",
                                        color: Colors.amber.withOpacity(0.1),
                                        border: Colors.amber.withOpacity(0.4),
                                        textColor: Colors.amber,
                                        icon: Icons.warning_amber_outlined,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _openExpandedView(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.updateAvailable
                                          ? "What's New"
                                          : "See Details",
                                      style: AppTextStyle.bold
                                          .small(activeColor)
                                          .copyWith(
                                        decoration:
                                        TextDecoration.underline,
                                        decorationColor: activeColor
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
                                      color: activeColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isInstalled)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          color: isDark ? const Color(0xFF2C2C35) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                            ),
                          ),
                          onSelected: (value) {
                            if (value == 'uninstall') widget.onUninstall();
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'uninstall',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  Text(
                                    '  Uninstall ${widget.app.appName}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
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
                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: () => _openExpandedView(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _parseHtmlForPreview(widget.app.description),
                        style: descStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _ActionButtons(
                      widget: widget,
                      activeColor: activeColor,
                      bg: darkButtonBg,
                      fg: lightContentColor,
                      packageName: widget.app.packageName,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedCardContent extends StatelessWidget {
  final AppInfoCardUI parentWidget;
  final Color activeColor;
  final Animation<double> animation;

  const _ExpandedCardContent({
    required this.parentWidget,
    required this.activeColor,
    required this.animation,
  });

  Widget _flightShuttleBuilder(
      BuildContext flightContext,
      Animation<double> animation,
      HeroFlightDirection flightDirection,
      BuildContext fromHeroContext,
      BuildContext toHeroContext,
      ) {
    final Hero toHero = toHeroContext.widget as Hero;
    return Material(type: MaterialType.transparency, child: toHero.child);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color baseBg = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final Color cardBgColor = Color.alphaBlend(
      activeColor.withOpacity(0.04),
      baseBg,
    );
    final Color darkButtonBg = isDark
        ? Color.alphaBlend(activeColor.withOpacity(0.1), const Color(0xFF151520))
        : Color.alphaBlend(activeColor.withOpacity(0.1), Colors.grey.shade100);

    final Color lightContentColor = isDark
        ? Color.lerp(activeColor, Colors.white, 0.85)!
        : Color.lerp(activeColor, Colors.black, 0.85)!;

    return Stack(
      children: [
        // --- LAYER 1: Background Hero ---
        // DO NOT WRAP THIS IN FADE TRANSITION
        // This ensures the box is solid immediately and flies smoothly.
        Positioned.fill(
          child: Hero(
            tag: '${parentWidget.app.packageName}_bg',
            child: Material(
              color: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: activeColor.withOpacity(0.3), width: 1),
              ),
              elevation: 20,
              shadowColor: Colors.black.withOpacity(0.4),
              type: MaterialType.card,
            ),
          ),
        ),

        // --- LAYER 2: Content ---
        // WRAP THIS IN FADE TRANSITION
        // This makes the text fade in smoothly WHILE the box expands.
        FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            // Delay slightly so text doesn't overflow while box is tiny
            curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Hero(
                            tag: '${parentWidget.app.packageName}_name',
                            flightShuttleBuilder: _flightShuttleBuilder,
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                parentWidget.app.appName,
                                style: AppTextStyle.bold.large().copyWith(
                                  fontSize: 26,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 30),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Hero(
                                tag: '${parentWidget.app.packageName}_icon',
                                flightShuttleBuilder: _flightShuttleBuilder,
                                child: SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: CachedNetworkImage(
                                    imageUrl: parentWidget.app.icon,
                                    memCacheHeight: 150,
                                    memCacheWidth: 150,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag:
                                    '${parentWidget.app.packageName}_version',
                                    flightShuttleBuilder: _flightShuttleBuilder,
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _VersionPill(
                                            label:
                                            "v${parentWidget.app.version}",
                                            color: activeColor.withOpacity(
                                              0.15,
                                            ),
                                            border: activeColor.withOpacity(
                                              0.4,
                                            ),
                                            textColor: activeColor,
                                            icon: Icons.grid_view_rounded,
                                          ),
                                          if (parentWidget.updateAvailable &&
                                              parentWidget.installedVersion !=
                                                  null)
                                            _VersionPill(
                                              label:
                                              "Installed v${parentWidget.installedVersion}",
                                              color: Colors.amber.withOpacity(
                                                0.1,
                                              ),
                                              border: Colors.amber.withOpacity(
                                                0.4,
                                              ),
                                              textColor: Colors.amber,
                                              icon:
                                              Icons.warning_amber_outlined,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  if (!parentWidget.isInstalled)
                                    Text(
                                      "Not Installed",
                                      style: AppTextStyle.light.small(
                                        Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (parentWidget.app.changelog != null &&
                              parentWidget.app.changelog!.isNotEmpty) ...[
                            Text(
                              "What's New",
                              style: AppTextStyle.bold.large(activeColor),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                18,
                                18,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: activeColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: activeColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: HtmlWidget(
                                parentWidget.app.changelog!,
                                textStyle: AppTextStyle.light.normal(
                                  isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          Text(
                            "About this App",
                            style: AppTextStyle.bold.large(activeColor),
                          ),
                          const SizedBox(height: 12),

                          HtmlWidget(
                            parentWidget.app.description,
                            textStyle: AppTextStyle.light
                                .normal(isDark ? Colors.grey[300]! : Colors.grey[800]!)
                                .copyWith(height: 1.6, fontSize: 15),
                            customStylesBuilder: (element) {
                              if (element.localName == 'strong' ||
                                  element.localName == 'b') {
                                return {
                                  'color': isDark ? 'white' : 'black',
                                  'font-weight': 'bold',
                                };
                              }
                              if (element.localName == 'h1' ||
                                  element.localName == 'h2') {
                                return {
                                  'color': isDark ? 'white' : 'black',
                                  'margin-bottom': '10px',
                                };
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _ActionButtons(
                        widget: parentWidget,
                        activeColor: activeColor,
                        bg: darkButtonBg,
                        fg: lightContentColor,
                        packageName: parentWidget.app.packageName,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// HELPER WIDGETS
// ---------------------------------------------------------------------------

class _VersionPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color border;
  final Color textColor;
  final IconData icon;

  const _VersionPill({
    required this.label,
    required this.color,
    required this.border,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyle.bold.small(textColor)),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AppInfoCardUI widget;
  final Color activeColor;
  final Color bg;
  final Color fg;
  final String packageName;

  const _ActionButtons({
    required this.widget,
    required this.activeColor,
    required this.bg,
    required this.fg,
    required this.packageName,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildMainBtn() {
      if (Platform.isIOS) {
        return _Button(
          icon: Icons.android_rounded,
          label: "Available on Android",
          onTap: () {}, // Disabled for iOS
          bg: Colors.grey.withOpacity(0.1),
          fg: Colors.grey,
          activeColor: Colors.grey.withOpacity(0.2),
        );
      }
      if (!widget.isActive) {
        return _Button(
          icon: Icons.block_rounded,
          label: "Unavailable",
          onTap: () {}, // Dead click, does nothing
          bg: Colors.grey.withOpacity(0.1), // dull bg
          fg: Colors.grey, // dull text
          activeColor: Colors.grey.withOpacity(0.2), // dull border
        );
      }
      if (widget.isChecking) {
        return Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          ),
        );
      }
      if (widget.downloadState != null && widget.downloadState!.isDownloading) {
        return DownloadButton(
          activeColor: activeColor,
          bg: bg,
          fg: fg,
          progress: widget.downloadState!.progress,
          onCancel: widget.onCancelDownload,
        );
      }
      if (widget.isInstalled) {
        return widget.updateAvailable
            ? _Button(
          icon: Icons.system_update,
          label: "Update",
          onTap: widget.onDownload,
          bg: bg,
          fg: fg,
          activeColor: activeColor,
        )
            : _Button(
          icon: Icons.check_circle,
          label: "Installed",
          onTap: widget.onOpenApp,
          bg: bg,
          fg: fg,
          activeColor: activeColor,
        );
      }
      return _Button(
        icon: Icons.download_rounded,
        label: "Download Now",
        onTap: widget.onDownload,
        bg: bg,
        fg: fg,
        activeColor: activeColor,
      );
    }

    return Row(
      children: [
        Expanded(
          // Main Button Hero
          child: Hero(
            tag: '${packageName}_btn_main',
            child: Material(
              type: MaterialType.transparency,
              child: buildMainBtn(),
            ),
          ),
        ),
        if (widget.isInstalled) ...[
          const SizedBox(width: 12),
          // Open Button Hero
          Hero(
            tag: '${packageName}_btn_open',
            child: Material(
              type: MaterialType.transparency,
              child: _OpenButton(
                activeColor: activeColor,
                onTap: widget.onOpenApp,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Button extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;
  final Color activeColor;

  const _Button({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.bg,
    required this.fg,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        side: BorderSide(color: activeColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyle.bold.normal(fg).copyWith(height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _OpenButton extends StatelessWidget {
  final Color activeColor;
  final VoidCallback onTap;

  const _OpenButton({required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: activeColor.withOpacity(0.15),
          foregroundColor: activeColor,
          elevation: 0,
          side: BorderSide(color: activeColor.withOpacity(0.5), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Icon(Icons.open_in_new, color: activeColor, size: 18),
      ),
    );
  }
}