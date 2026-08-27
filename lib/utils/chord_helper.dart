import 'package:flutter/material.dart';

class ChordHelper {
  // Dictionary of basic guitar chords (from uecfi_flutter_app_vanilla)
  static const Map<String, String> _guitarChords = {
    'C': 'x32010', 'C#': 'x46664', 'Db': 'x46664',
    'D': 'xx0232', 'D#': 'xx1343', 'Eb': 'xx1343',
    'E': '022100',
    'F': '133211', 'F#': '244322', 'Gb': '244322',
    'G': '320003', 'G#': '466544', 'Ab': '466544',
    'A': 'x02220', 'A#': 'x13331', 'Bb': 'x13331',
    'B': 'x24442',
    'Cm': 'x35543', 'C#m': 'x46654', 'Dbm': 'x46654',
    'Dm': 'xx0231', 'D#m': 'xx1342', 'Ebm': 'xx1342',
    'Em': '022000',
    'Fm': '133111', 'F#m': '244222', 'Gbm': '244222',
    'Gm': '355333', 'G#m': '466444', 'Abm': '466444',
    'Am': 'x02210', 'A#m': 'x13321', 'Bbm': 'x13321',
    'Bm': 'x24432',
    'C7': 'x32310', 'D7': 'xx0212', 'E7': '020100', 'F7': '131211', 'G7': '320001', 'A7': 'x02020', 'B7': 'x21202',
    'Cmaj7': 'x32000', 'Gmaj7': '3x0002', 'Amaj7': 'x02120', 'Dmaj7': 'xx0222', 'Emaj7': '021100', 'Fmaj7': '1x2210',
    'Csus2': 'x30033', 'Dsus2': 'xx0230', 'Asus2': 'x02200', 'Esus2': '024400',
    'Csus4': 'x33010', 'Dsus4': 'xx0233', 'Asus4': 'x02230', 'Esus4': '022200',
  };

  // Dictionary of basic ukulele chords
  static const Map<String, String> _ukuleleChords = {
    'C': '0003', 'C#': '1114', 'Db': '1114',
    'D': '2220', 'D#': '0331', 'Eb': '0331',
    'E': '1402',
    'F': '2010', 'F#': '3121', 'Gb': '3121',
    'G': '0232', 'G#': '5343', 'Ab': '5343',
    'A': '2100', 'A#': '3211', 'Bb': '3211',
    'B': '4322',
    'Cm': '0333', 'C#m': '1444', 'Dbm': '1444',
    'Dm': '2210', 'D#m': '3321', 'Ebm': '3321',
    'Em': '0432',
    'Fm': '1013', 'F#m': '2120', 'Gbm': '2120',
    'Gm': '0231', 'G#m': '4342', 'Abm': '4342',
    'Am': '2000', 'A#m': '3111', 'Bbm': '3111',
    'Bm': '4222',
    'C7': '0001', 'D7': '2223', 'E7': '1202', 'F7': '2310', 'G7': '0212', 'A7': '0100', 'B7': '2322',
    'Cmaj7': '0002', 'Gmaj7': '0222', 'Amaj7': '1100', 'Dmaj7': '2224', 'Emaj7': '1302', 'Fmaj7': '5557',
  };

