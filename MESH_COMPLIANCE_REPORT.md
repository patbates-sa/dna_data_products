# Hub-and-Spoke Mesh Compliance Report

**Project:** `da_sales`  
**dbt Platform project:** `pd_da_sales` (`70437463666928`)  
**Assessment date:** 2026-08-21  
**Assessment status:** Promotion blocked  
**Target architecture role:** Gold product spoke  
**Producer dependency:** `data_engineering`

## Executive summary

`da_sales` is not compliant with the Hub-and-Spoke Mesh standard. The project has a valid cross-project dependency and one well-defined public mart, but its current DAG does not enforce the Silver-to-Gold boundary or the required Gold `stage → int → mart` structure.

The highest-priority issues are:

1. A Gold model reads directly from a raw source.
2. The cross-project reference to `data_engineering.fct_order_items` is not version-pinned.
3. All local model paths fall outside the required Gold folder structure, and both flows skip required layers.
4. `agg_customer_returns` is a protected, uncontracted mart.
5. The Mesh validation macro targets unrelated default project names and does not reliably enforce compliance in CI.
6. The local source is stale, and producer-before-consumer execution is not enforced by job configuration.

The project should not be promoted as Mesh-compliant until all critical and high-severity findings are closed and the promotion gates in this report pass.

## Scope and evidence

This assessment covers:

- `dbt_project.yml`, `dependencies.yml`, and `packages.yml`
- All three local SQL models and their YAML definitions
- Group ownership and source configuration
- Parsed dbt manifest metadata for local and imported models
- `validate_mesh` macro behavior
- Source freshness
- Consumer and producer production/CI job configuration and recent production runs

Evidence collected:

- `dbt parse --no-partial-parse`: passed
- `dbt ls --resource-type model --output json`: passed
- `dbt run-operation validate_mesh`: failed because no models matched the configured `dna_data_products` project name
- `dbt run-operation validate_mesh --vars '{"mesh_products_project":"da_sales","mesh_domain_project":"data_engineering"}'`: found four Mesh violations
- `dbt source freshness --select source:ads.ad_spend`: warned stale
- Latest consumer production `dbt build`: passed with no warnings
- Latest producer production `dbt build`: passed
- Selected local build discovered 3 models and 9 tests, but dbt State reused all 12 nodes; this was not a fresh execution

Repository findings reflect the current development branch. Production run evidence reflects the commits recorded by dbt Platform and may not be identical to the current branch.

## Compliance scorecard

| Control area | Status | Evidence |
|---|---|---|
| Project dependency | Partial | `dependencies.yml` declares `data_engineering`; Mesh vars point to unrelated project names. |
| Gold layer structure | Fail | Models use `models/0_staging/` and `models/2_marts/`; there is no product-scoped `stage → int → mart` flow. |
| Silver-to-Gold boundary | Fail | `stg_ad_spend` calls `source('ads', 'ad_spend')` directly from the product project. |
| Cross-project version pinning | Fail | `ref('data_engineering', 'fct_order_items')` has no `version` argument. |
| Gold public interfaces | Partial | `dim_ad_spend_per_adv` is public and contracted; `agg_customer_returns` is protected and uncontracted. |
| Ownership | Pass | The `sales` group has a named owner and email; both marts are assigned to it. |
| Key data tests | Partial | Both marts have uniqueness and not-null coverage; no relationship tests are defined. |
| Schema conventions | Fail | No explicit `stage` schema for Gold stage/int or consumer schema for Gold marts. |
| Materialization controls | Pass / N/A | All local models are tables; no incremental boundaries require review. |
| Freshness gates | Fail | `ads.ad_spend` was about 1 year and 6 months stale at assessment time. |
| Orchestration | Partial | Producer and consumer jobs are separate, but schedules are disabled and no completion dependency is configured. |
| CI compliance enforcement | Fail | Sales CI has no completed runs, and its validator uses incorrect project defaults. |

## Findings and remediation

### MESH-001 — Gold reads a raw source

**Severity:** Critical  
**Owner:** Domain producer and Sales product teams  
**Evidence:** `models/0_staging/stg_ad_spend.sql` uses `source('ads', 'ad_spend')`.

Gold projects must consume published Silver interfaces. Raw-source ingestion and domain-standard preparation belong in the domain producer.

**Required remediation:**

- Move ownership of the `ads` source and reusable ad-spend preparation into `data_engineering`.
- Publish a public Silver mart with a formal group owner, enforced typed contract, key tests, and a model version.
- Add a Sales Gold stage model that consumes the published interface through a version-pinned cross-project `ref()`.

**Acceptance criteria:**

- No local Gold model depends on a `source` node.
- The imported ad-spend model is public, contracted, tested, owned, and versioned.
- The Sales consumer ref specifies the producer project and model version.

### MESH-002 — Cross-project ref is not version-pinned

**Severity:** Critical  
**Owner:** Data Engineering producer and Sales product teams  
**Evidence:** `models/2_marts/agg_customer_returns.sql` uses `ref('data_engineering', 'fct_order_items')`; parsed metadata reports `version: null`.

**Required remediation:**

- Publish a supported version of `fct_order_items` in `data_engineering`.
- Update the consumer to use an explicit version, for example `version=1`.

**Acceptance criteria:**

- Every cross-project ref in `da_sales` has an explicit version.
- CI fails when an unversioned cross-project ref is introduced.

### MESH-003 — Gold flows do not follow `stage → int → mart`

**Severity:** High  
**Owner:** Sales product team  
**Evidence:** All local models fail the validator's path rule when it is run with the actual project names. There is no Gold int layer.

**Required remediation:**

