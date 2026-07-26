import 'package:flutter/material.dart';

import '../widgets/tab_states.dart';

/// Placeholder for the trip's places.
///
/// The destination exists already so the bar keeps its final shape; nothing
/// here pretends to hold data yet.
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.map_outlined,
      title: 'Map coming soon',
      subtitle: 'The places you save for this trip\nwill show up here.',
    );
  }
}
