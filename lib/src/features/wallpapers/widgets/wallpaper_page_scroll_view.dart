import 'package:flutter/material.dart';

/// A single scroll surface for page chrome and non-grid states.
///
/// Keeping the header in the same viewport as the status content lets large
/// accessibility text reflow and scroll instead of competing with a fixed
/// header for the remaining height.
class WallpaperPageScrollView extends StatelessWidget {
  const WallpaperPageScrollView({
    super.key,
    required this.headerWidgets,
    required this.child,
    this.onRefresh,
  });

  final List<Widget> headerWidgets;
  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        for (final header in headerWidgets) SliverToBoxAdapter(child: header),
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );

    if (onRefresh case final refresh?) {
      return RefreshIndicator(onRefresh: refresh, child: scrollView);
    }
    return scrollView;
  }
}
