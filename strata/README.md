# Strata

Orchestrator meta-package for the Strata framework, exporting all sub-packages (`strata_core`, `strata_network`, `strata_storage`, `strata_state`, `strata_navigation`, `strata_ui`) and providing unified dependency injection setup via `StrataInitializer`.

## Usage

```dart
import 'package:strata/strata.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final strataConfig = StrataConfigEntity(
    networkConfig: NetworkConfigEntity(
      baseUrl: 'https://api.example.com',
      excludedPaths: ['/login', '/register'],
      refreshTokenApiEndpoint: '/auth/refresh',
      accessTokenKey: 'access_token',
      refreshTokenKey: 'refresh_token',
    ),
    navigationConfig: NavigationConfigEntity(
      routes: appRoutes,
      initialLocation: '/',
    ),
  );

  // Single-line framework initialization with mandatory await getIt.allReady()
  await StrataInitializer.initialize(strataConfig);

  runApp(const MyApp());
}
```

## Testing & Teardown

For unit and widget tests, use `StrataInitializer.reset()` to clean up GetIt singletons between test runs:

```dart
tearDown(() async {
  await StrataInitializer.reset();
});
```
