/// Consona Color — Curated preset palettes.
///
/// Direct port of `SOFT_COLOR_PRESETS` and `DARK_COLOR_PRESETS` from the
/// interface `color-presets.tsx` (full named arrays, unabridged).
library;

import 'package:flutter/widgets.dart';

/// A named preset color (display name + hex string).
@immutable
class ConsonaColorPresetItem {
  const ConsonaColorPresetItem(this.name, this.hex);
  final String name;
  final String hex;
}

/// 50 soft pastel / neutral presets.
const List<ConsonaColorPresetItem> kSoftColorPresets = [
  // Whites, Neutrals & Light Grays
  ConsonaColorPresetItem('Pure White', '#ffffff'),
  ConsonaColorPresetItem('Snow Drift', '#f8fafc'),
  ConsonaColorPresetItem('Alabaster', '#f8f9fa'),
  ConsonaColorPresetItem('Cotton Pearl', '#f5f5f7'),
  ConsonaColorPresetItem('Ivory Mist', '#fdfbf7'),
  ConsonaColorPresetItem('Porcelain', '#f1f5f9'),
  ConsonaColorPresetItem('Soft Chalk', '#e2e8f0'),
  ConsonaColorPresetItem('Dove Gray', '#e4e4e7'),

  // Soft Pinks & Roses
  ConsonaColorPresetItem('Blush Satin', '#ffcad4'),
  ConsonaColorPresetItem('Rose Quartz', '#ffe5d9'),
  ConsonaColorPresetItem('Cameo Pink', '#fde2e4'),
  ConsonaColorPresetItem('Petal Pink', '#fce7f3'),
  ConsonaColorPresetItem('Flamingo Pastel', '#fbcfe8'),
  ConsonaColorPresetItem('Ballet Slipper', '#ffd1dc'),

  // Soft Purples & Lavenders
  ConsonaColorPresetItem('Lavender Haze', '#e8e8e4'),
  ConsonaColorPresetItem('Frosted Mauve', '#e2d4f0'),
  ConsonaColorPresetItem('Lilac Feather', '#f3e8ff'),
  ConsonaColorPresetItem('Pale Thistle', '#ece4f9'),
  ConsonaColorPresetItem('Wisteria Pale', '#e9d8fd'),
  ConsonaColorPresetItem('Soft Iris', '#ede9fe'),

  // Soft Blues & Cyans
  ConsonaColorPresetItem('Cloud Whisper', '#e0fbfc'),
  ConsonaColorPresetItem('Chalk Blue', '#d9e8f5'),
  ConsonaColorPresetItem('Morning Sky', '#e0f2fe'),
  ConsonaColorPresetItem('Icy Azure', '#e1f5fe'),
  ConsonaColorPresetItem('Periwinkle Fog', '#dce4ff'),
  ConsonaColorPresetItem('Glacier Mist', '#cffafe'),

  // Soft Mints, Seafoams & Sages
  ConsonaColorPresetItem('Soft Sage', '#d8e2dc'),
  ConsonaColorPresetItem('Dusty Mint', '#d0f4de'),
  ConsonaColorPresetItem('Eucalyptus', '#c6dec6'),
  ConsonaColorPresetItem('Seafoam Silk', '#e8f8f5'),
  ConsonaColorPresetItem('Pistachio Ice', '#e8f5e9'),
  ConsonaColorPresetItem('Matcha Milk', '#e4eed7'),
  ConsonaColorPresetItem('Honeydew', '#f0fdf4'),
  ConsonaColorPresetItem('Celadon Breeze', '#def0e5'),
  ConsonaColorPresetItem('Spearmint Foam', '#ccfbf1'),
  ConsonaColorPresetItem('Spring Meadow', '#dcfce7'),

  // Soft Yellows, Creams & Peaches
  ConsonaColorPresetItem('Buttercream', '#fef9e7'),
  ConsonaColorPresetItem('Vanilla Chiffon', '#fff8e7'),
  ConsonaColorPresetItem('Peach Puff', '#ffe5d4'),
  ConsonaColorPresetItem('Champagne', '#f9f1e7'),
  ConsonaColorPresetItem('Apricot Nectar', '#ffedd5'),
  ConsonaColorPresetItem('Primrose Soft', '#fef08a'),
  ConsonaColorPresetItem('Lemon Chiffon', '#fef9c3'),
  ConsonaColorPresetItem('Custard Cream', '#fef3c7'),
  ConsonaColorPresetItem('Pastel Saffron', '#fed7aa'),
  ConsonaColorPresetItem('Papaya Whip', '#ffefd5'),

  // Soft Earth & Warm Pastels
  ConsonaColorPresetItem('Linen Mist', '#f7ebe8'),
  ConsonaColorPresetItem('Oatmeal Cream', '#f5ebe0'),
  ConsonaColorPresetItem('Fawn Cashmere', '#ead7d1'),
  ConsonaColorPresetItem('Smoky Quartz Light', '#e5e0db'),
  ConsonaColorPresetItem('Sand Dollar', '#efece6'),
  ConsonaColorPresetItem('Cool Pewter', '#cbd5e1'),
];

