import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:strata_core/strata_core.dart';

import '../network/network_status_cubit.dart';

/// A widget that wraps the app and provides network status callbacks.
class const NetworkStatusWrapper({
  super.key,
  required final Widget child,
  final Widget Function(BuildContext context, ConnectionStatus status, Widget child)?
      builder,
  final void Function(ConnectionStatus status)? onStatusChange,
  final VoidCallback? onConnect,
  final VoidCallback? onDisconnect,
  final NetworkStatusCubit? networkStatusCubit,
}) extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final cubit = networkStatusCubit ?? GetIt.I<NetworkStatusCubit>();
    final customBuilder = builder;
    return BlocProvider<NetworkStatusCubit>.value(
      value: cubit,
      child: BlocConsumer<NetworkStatusCubit, ConnectionStatus>(
        listener: (context, status) {
          onStatusChange?.call(status);
          switch (status) {
            case ConnectionStatus.connected:
              onConnect?.call();
              break;
            case ConnectionStatus.disconnected:
              onDisconnect?.call();
              break;
            case ConnectionStatus.unknown:
              break;
          }
        },
        builder: (context, status) {
          if (customBuilder != null) {
            return customBuilder(context, status, child);
          }
          return child;
        },
      ),
    );
  }
}
