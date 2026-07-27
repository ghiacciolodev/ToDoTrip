import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';

/// The privacy policy, read from the same file that lives in the repository.
///
/// Loaded as an asset rather than held in the translation files: it is one text
/// that has to match the version reviewed by a human, and cutting a legal
/// document into ARB keys would guarantee the two versions drift apart.
///
/// Stateful only to own the tap recognisers for the two links in it — they hold
/// a gesture arena entry each and have to be disposed.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  static const _path = 'assets/legal/privacy-policy.md';

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _recognizers = <TapGestureRecognizer>[];
  late final Future<String> _document = rootBundle.loadString(
    PrivacyScreen._path,
  );

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacyPolicy)),
      body: FutureBuilder<String>(
        future: _document,
        builder: (context, snapshot) {
          final text = snapshot.data;
          if (text == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: _blocks(text),
          );
        },
      ),
    );
  }

  /// Enough Markdown for this one document: headings, bullets, bold runs and
  /// bare links. A parser package would be a dependency added to render four
  /// constructs, and the document is ours — it cannot surprise us.
  List<Widget> _blocks(String source) {
    final blocks = <Widget>[];
    for (final raw in source.split('\n\n')) {
      final block = raw.trim();
      if (block.isEmpty) continue;

      if (block.startsWith('# ')) {
        blocks.add(
          Text(
            block.substring(2),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (block.startsWith('## ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(
              block.substring(3),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        );
      } else if (block.startsWith('- ')) {
        for (final line in block.substring(2).split('\n- ')) {
          blocks.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(height: 1.5)),
                  Expanded(child: _paragraph(line)),
                ],
              ),
            ),
          );
        }
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _paragraph(block),
          ),
        );
      }
    }
    return blocks;
  }

  /// Rejoins the hard-wrapped source, then splits out the bold runs and the
  /// bare URLs so both stay legible and tappable.
  Widget _paragraph(String text) {
    final flowed = text.replaceAll('\n', ' ');
    final pattern = RegExp(r'\*\*(.+?)\*\*|(https?://[^\s]+)');
    final spans = <InlineSpan>[];
    var index = 0;

    for (final match in pattern.allMatches(flowed)) {
      if (match.start > index) {
        spans.add(TextSpan(text: flowed.substring(index, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else {
        final url = match.group(2)!;
        final recognizer = TapGestureRecognizer()
          ..onTap = () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: url,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              decoration: TextDecoration.underline,
            ),
            recognizer: recognizer,
          ),
        );
      }
      index = match.end;
    }
    if (index < flowed.length) {
      spans.add(TextSpan(text: flowed.substring(index)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(color: AppColors.ink, fontSize: 15, height: 1.5),
    );
  }
}
