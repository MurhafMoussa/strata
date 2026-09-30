# strata_ui

Reusable UI components, custom form fields, and layout theme abstractions for the Strata framework.

## Overview

`strata_ui` provides decoupled, reusable Flutter widgets isolated from state management (`flutter_bloc`) and routing (`go_router`) engines. Navigation and state interactions are handled cleanly via standard Flutter callback closures.

## Architectural Rules & Boundaries

- **Decoupled Components**: Depends ONLY on `strata_core`, `strata_state`, `flutter`, `skeletonizer`, `pinput`, `readmore`, `shimmer`, `cached_network_image`, `carousel_slider`, `gap`, and `typed_form_fields`.
- **Zero Framework Binding**: MUST NOT depend on `flutter_bloc` or `go_router`.
- **Callback Pattern**: Actions and events are passed as callbacks (`onRefresh`, `onLoadMore`, `onChanged`, `onTap`).
- **Strict Boundary Enforcement**: Enforced via package dependency audit tests.

## Key Components

### 1. `StrataPaginationWidget`
Decoupled, platform-adaptive pagination widget utilizing native Flutter `RefreshIndicator.adaptive`, `NotificationListener<ScrollNotification>`, mutually exclusive layout builders (`scrollableBuilder`, `sliversBuilder`, `customBuilder`), full-screen and incremental `Skeletonizer` loading states, inline page-N retry bar, desktop/web scrollbar and shortcuts (`Ctrl+R` / `Cmd+R`), and offline cache badges.

```dart
import 'package:strata_ui/strata_ui.dart';

StrataPaginationWidget<ProductItem, PaginationMetaModel>(
  state: paginationState,
  onRefresh: () async => fetchProducts(),
  onLoadMore: () async => fetchMoreProducts(),
  emptyEntity: ProductItem.empty,
  scrollableBuilder: (context, controller, items) {
    return ListView.separated(
      key: const Key('strata_pagination_list'),
      controller: controller,
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) => ListTile(title: Text(items[index].name)),
    );
  },
);
```

### 2. Custom Form Fields (`StrataTextField`, `StrataPinCodeField`)
Form field widgets powered by `typed_form_fields` 2.x providing type-safe reactive updates and customizable error indicators.

```dart
StrataTextField(
  name: 'email',
  labelText: 'Email Address',
  showRequiredStar: true,
  onChanged: (val) => print('Email: $val'),
);

StrataPinCodeField(
  name: 'otp',
  length: 6,
  onCompleted: (pin) => verifyOtp(pin),
);
```

### 3. `StrataImage`
Universal image component handling asset, network, file, and SVG formats with shimmer placeholder loading and error fallbacks.

```dart
StrataImage.network(
  'https://example.com/avatar.jpg',
  width: 80,
  height: 80,
  borderRadius: BorderRadius.circular(40),
);
```

### 4. Responsive Layout
- Responsive layout helper `getValueForScreenType(context, mobile: 16, tablet: 24, desktop: 32)`

## Running Tests & Audits

Run static analysis and tests inside the `strata_ui` directory:

```bash
cd strata_ui
flutter analyze
flutter test
```