  /// Clean chord name string
  static String cleanChordName(String chordRaw) {
    var cleaned = chordRaw.replaceAll('>', '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^\w#b\/7]'), '');
    return cleaned;
  }

  /// Transpose chord by semitone steps (e.g. +1 C -> C#)
  static String transposeChord(String chord, int steps) {
    if (steps == 0) return chord;

    final List<String> notes = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
    ];
    final Map<String, String> flatsToSharps = {
      'Db': 'C#', 'Eb': 'D#', 'Gb': 'F#', 'Ab': 'G#', 'Bb': 'A#',
    };

    final match = RegExp(r'^([A-G][#b]?)(.*)$').firstMatch(chord);
    if (match == null) return chord;

    String root = match.group(1)!;
    String suffix = match.group(2)!;

    if (flatsToSharps.containsKey(root)) {
      root = flatsToSharps[root]!;
    }

    int index = notes.indexOf(root);
    if (index == -1) return chord;

    int newIndex = (index + steps) % 12;
    if (newIndex < 0) newIndex += 12;

    String newRoot = notes[newIndex];

    if (suffix.contains('/')) {
      final slashParts = suffix.split('/');
      if (slashParts.length == 2) {
        String bassNote = slashParts[1];
        String transposedBass = transposeChord(bassNote, steps);
        suffix = '${slashParts[0]}/$transposedBass';
      }
    }

    return '$newRoot$suffix';
  }

  /// Show interactive chord shape dialog (from uecfi_flutter_app_vanilla)
  static void showChordDiagram(BuildContext context, String chordRaw, {String instrument = 'Guitar'}) {
    final chordName = cleanChordName(chordRaw);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$chordName ($instrument)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 180,
              height: 190,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ChordDiagram(
                instrument: instrument,
                chordName: chordName,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Chord Diagram Widget rendering guitar/ukulele frets (from uecfi_flutter_app_vanilla)
class ChordDiagram extends StatelessWidget {
  final String instrument;
  final String chordName;

  const ChordDiagram({
    super.key,
    required this.instrument,
    required this.chordName,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> dict = instrument == 'Ukulele'
        ? ChordHelper._ukuleleChords
        : ChordHelper._guitarChords;

    String baseChord = chordName;
    if (!dict.containsKey(baseChord)) {
      baseChord = baseChord.replaceAll(RegExp(r'(add9|dim|aug|m7|7sus4)'), '');
      if (!dict.containsKey(baseChord)) {
        return Center(
          child: Text('Chord "$chordName" shape not available', textAlign: TextAlign.center),
        );
      }
    }

    final frets = dict[baseChord]!;
    final isUkulele = instrument == 'Ukulele';
    final numStrings = isUkulele ? 4 : 6;
    final stringNames = isUkulele ? const ['G', 'C', 'E', 'A'] : const ['E', 'A', 'D', 'G', 'B', 'e'];

    return CustomPaint(
      size: const Size(150, 150),
      painter: _ChordPainter(
        fretsStr: frets,
        numStrings: numStrings,
        stringNames: stringNames,
        textColor: Theme.of(context).colorScheme.onSurface,
        primaryColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ChordPainter extends CustomPainter {
  final String fretsStr;
  final int numStrings;
  final List<String> stringNames;
  final Color textColor;
  final Color primaryColor;

  _ChordPainter({
    required this.fretsStr,
    required this.numStrings,
    required this.stringNames,
    required this.textColor,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = textColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final xPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold);

    // Calculate grid dimensions
    final double padding = 20.0;
    final double headerHeight = 24.0;
    final double width = size.width - padding * 2;
    final double height = size.height - padding * 2 - headerHeight;

    final double stringSpacing = width / (numStrings - 1);
    final int numFrets = 4; // Display 4 frets visually
    final double fretSpacing = height / numFrets;

    // Draw String Names at the top
    for (int i = 0; i < numStrings; i++) {
      final tp = TextPainter(
        text: TextSpan(text: stringNames[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padding + i * stringSpacing - tp.width / 2, padding - 20));
    }

    // Determine the base fret offset
    List<int> pressedFrets = [];
    for (int i = 0; i < fretsStr.length; i++) {
      final char = fretsStr[i];
      if (char == 'x' || char == 'X') {
        pressedFrets.add(-1);
      } else {
        pressedFrets.add(int.tryParse(char) ?? 0);
      }
    }

    // Check if we need to shift frets down (barre chords high on neck)
    int minFret = 99;
    int maxFret = 0;
    for (int fret in pressedFrets) {
      if (fret > 0) {
        if (fret < minFret) minFret = fret;
        if (fret > maxFret) maxFret = fret;
      }
    }

    int fretOffset = 0;
    if (maxFret > 4) {
      fretOffset = minFret - 1;
    }

    // Draw Nut or top line
    if (fretOffset == 0) {
      canvas.drawLine(
        Offset(padding, padding + headerHeight),
        Offset(padding + width, padding + headerHeight),
        Paint()..color = textColor..strokeWidth = 5,
      );
    } else {
      // Draw offset text indicator
      final tp = TextPainter(
        text: TextSpan(
          text: 'fr ${fretOffset + 1}',
          style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padding + width + 8, padding + headerHeight + 2));
    }

    // Draw vertical strings
    for (int i = 0; i < numStrings; i++) {
      double x = padding + i * stringSpacing;
      canvas.drawLine(
        Offset(x, padding + headerHeight),
        Offset(x, padding + headerHeight + height),
        paint,
      );
    }

    // Draw horizontal frets
    for (int i = 0; i <= numFrets; i++) {
      double y = padding + headerHeight + i * fretSpacing;
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + width, y),
        paint,
      );
    }

    // Draw fingers (dots) and mutes (X) or opens (O)
    for (int idx = 0; idx < pressedFrets.length; idx++) {
      if (idx >= numStrings) break;

      double x = padding + idx * stringSpacing;
      int fret = pressedFrets[idx];

      if (fret == -1) {
        // Draw X above nut
        double crossSize = 4.0;
        double cy = padding + headerHeight - 10;
        canvas.drawLine(Offset(x - crossSize, cy - crossSize), Offset(x + crossSize, cy + crossSize), xPaint);
        canvas.drawLine(Offset(x + crossSize, cy - crossSize), Offset(x - crossSize, cy + crossSize), xPaint);
      } else if (fret == 0) {
        // Draw O above nut
        canvas.drawCircle(Offset(x, padding + headerHeight - 10), 4, Paint()..color = textColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
      } else {
        // Draw dot on the fret
        int visualFret = fret - fretOffset;
        if (visualFret > 0 && visualFret <= numFrets) {
          double y = padding + headerHeight + (visualFret - 1) * fretSpacing + fretSpacing / 2;
          canvas.drawCircle(Offset(x, y), 8, dotPaint);
          canvas.drawCircle(Offset(x, y), 8, Paint()..color = ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark ? Colors.white24 : Colors.black26..style = PaintingStyle.stroke..strokeWidth = 0.5);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChordPainter oldDelegate) {
    return oldDelegate.fretsStr != fretsStr ||
        oldDelegate.numStrings != numStrings ||
        oldDelegate.textColor != textColor ||
        oldDelegate.primaryColor != primaryColor;
  }
}