/// Moody dark presets.
const List<ConsonaColorPresetItem> kDarkColorPresets = [
  // Blacks, Charcoals & Grays
  ConsonaColorPresetItem('Pure Black', '#000000'),
  ConsonaColorPresetItem('Obsidian Noir', '#0f0f11'),
  ConsonaColorPresetItem('Charcoal Gray', '#1f2937'),
  ConsonaColorPresetItem('Gunmetal Slate', '#27272a'),
  ConsonaColorPresetItem('Iron Ore', '#374151'),
  ConsonaColorPresetItem('Cool Graphite', '#475569'),
  ConsonaColorPresetItem('Smoked Tungsten', '#3f3f46'),
  ConsonaColorPresetItem('Pewter Shadow', '#52525b'),

  // Dark Pinks & Magentas
  ConsonaColorPresetItem('Dark Rose Pink', '#9f1239'),
  ConsonaColorPresetItem('Midnight Magenta', '#be185d'),
  ConsonaColorPresetItem('Raspberry Noir', '#831843'),
  ConsonaColorPresetItem('Dark Coral Pink', '#9e2a2b'),
  ConsonaColorPresetItem('Deep Flamingo', '#a21caf'),
  ConsonaColorPresetItem('Mulberry Pink', '#701a75'),
  ConsonaColorPresetItem('Ruby Twilight', '#881337'),
  ConsonaColorPresetItem('Dark Fuchsia', '#86198f'),

  // Dark Yellows, Mustards & Golds
  ConsonaColorPresetItem('Dark Mustard', '#854d0e'),
  ConsonaColorPresetItem('Antique Gold', '#713f12'),
  ConsonaColorPresetItem('Dark Saffron', '#a16207'),
  ConsonaColorPresetItem('Dark Citron', '#4d4408'),
  ConsonaColorPresetItem('Honey Ochre', '#92400e'),
  ConsonaColorPresetItem('Tuscan Amber', '#b45309'),
  ConsonaColorPresetItem('Bronze Olive', '#594a05'),
  ConsonaColorPresetItem('Burnt Caramel', '#7c2d12'),

  // Dark Mints, Seafoams & Greens
  ConsonaColorPresetItem('Dark Mint', '#065f46'),
  ConsonaColorPresetItem('Dark Spearmint', '#047857'),
  ConsonaColorPresetItem('Seafoam Shadow', '#0d5c58'),
  ConsonaColorPresetItem('Jade Mint', '#115e59'),
  ConsonaColorPresetItem('Pine Mint', '#0f766e'),
  ConsonaColorPresetItem('Frosted Evergreen', '#134e4a'),
  ConsonaColorPresetItem('Forest Emerald', '#14532d'),
  ConsonaColorPresetItem('Deep Pine', '#15803d'),

  // Dark Limes & Olives
  ConsonaColorPresetItem('Dark Olive Lime', '#3f6212'),
  ConsonaColorPresetItem('Moss Green', '#4d7c0f'),
  ConsonaColorPresetItem('Dark Chartreuse', '#365314'),
  ConsonaColorPresetItem('Kombu Green', '#1a381e'),

  // Dark Cyans & Teals
  ConsonaColorPresetItem('Deep Petroleum', '#0e7490'),
  ConsonaColorPresetItem('Ocean Abyss', '#0369a1'),
  ConsonaColorPresetItem('Aegean Teal', '#155e75'),
  ConsonaColorPresetItem('Stormy Cyan', '#164e63'),

  // Dark Blues & Indigos
  ConsonaColorPresetItem('Midnight Navy', '#1e3a8a'),
  ConsonaColorPresetItem('Deep Sapphire', '#1d4ed8'),
  ConsonaColorPresetItem('Imperial Indigo', '#4338ca'),
  ConsonaColorPresetItem('Slate Indigo', '#3730a3'),
  ConsonaColorPresetItem('Cobalt Night', '#2563eb'),
  ConsonaColorPresetItem('Twilight Steel', '#334155'),

  // Dark Purples & Violets
  ConsonaColorPresetItem('Velvet Violet', '#6b21a8'),
  ConsonaColorPresetItem('Dark Amethyst', '#5b21b6'),
  ConsonaColorPresetItem('Blackcurrant', '#4c1d95'),
  ConsonaColorPresetItem('Imperial Plum', '#581c87'),

  // Dark Warm & Earth Tones
  ConsonaColorPresetItem('Dark Terracotta', '#9a3412'),
  ConsonaColorPresetItem('Espresso Roast', '#451a03'),
];
