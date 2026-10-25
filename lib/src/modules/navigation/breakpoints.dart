/// Consona Breakpoints — window size classes driving [ConsonaShell] layout
library;

enum ConsonaWindowClass { compact, medium, expanded }

class ConsonaBreakpoints {
  const ConsonaBreakpoints({this.medium = 600.0, this.expanded = 1000.0})
      : assert(medium <= expanded);

  /// Width at which [ConsonaWindowClass.medium] starts (compact < medium).
  final double medium;

  /// Width at which [ConsonaWindowClass.expanded] starts.
  final double expanded;

  ConsonaWindowClass classify(double width) {
    if (width >= expanded) return ConsonaWindowClass.expanded;
    if (width >= medium) return ConsonaWindowClass.medium;
    return ConsonaWindowClass.compact;
  }

  @override
  bool operator ==(Object other) =>
      other is ConsonaBreakpoints &&
      other.medium == medium &&
      other.expanded == expanded;

  @override
  int get hashCode => Object.hash(medium, expanded);
}

/// Wide-screen layout property of [ConsonaShell] (used at expanded widths).
enum ConsonaShellWide {
  /// Full-label side nav on the leading edge.
  sidebar,

  /// Top nav inside the header area.
  header,
}
