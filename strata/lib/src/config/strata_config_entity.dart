import 'package:equatable/equatable.dart';
import 'package:strata_network/strata_network.dart';
import 'package:strata_state/strata_state.dart';

/// Configuration entity for initializing the Strata framework.
class StrataConfigEntity extends Equatable {
  const StrataConfigEntity({
    required this.networkConfig,
    required this.themeConfig,
    required this.localizationConfig,
    required this.errorParser,
  });

  final NetworkConfigEntity networkConfig;
  final ThemeConfigEntity themeConfig;
  final LocalizationConfigEntity localizationConfig;
  final ErrorModelParser errorParser;

  @override
  List<Object?> get props => [
        networkConfig,
        themeConfig,
        localizationConfig,
        errorParser,
      ];
}
