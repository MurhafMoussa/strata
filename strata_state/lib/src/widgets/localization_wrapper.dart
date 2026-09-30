import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../localization/localization_cubit.dart';

/// A wrapper widget that provides [LocalizationCubit] to the widget tree
/// and builds UI components controlled by the cubit's locale state.
class const LocalizationWrapper({
  super.key,
  required final BlocWidgetBuilder<Locale> builder,
  final BlocWidgetListener<Locale>? listener,
  final LocalizationCubit? localizationCubit,
}) extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final cubit = localizationCubit ?? GetIt.I<LocalizationCubit>();
    return BlocProvider<LocalizationCubit>.value(
      value: cubit,
      child: BlocConsumer<LocalizationCubit, Locale>(
        builder: builder,
        listener: listener ?? (context, state) {},
      ),
    );
  }
}
