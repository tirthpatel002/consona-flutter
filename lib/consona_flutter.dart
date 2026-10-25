/// Consona Flutter — Multi-Platform UI Component Library & Logic Foundation
library;

// Core Kernel
export 'src/core/animation.dart';
export 'src/core/engine.dart';
export 'src/core/event_bus.dart';
export 'src/core/hit_target.dart';
export 'src/core/plugin.dart';
export 'src/core/provider.dart';
export 'src/core/registry.dart';
export 'src/core/size_context.dart';
export 'src/core/slot.dart';
export 'src/core/slots.dart';
export 'src/core/storage.dart';
export 'src/core/types.dart';
export 'src/core/variants.dart';

// Theme System
export 'src/theme/border.dart';
export 'src/theme/color_scheme.dart';
export 'src/theme/colors.dart';
export 'src/theme/component_themes.dart';
export 'src/theme/density.dart';
export 'src/theme/motion.dart';
export 'src/theme/presets.dart';
export 'src/theme/radius.dart';
export 'src/theme/shadow.dart';
export 'src/theme/stroke.dart';
export 'src/theme/theme_config.dart';
export 'src/theme/theme_controller.dart';
export 'src/theme/theme_data.dart';
export 'src/theme/theme_provider.dart';
export 'src/theme/tokens.dart';
export 'src/theme/typography.dart';

// Feedback Subsystem
export 'src/modules/feedback/context/feedback_scope.dart';
export 'src/modules/feedback/engine/feedback_engine.dart';
export 'src/modules/feedback/engine/haptic_engine.dart';
export 'src/modules/feedback/engine/sound_engine.dart';
export 'src/modules/feedback/feedback_plugin.dart';
export 'src/modules/feedback/interaction/spring_press.dart';
export 'src/modules/feedback/models/feedback_config.dart';
export 'src/modules/feedback/models/feedback_event.dart';
export 'src/modules/feedback/models/feedback_profile.dart';
export 'src/modules/feedback/player/sound_player.dart';
export 'src/modules/feedback/sound_library/default_cues.dart';
export 'src/modules/feedback/sound_library/sound_library.dart';

// Asset Subsystem
export 'src/modules/assets/asset.dart';
export 'src/modules/assets/asset_kind.dart';
export 'src/modules/assets/asset_library.dart';
export 'src/modules/assets/assets_plugin.dart';
export 'src/modules/assets/cache/asset_cache.dart';
export 'src/modules/assets/synth/sound_recipe.dart';

// Core Atoms & Cells
export 'src/modules/core/alert/alert.dart';
export 'src/modules/core/alert/banner.dart';
export 'src/modules/core/avatar/avatar.dart';
export 'src/modules/core/badge/badge.dart';
export 'src/modules/core/badge/pill.dart';
export 'src/modules/core/badge/status_dot.dart';
export 'src/modules/core/button/button.dart';
export 'src/modules/core/button/button_variant.dart';
export 'src/modules/core/button/fab.dart';
export 'src/modules/core/button/icon_button.dart';
export 'src/modules/core/carousel/carousel.dart';
export 'src/modules/core/checkbox/checkbox.dart';
export 'src/modules/core/chip/choice_box.dart';
export 'src/modules/core/chip/chip.dart';
export 'src/modules/core/color/color_picker.dart';
export 'src/modules/core/empty_state/empty_state.dart';
export 'src/modules/core/interaction/swipe_action.dart';
export 'src/modules/core/interaction/swipe_dismiss.dart';
export 'src/modules/core/list_tile/list_tile.dart';
export 'src/modules/core/loader/loader.dart';
export 'src/modules/core/progress/progress.dart';
export 'src/modules/core/radio/radio.dart';
export 'src/modules/core/section/section.dart';
export 'src/modules/core/separator/divider.dart';
export 'src/modules/core/skeleton/skeleton.dart';
export 'src/modules/core/split_view/split_view.dart';
export 'src/modules/core/switch/switch.dart';
export 'src/modules/core/table/pagination.dart';
export 'src/modules/core/table/table.dart';
export 'src/modules/core/timeline/timeline.dart';
export 'src/modules/core/toolbar/toolbar.dart';
export 'src/modules/core/tree/tree.dart';
export 'src/modules/core/typography/copyable.dart';
export 'src/modules/core/typography/kbd.dart';
export 'src/modules/core/typography/link.dart';
export 'src/modules/core/typography/show_more.dart';
export 'src/modules/core/typography/snippet.dart';
export 'src/modules/core/typography/text.dart';

