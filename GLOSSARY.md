# Strata Framework Terminology

Canonical domain terminology for the Strata Flutter monorepo architecture.

## Terminology

**Strata**:
The modular, multi-package Flutter/Dart framework suite replacing the monolithic coore package.
_Avoid_: coore v2, coore_monorepo

**Strata Storage**:
The infrastructure package (`strata_storage`) responsible for token persistence contracts, secure key management, and database setup helpers without wrapping native database APIs.
_Avoid_: NoSqlDatabaseInterface, LocalDatabaseWrapper

**SensitiveStorageInterface**:
The focused key-value abstract interface in `strata_core` specifically designed for reading, saving, deleting, and clearing encrypted string data (auth tokens, API keys).
_Avoid_: SensitiveStorageContract, SecureDatabaseInterface, LocalStorageContract

**Interface Naming Convention**:
All abstract contracts/interfaces use the `Interface` suffix (e.g. `SensitiveStorageInterface`). Concrete implementations prepend the technology/driver name as a prefix before the base name (e.g. `FlutterSecureSensitiveStorage` or `DioApiHandler`).
_Avoid_: `*Contract`, `*Impl` suffix, `I*` prefix

**CancelRequestManagerInterface**:
The network management interface in `strata_network` that tracks and manages Dio `CancelToken` instances for concurrent and cancellable HTTP requests.
_Avoid_: CancelRequestManagerImpl

**TokenManagerInterface**:
The token lifecycle interface in `strata_network` responsible for storing, retrieving, refreshing, and clearing authentication tokens across network requests.
_Avoid_: AuthTokenManager

**StrataLoggerInterface**:
The abstract logging interface in `strata_core` establishing application-wide logging contracts for verbose, debug, info, warning, and error diagnostics.
_Avoid_: CoreLoggerInterface, ILogger

**AsyncState**:
The pure functional union state representation in `strata_core` representing `initial`, `loading`, `success(T data)`, and `failure(Failure failure)` independent of any state management library.
_Avoid_: CoreState, BlocApiState, ApiState

**AsyncHandler**:
The composite delegate in `strata_state` managing loading/success/failure/retry lifecycles and automated request cancellation for an `AsyncState` field within a BLoC/Cubit state.
_Avoid_: ApiStateController, ApiStateHandler, AsyncStateController

**DisposableAsyncHandlerInterface**:
The contract in `strata_state` implemented by `AsyncHandler` for managing disposable state delegates within BLoC/Cubit state hosts without using the legacy `IApiStateHandler` or `DisposableApiStateHandlerInterface` name.
_Avoid_: IApiStateHandler, ApiStateHandlerInterface, DisposableApiStateHandlerInterface

**ApiRequestOptions**:
The immutable configuration class in `strata_network` passed to `ApiHandlerInterface` containing per-request headers, retry options, authorization flags, and progress callbacks.
_Avoid_: RequestOptions, DioOptions, NetworkRequestOptions

**NetworkFormData**:
The framework-agnostic multipart data structure in `strata_network` encapsulating form fields and `NetworkFile` instances without leaking Dio types to host applications.
_Avoid_: FormDataAdapter, DioFormData

**PaginationStrategy**:
The pure, immutable value interface in `strata_core` defining pagination parameters (Page/Offset, Skip/Limit, Cursor) and next-page computation without side effects.
_Avoid_: MutablePaginationStrategy, StatefulPaginationEngine

**StrataPaginationState**:
The sealed union state representation in `strata_state` modeling pagination lifecycle states (`initial`, `loading`, `succeeded`, `refreshing`, `loadingMore`, `failed`, `pageFetchFailure`).
_Avoid_: CorePaginationState, CorePaginationWidgetState, EasyRefreshState

**StrataPaginationBloc**:
The generic state controller in `strata_state` managing paginated network requests, $O(N)$ item deduplication, and concurrency throttling.
_Avoid_: PaginationBloc, PaginationController, CorePaginationCubit, CorePaginationBloc

**StrataPaginationWidget**:
The decoupled presentation component in `strata_ui` providing native platform-adaptive pull-to-refresh (`RefreshIndicator.adaptive`) and infinite scrolling across multi-screen layouts.
_Avoid_: CorePaginationWidget, EasyRefreshWidget, SmartRefresher

**NetworkExceptionMapperInterface**:
The abstract contract in `strata_network` for mapping Dio/network exceptions into domain `Failure` instances. Implemented by `DioExceptionMapper`.
_Avoid_: ExceptionConverter, DioExceptionMapperInterface

