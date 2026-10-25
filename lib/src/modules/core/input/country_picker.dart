/// Consona CountryPickerSheet — Minimal modal bottom sheet for country dial selection.
library;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../core/types.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/tokens.dart';
import '../../feedback/context/feedback_scope.dart';
import '../../feedback/models/feedback_event.dart';
import '../../overlay/drawer/drawer.dart';
import 'search_field.dart';

class CountryCode {
  const CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String code;
  final String dialCode;
  final String flag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryCode &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          dialCode == other.dialCode;

  @override
  int get hashCode => code.hashCode ^ dialCode.hashCode;
}

class ConsonaCountryPickerSheet extends StatefulWidget {
  const ConsonaCountryPickerSheet({
    super.key,
    this.selected,
    this.countries = defaultCountries,
    this.embedded = false,
  });

  final CountryCode? selected;
  final List<CountryCode> countries;

  /// When true, omits outer surface chrome (parent [ConsonaDrawer] provides it).
  final bool embedded;

  static Future<CountryCode?> show(
    BuildContext context, {
    CountryCode? current,
  }) {
    return ConsonaDrawer.show<CountryCode>(
      context,
      snapPoints: const [0.72, 0.92],
      initialSnapIndex: 0,
      scrollable: false,
      header: ConsonaDrawerHeader(
        title: 'Country / Region',
        subtitle: 'Search or scroll to select',
        onClose: () => Navigator.of(context).maybePop(),
      ),
      child: ConsonaCountryPickerSheet(
        selected: current,
        embedded: true,
      ),
    );
  }

  static const List<CountryCode> defaultCountries = [
    CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    CountryCode(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
    CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
    CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryCode(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
    CountryCode(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
  ];

  @override
  State<ConsonaCountryPickerSheet> createState() => _ConsonaCountryPickerSheetState();
}

class _ConsonaCountryPickerSheetState extends State<ConsonaCountryPickerSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final theme = ConsonaTheme.of(context);
    final colors = theme.colors;

    final filtered = widget.countries.where((c) {
      if (_filter.isEmpty) return true;
      final query = _filter.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          c.dialCode.contains(query) ||
          c.code.toLowerCase().contains(query);
    }).toList();

    final list = ListView.separated(
      shrinkWrap: !widget.embedded,
      padding: EdgeInsets.symmetric(
        horizontal: widget.embedded ? 0 : ConsonaSpacing.md,
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          border: theme.border.resolve(
            ConsonaBorderRole.divider,
            context: context,
          ),
        ),
      ),
      itemBuilder: (context, index) {
        final country = filtered[index];
        final isSelected = widget.selected == country;
        return GestureDetector(
          onTap: () {
            ConsonaFeedbackScope.of(context).trigger(FeedbackEvent.selection);
            Navigator.of(context).pop(country);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ConsonaSpacing.md),
            child: Row(
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 22.0)),
                const SizedBox(width: ConsonaSpacing.md),
                Expanded(
                  child: Text(
                    country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.copyWith(
                      color: isSelected ? colors.primary : colors.foreground,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  country.dialCode,
                  style: theme.typography.body.copyWith(
                    color: colors.mutedFg,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.all(ConsonaSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Country',
                      style: theme.typography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(ConsonaSpacing.xxs),
                        child: Icon(
                          Icons.close_rounded,
                          size: ConsonaGeometries.iconSizeFor(
                            ConsonaOpticalSize.sm,
                          ),
                          color: colors.mutedFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ConsonaSpacing.sm),
                ConsonaSearchField(
                  placeholder: 'Search countries...',
                  onChanged: (text) => setState(() => _filter = text),
                ),
              ],
            ),
          )
        else
          Padding(
            // Top inset keeps the search outline clear of the drawer header clip.
            padding: const EdgeInsets.only(
              top: ConsonaSpacing.sm,
              bottom: ConsonaSpacing.sm,
            ),
            child: ConsonaSearchField(
              placeholder: 'Search countries...',
              onChanged: (text) => setState(() => _filter = text),
            ),
          ),
        Expanded(child: list),
      ],
    );

    if (widget.embedded) {
      // Fill the drawer body (parent is SizedBox.expand when scrollable:false).
      return body;
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 520.0),
      margin: const EdgeInsets.all(ConsonaSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: theme.radius.resolve(ConsonaRadiusRole.macro),
        border: theme.border.resolve(ConsonaBorderRole.surfaceEdge),
        boxShadow: theme.shadow.resolve(ConsonaShadowLevel.strong),
      ),
      child: SizedBox(height: 520, child: body),
    );
  }
}
