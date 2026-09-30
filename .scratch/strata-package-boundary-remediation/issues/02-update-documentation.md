# 02: Update documentation to match reality

**What to deliver:** Documentation that accurately reflects the framework's 6-sub-package structure and complete vocabulary — GLOSSARY, spec 0001, and README all synchronized with the actual codebase.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Add missing GLOSSARY entries: `NetworkExceptionMapperInterface`, `PaginationCacheAdapterInterface`, `PaginationCachePolicy`, `StrataPaginationConfig`, `StrataScrollableContentWithFab`, `ValueSelectorCubit` / `SingleSelectorCubit` / `MultiSelectorCubit`, `NetworkStatusCubit`, `StrataBlocObserver`, `Identifiable<T>`, `PaginationParamsInterface`
- [x] Update `ai_specs/0001-strata-framework-migration/spec.md` to remove the `strata_navigation` package definition and all references to it
- [x] Update README to say "6 sub-packages" instead of "7" (title, package table, Melos commands section)
- [x] Remove `navigationConfig` / `NavigationConfigEntity` references from README code examples
- [x] Verify all GLOSSARY `_Avoid_` lists match actual codebase naming