- Organize product models under `models/sales/stage/`, `models/sales/int/`, and `models/sales/mart/`.
- Route the customer-returns and ad-spend flows through each required layer.
- Keep stage and int models protected; make final Gold marts public.

**Acceptance criteria:**

- Every Gold mart has a local int parent and a local stage ancestor.
- Gold stage models consume only public, versioned Silver interfaces.
- Gold stage/int models are protected and Gold marts are public.

### MESH-004 — `agg_customer_returns` is not a contracted public mart

**Severity:** High  
**Owner:** Sales product team  
**Evidence:** The parsed model has protected access, no enforced contract, and no declared column data types.

The model also applies `limit 100` after ordering by `customer_key`. This silently truncates the product and does not define “top” customers using a business measure.

**Required remediation:**

- Set public access and enforce a typed contract.
- Retain the `sales` group assignment and existing key tests.
- Add relationship tests where a stable customer interface is available.
- Remove the arbitrary row limit, or explicitly define and name a top-customer product using a deterministic business ranking.

**Acceptance criteria:**

- The mart is public, owned, typed, contracted, documented, and tested.
- Its output grain and inclusion rules are explicit and deterministic.

### MESH-005 — Mesh validator is misconfigured and incomplete

**Severity:** High  
**Owner:** Sales product team / dbt platform maintainers  
**Evidence:** `dbt_project.yml` sets `mesh_products_project: dna_data_products` and `mesh_domain_project: dna_data_domain`. The local project is `da_sales`, and its producer is `data_engineering`.

With defaults, the validator reports only that no product models were found. With actual names, it reports four violations: three invalid model paths and one direct source dependency. The macro does not enforce version-pinned ref syntax and does not prove strict `stage → int → mart` lineage.

**Required remediation:**

- Set project-specific producer and consumer names correctly.
- Extend validation to enforce version pins, layer-to-layer dependencies, schemas, public mart contracts, and access rules.
- Keep validation in CI before build/promotion.

**Acceptance criteria:**

- The validator inspects all local models in CI.
- Known violations fail CI with model-specific messages.
- A compliant test fixture passes and representative anti-pattern fixtures fail.

### MESH-006 — Source freshness is outside the readiness threshold

**Severity:** High  
**Owner:** Source owner and Data Engineering producer team  
**Evidence:** `ads.ad_spend` warned as last updated about 1 year and 6 months before assessment, exceeding its 365-day warning threshold.

**Required remediation:**

- Confirm whether the feed is abandoned, broken, or intentionally static.
- Restore the feed or retire the dependent product.
- Set an operationally meaningful freshness SLA and run freshness before downstream builds.

**Acceptance criteria:**

- Source freshness passes the agreed SLA.
- Stale producer data blocks or alerts before the Sales product build.

### MESH-007 — Producer-before-consumer ordering is not enforced

**Severity:** Medium  
**Owner:** dbt platform/orchestration maintainers  
**Evidence:** Producer and consumer production jobs are separate and their latest runs completed in the correct order, but schedules are disabled and no job-completion dependency is configured.

**Required remediation:**

- Trigger the Sales job only after successful producer completion, or use a documented schedule offset plus freshness/readiness checks.
- Keep producer and consumer as separate jobs.
- Include source freshness, build, and test gates in the controlled sequence.

**Acceptance criteria:**

- Consumer execution cannot start before successful producer completion for the same load window.
- A failed or stale producer blocks the consumer.
- Job ownership and rollback steps are documented.

### MESH-008 — Avoidable schema-drift exposure in the ad-spend mart

**Severity:** Low  
**Owner:** Sales product team  
**Evidence:** `dim_ad_spend_per_adv.sql` uses `select *` in its input CTE.

**Required remediation:**

- Select the required input columns explicitly.
- Preserve the enforced output contract.

**Acceptance criteria:**

- The model references only required upstream columns by name.

## Existing compliant elements

- `dependencies.yml` uses a dbt cross-project dependency instead of vendoring producer code.
- `stg_ad_spend` selects explicit source columns.
- `dim_ad_spend_per_adv` has public access, a formal group, an enforced typed contract, documentation, uniqueness testing, and not-null testing.
- Both local marts have documented grains and key tests.
- A formal `sales` group owner is defined.
- Producer and consumer production builds most recently completed successfully.
- No duplicate producer/consumer incremental merge boundary exists because all local models are tables.

## Promotion gates

Promotion remains blocked until all of the following are true:

- [ ] Gold contains no direct `source()` dependencies.
- [ ] Every cross-project ref is explicitly version-pinned.
- [ ] Every Gold flow follows `stage → int → mart`.
- [ ] Gold stage/int models are protected and Gold marts are public.
- [ ] Every public mart has a formal group owner and enforced typed contract.
- [ ] Key uniqueness, not-null, and applicable relationship tests pass.
- [ ] Schemas follow the approved `stage` and consumer schema conventions.
- [ ] Source freshness passes an approved SLA.
- [ ] Producer completion and load-window readiness are enforced before consumer execution.
- [ ] Corrected Mesh validation passes in CI.
- [ ] Producer and consumer builds/tests pass without warnings.
- [ ] Outputs are reconciled against the current products.
- [ ] A rollback plan is documented and approved.

## Recommended implementation sequence

1. Correct and strengthen the Mesh validator so subsequent changes are gated accurately.
2. Publish versioned, contracted Silver interfaces for ad spend and order items.
3. Refactor Sales into product-scoped Gold stage, int, and mart folders.
4. Add version-pinned refs and complete mart contracts/tests.
5. Reconcile refactored outputs against current production relations.
6. Add freshness and producer-completion orchestration gates.
7. Run producer and consumer CI/build gates and document rollback before promotion.
