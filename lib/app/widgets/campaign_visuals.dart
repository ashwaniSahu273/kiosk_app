import 'package:flutter/material.dart';

/// Shared hero gradients, tags, and icons for program/donation campaign UI.
class CampaignVisuals {
  const CampaignVisuals._();

  static String programTag(String id) {
    if (id.contains('quran')) {
      return 'Quran';
    }
    if (id.contains('youth')) {
      return 'Youth';
    }
    if (id.contains('sisters')) {
      return 'Sisters';
    }
    if (id.contains('new-muslim') || id.contains('mentorship')) {
      return 'New Muslim';
    }
    return 'Programs';
  }

  static List<Color> programGradient(String id, ColorScheme scheme) {
    if (id.contains('quran')) {
      return <Color>[const Color(0xFF1B5E20), const Color(0xFF43A047)];
    }
    if (id.contains('youth')) {
      return <Color>[const Color(0xFF0D47A1), const Color(0xFF42A5F5)];
    }
    if (id.contains('sisters')) {
      return <Color>[const Color(0xFF4A148C), const Color(0xFFAB47BC)];
    }
    if (id.contains('new-muslim') || id.contains('mentorship')) {
      return <Color>[const Color(0xFF00695C), const Color(0xFF26A69A)];
    }
    return <Color>[scheme.primary, scheme.secondary];
  }

  static IconData programIcon(String id) {
    if (id.contains('quran')) {
      return Icons.menu_book_rounded;
    }
    if (id.contains('youth')) {
      return Icons.groups_rounded;
    }
    if (id.contains('sisters')) {
      return Icons.school_rounded;
    }
    if (id.contains('new-muslim') || id.contains('mentorship')) {
      return Icons.handshake_rounded;
    }
    return Icons.event_rounded;
  }

  static List<Color> donationGradient(String id, ColorScheme scheme) {
    if (id.contains('zakat')) {
      return <Color>[const Color(0xFF1B5E20), const Color(0xFF43A047)];
    }
    if (id.contains('sadaqah') || id.contains('general')) {
      return <Color>[const Color(0xFFC62828), const Color(0xFFE53935)];
    }
    if (id.contains('maintenance') || id.contains('building')) {
      return <Color>[const Color(0xFF4E342E), const Color(0xFF8D6E63)];
    }
    return <Color>[scheme.primary, scheme.secondary];
  }

  static IconData donationIcon(String id) {
    if (id.contains('zakat')) {
      return Icons.mosque_rounded;
    }
    if (id.contains('sadaqah') || id.contains('general')) {
      return Icons.volunteer_activism_rounded;
    }
    if (id.contains('maintenance') || id.contains('building')) {
      return Icons.home_work_rounded;
    }
    return Icons.favorite_rounded;
  }
}
