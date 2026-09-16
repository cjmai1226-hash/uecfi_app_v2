import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLength;
  final TextStyle? style;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLength = 150,
    this.style,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  List<InlineSpan> _parseFormatting(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final RegExp exp = RegExp(
      r'(\*\*\*[\s\S]+?\*\*\*|\*\*[\s\S]+?\*\*|\*[^\*\n]+?\*|_[^_\n]+?_)',
    );
    int lastMatchEnd = 0;

    for (final match in exp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('***') &&
          matchedText.endsWith('***') &&
          matchedText.length >= 6) {
        spans.add(TextSpan(
          text: matchedText.substring(3, matchedText.length - 3),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (matchedText.startsWith('**') &&
          matchedText.endsWith('**') &&
          matchedText.length >= 4) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (matchedText.startsWith('*') &&
          matchedText.endsWith('*') &&
          matchedText.length >= 2) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (matchedText.startsWith('_') &&
          matchedText.endsWith('_') &&
          matchedText.length >= 2) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      } else {
        spans.add(TextSpan(text: matchedText, style: baseStyle));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle = (widget.style ?? theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: widget.style?.color ?? context.contentColor,
      height: widget.style?.height ?? 1.5,
    );

    final textChars = widget.text.characters;

    if (textChars.length <= widget.maxLength) {
      return Text.rich(
        TextSpan(children: _parseFormatting(widget.text, effectiveStyle)),
      );
    }

    final truncated = textChars.take(widget.maxLength).toString().trimRight();
    final displayedText = _isExpanded ? widget.text : '$truncated...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: _parseFormatting(displayedText, effectiveStyle)),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              _isExpanded ? 'See less' : 'See more',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
