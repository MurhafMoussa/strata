import 'package:equatable/equatable.dart';

/// Supported platform environments.
enum PlatformType {
  android,
  ios,
  web,
  macos,
  windows,
  linux,
  fuchsia,
  unknown;

  /// Returns true if this platform represents a mobile OS (Android, iOS).
  bool get isMobile => this == PlatformType.android || this == PlatformType.ios;

  /// Returns true if this platform represents a desktop OS (Windows, macOS, Linux).
  bool get isDesktop =>
      this == PlatformType.windows ||
      this == PlatformType.macos ||
      this == PlatformType.linux;

  /// Returns true if running in a web browser environment.
  bool get isWeb => this == PlatformType.web;

  /// Resolves [PlatformType] safely from a name string.
  static PlatformType fromName(String? name) {
    if (name == null || name.isEmpty) return PlatformType.unknown;
    return PlatformType.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => PlatformType.unknown,
    );
  }
}

/// Domain entity representing device hardware, operating system, and build metadata.
class DeviceInfoEntity extends Equatable {
  const DeviceInfoEntity({
    required this.deviceId,
    required this.platform,
    this.model = 'Unknown',
    this.manufacturer = 'Unknown',
    this.osVersion = 'Unknown',
    this.isPhysicalDevice = true,
    this.buildNumber = 'Unknown',
    this.versionNumber = 'Unknown',
  });

  /// Unique identifier of the device or vendor ID.
  final String deviceId;

  /// Underlying platform type.
  final PlatformType platform;

  /// Device hardware model name (e.g. Pixel 8, iPhone 15, MacBookPro18,1).
  final String model;

  /// Device manufacturer (e.g. Google, Apple, Microsoft, Samsung).
  final String manufacturer;

  /// Operating system release or kernel version.
  final String osVersion;

  /// Whether the app is executing on a physical device as opposed to an emulator/simulator.
  final bool isPhysicalDevice;

  /// Build number of the running application package.
  final String buildNumber;

  /// Version number / semantic version string of the running application package.
  final String versionNumber;

  /// Fallback entity when device info cannot be resolved or during uninitialized states.
  static const DeviceInfoEntity unknown = DeviceInfoEntity(
    deviceId: 'Unknown',
    platform: PlatformType.unknown,
    model: 'Unknown',
    manufacturer: 'Unknown',
    osVersion: 'Unknown',
    isPhysicalDevice: false,
    buildNumber: 'Unknown',
    versionNumber: 'Unknown',
  );

  /// Creates a copy of this entity with specified fields updated.
  DeviceInfoEntity copyWith({
    String? deviceId,
    PlatformType? platform,
    String? model,
    String? manufacturer,
    String? osVersion,
    bool? isPhysicalDevice,
    String? buildNumber,
    String? versionNumber,
  }) {
    return DeviceInfoEntity(
      deviceId: deviceId ?? this.deviceId,
      platform: platform ?? this.platform,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      osVersion: osVersion ?? this.osVersion,
      isPhysicalDevice: isPhysicalDevice ?? this.isPhysicalDevice,
      buildNumber: buildNumber ?? this.buildNumber,
      versionNumber: versionNumber ?? this.versionNumber,
    );
  }

  /// Serializes device info to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'platform': platform.name,
        'model': model,
        'manufacturer': manufacturer,
        'osVersion': osVersion,
        'isPhysicalDevice': isPhysicalDevice,
        'buildNumber': buildNumber,
        'versionNumber': versionNumber,
      };

  /// Deserializes a [DeviceInfoEntity] from a JSON map with safe fallbacks.
  factory DeviceInfoEntity.fromJson(Map<String, dynamic> json) {
    return DeviceInfoEntity(
      deviceId: json['deviceId'] as String? ?? 'Unknown',
      platform: PlatformType.fromName(json['platform'] as String?),
      model: json['model'] as String? ?? 'Unknown',
      manufacturer: json['manufacturer'] as String? ?? 'Unknown',
      osVersion: json['osVersion'] as String? ?? 'Unknown',
      isPhysicalDevice: json['isPhysicalDevice'] as bool? ?? false,
      buildNumber: json['buildNumber'] as String? ?? 'Unknown',
      versionNumber: json['versionNumber'] as String? ?? 'Unknown',
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        platform,
        model,
        manufacturer,
        osVersion,
        isPhysicalDevice,
        buildNumber,
        versionNumber,
      ];
}
