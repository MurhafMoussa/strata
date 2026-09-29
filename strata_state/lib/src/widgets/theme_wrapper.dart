import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../config/theme_config_entity.dart';
import '../theme/theme_cubit.dart';

/// A wrapper widget that provides [ThemeCubit] to the widget tree
/// and builds UI components controlled by the cubit's theme state.
class const ThemeWrapper({
  super.key,
  required final Widget Function(BuildContext context, ThemeConfigEntity themeConfig)
      builder,
  final ThemeCubit? themeCubit,
}) extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final cubit = themeCubit ?? GetIt.I<ThemeCubit>();
    return BlocProvider<ThemeCubit>.value(
      value: cubit,
      child: BlocBuilder<ThemeCubit, ThemeConfigEntity>(
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode ||
            previous.enableAutoSwitch != current.enableAutoSwitch,
        builder: builder,
      ),
    );
  }
}
