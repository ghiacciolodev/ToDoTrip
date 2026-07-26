import 'package:flutter/material.dart';

/// Runs [onResume] when the app comes back to the foreground.
///
/// Other people's changes cannot arrive on their own without websockets, so
/// the app refetches at the moments a user would expect data to be current:
/// reopening the app, and switching to a tab.
class RefreshOnResume extends StatefulWidget {
  const RefreshOnResume({
    super.key,
    required this.onResume,
    required this.child,
  });

  final VoidCallback onResume;
  final Widget child;

  @override
  State<RefreshOnResume> createState() => _RefreshOnResumeState();
}

class _RefreshOnResumeState extends State<RefreshOnResume>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.onResume();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
