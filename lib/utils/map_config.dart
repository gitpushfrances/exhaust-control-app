import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Shared map settings. Every map screen reads the tile source, zoom limits
/// and attribution from here, so a provider change is a one-file edit.
class MapConfig {
  const MapConfig._();

  /// OpenStreetMap standard tile server.
  /// Usage policy: https://operations.osmfoundation.org/policies/tiles
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Identifies this app to the tile server, as the OSM usage policy requires.
  static const String userAgentPackageName =
      'com.example.exhaust_controller_app';

  static const double minZoom = 5.0;
  static const double maxZoom = 18.0;

  /// Credit required by the OSM licence. Shown as a small info button that
  /// opens on tap, so it does not cover the map. The widget prepends the
  /// copyright symbol itself, so only the source name goes in the text.
  static Widget attribution() => RichAttributionWidget(
    showFlutterMapAttribution: false,
    attributions: [TextSourceAttribution('OpenStreetMap contributors')],
  );
}