// Navigation
export 'src/modules/navigation/app_bar.dart';
export 'src/modules/navigation/breadcrumbs.dart';
export 'src/modules/navigation/breakpoints.dart';
export 'src/modules/navigation/destination.dart';
export 'src/modules/navigation/nav.dart';
export 'src/modules/navigation/segmented_control.dart';
export 'src/modules/navigation/shell.dart';
export 'src/modules/navigation/stepper.dart';
export 'src/modules/navigation/swipeable_tab_pager.dart';

// Forms, Inputs, Pickers & Steppers
export 'src/modules/core/counter/counter.dart';
export 'src/modules/core/counter/number_field.dart';
export 'src/modules/core/date_time/date_picker.dart';
export 'src/modules/core/date_time/date_time_picker.dart';
export 'src/modules/core/date_time/picker_chrome.dart';
export 'src/modules/core/date_time/time_picker.dart';
export 'src/modules/core/input/country_picker.dart';
export 'src/modules/core/input/email_field.dart';
export 'src/modules/core/input/file_dropzone.dart';
export 'src/modules/core/input/otp_field.dart';
export 'src/modules/core/input/password_field.dart';
export 'src/modules/core/input/phone_field.dart';
export 'src/modules/core/input/pin_verification.dart';
export 'src/modules/core/input/search_field.dart';
export 'src/modules/core/input/tag_input.dart';
export 'src/modules/core/input/text_area.dart';
export 'src/modules/core/input/text_field.dart';
export 'src/modules/core/picker/autocomplete.dart';
export 'src/modules/core/picker/multi_select.dart';
export 'src/modules/core/picker/select.dart';
export 'src/modules/core/picker/wheel_picker.dart';
export 'src/modules/core/rating/rating.dart';
export 'src/modules/core/scroll/infinite_scroll.dart';
export 'src/modules/core/scroll/pull_to_refresh.dart';
export 'src/modules/core/scroll/scroll_area.dart';
export 'src/modules/core/slider/range_slider.dart';
export 'src/modules/core/slider/slider.dart';

// Surfaces, Cards, Overlays & Audio
export 'src/modules/audio/adapters/audioplayers_audio_backend.dart';
export 'src/modules/audio/adapters/audioplayers_sound_player.dart';
export 'src/modules/audio/adapters/record_audio_recorder_backend.dart';
export 'src/modules/audio/audio_plugin.dart';
export 'src/modules/audio/engine/audio_engine.dart';
export 'src/modules/audio/engine/audio_format.dart';
export 'src/modules/audio/engine/recorder_engine.dart';
export 'src/modules/audio/player/audio_builders.dart';
export 'src/modules/audio/player/audio_player.dart';
export 'src/modules/audio/player/audio_player_card.dart';
export 'src/modules/audio/player/audio_player_pill.dart';
export 'src/modules/audio/recorder/audio_recorder_card.dart';
export 'src/modules/audio/recorder/audio_recorder_pill.dart';
export 'src/modules/audio/recorder/recording_preview.dart';
export 'src/modules/audio/scrubber/timeline_scrubber.dart';
export 'src/modules/audio/shared/artwork.dart';
export 'src/modules/audio/shared/mini_visualizer.dart';
export 'src/modules/audio/shared/morph_fill.dart';
export 'src/modules/audio/waveform/waveform.dart';
export 'src/modules/core/accordion/accordion.dart';
export 'src/modules/core/bento/bento_grid.dart';
export 'src/modules/core/card/card.dart';
export 'src/modules/overlay/action_sheet/action_sheet.dart';
export 'src/modules/overlay/command_palette/command_palette.dart';
export 'src/modules/overlay/common/overlay_host.dart';
export 'src/modules/overlay/context/overlay_scope.dart';
export 'src/modules/overlay/context_menu/context_menu.dart';
export 'src/modules/overlay/dialog/dialog.dart';
export 'src/modules/overlay/drawer/drawer.dart';
export 'src/modules/overlay/engine/overlay_engine.dart';
export 'src/modules/overlay/modal/modal.dart';
export 'src/modules/overlay/overlay_plugin.dart';
export 'src/modules/overlay/popover/popover.dart';
export 'src/modules/overlay/sheet/sheet.dart';
export 'src/modules/overlay/toast/toast.dart';
export 'src/modules/overlay/tooltip/tooltip.dart';

// Media & Files
export 'src/modules/media/media.dart';