**PaginationCacheAdapterInterface**:
The abstract contract in `strata_state` for pluggable offline caching of paginated responses. Implementations handle loading, persisting, and clearing paginated data from local persistence layers (Hive, SQLite, SharedPreferences).
_Avoid_: PaginationCache, CacheAdapterInterface

**PaginationCachePolicy**:
The enum in `strata_core` defining the caching strategy when fetching paginated data (`networkOnly`, `cacheFirst`, `cacheAndNetwork`).
_Avoid_: CacheStrategy, PaginationCacheMode

**StrataPaginationConfig**:
The InheritedWidget in `strata_ui` providing default configuration to descendant `StrataPaginationWidget`s (scroll threshold, builders, platform options).
_Avoid_: PaginationConfig, PaginationInheritedWidget

**StrataScrollableContentWithFab**:
The widget in `strata_ui` wrapping scrollable content with a floating action button that appears on scroll and animates scroll-to-top.
_Avoid_: ScrollableWithFab, FabScrollWidget

**ValueSelectorCubit / SingleSelectorCubit / MultiSelectorCubit**:
The Cubit hierarchy in `strata_state` for managing single and multi-selection of values with immutable state updates.
_Avoid_: SelectorCubit, ValueSelector, MultiSelectCubit

**NetworkStatusCubit**:
The Cubit in `strata_state` managing current network connection status by listening to `NetworkStatusInterface` streams.
_Avoid_: NetworkCubit, ConnectivityCubit

**StrataBlocObserver**:
The BlocObserver in `strata_state` logging events, state changes, transitions, errors, creation, and closure of blocs using `StrataLoggerInterface`.
_Avoid_: CoreBlocObserver, BlocLogger

**Identifiable<T>**:
The abstract interface in `strata_core` for entities with a unique identifier, used by the pagination system for type-safe item deduplication.
_Avoid_: Identifiable (non-generic), Entity, HasId

**NoParams**:
The empty parameter value object in `strata_core` for use cases and requests requiring no arguments, supporting JSON serialization.
_Avoid_: EmptyParams, VoidParams

**IdParam**:
The simple parameter value object in `strata_core` encapsulating a single unique entity ID string with configurable JSON key serialization (`toJson({String? idKey})`).
_Avoid_: SingleIdParam, IdParameters

**PaginationParamsInterface**:
The abstract interface in `strata_core` for pagination parameters with a `requestId` property, constraining the pagination bloc's generic parameter.
_Avoid_: PageParams, RequestIdParams

**PaginationParams**:
The unified sealed parameter hierarchy in `strata_core` (`PagePaginationParams`, `SkipPaginationParams`, `CursorPaginationParams`) implementing `PaginationParamsInterface`, providing JSON serialization (`toJson`, `fromJson`), query parameter flattening (`toQueryParameters`), optional filter extras (`extra`), and automatic `requestId` generation.
_Avoid_: NetworkPaginationParams, ApiPaginationParams

**Strata Skills**:
The curated suite of developer AI agent skills provided by the Strata framework, structured as a top-level router (`strata`) and modular workflow skills (`strata-bootstrap`, `strata-feature`, `strata-pagination`, `strata-auth`).
_Avoid_: Coore Prompts, Strata Rules, Copilot Recipes

**Strata Skills Installer**:
The CLI utility executable in the `strata` package (`dart run strata:install_skills`) responsible for provisioning and updating the Strata agent skill suite in consumer applications.
_Avoid_: SkillSetupScript, StrataCli, SkillCopier

## Example Application Domain

**TodoEntity**:
The domain entity representing an individual task, implementing `Identifiable<String>` for $O(N)$ pagination deduplication, holding `title`, `description`, `isCompleted`, `priority` (`TodoPriority`), `createdAt`, and `Option<DateTime>` `dueDate`.
_Avoid_: Todo, TaskEntity, TaskItem

**TodoPriority**:
The domain enumeration representing task urgency (`low`, `medium`, `high`, `urgent`), used for UI chips, sorting, and priority-based filtering.
_Avoid_: Priority, TaskPriority

**TodoRepositoryInterface**:
The domain repository interface defining operations for fetching paginated todos across all three pagination schemes (`PagePaginationParams`, `SkipPaginationParams`, `CursorPaginationParams`), fetching single todo details, and executing mutations.
_Avoid_: TodoRepositoryContract, ITodoRepository, TodoRepo
