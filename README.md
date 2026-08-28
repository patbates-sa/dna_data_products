# SA Demo 2.0: Sales Analytics

## Repository/project map

| Project | Repository | dbt Platform |
|---------|-----------|-----------|
| Terraform Infrastructure | [sa-demo-terraform](https://github.com/dbt-labs/sa-demo-terraform) | — |
| Data Engineering | [sa_demo_data_eng](https://github.com/dbt-labs/sa_demo_data_eng) | [Open in dbt Platform](https://tr995.us1.dbt.com/deploy/70437463654940/projects/70437463662253) |
| Sales Analytics | [sa_demo_da_sales](https://github.com/dbt-labs/sa_demo_da_sales) | [Open in dbt Platform](https://tr995.us1.dbt.com/deploy/70437463654940/projects/70437463662273) |
| Marketing Analytics | [sa_demo_da_marketing](https://github.com/dbt-labs/sa_demo_da_marketing) | [Open in dbt Platform](https://tr995.us1.dbt.com/deploy/70437463654940/projects/70437463662272) |
| Data Science | [sa_demo_ds](https://github.com/dbt-labs/sa_demo_ds) | [Open in dbt Platform](https://tr995.us1.dbt.com/deploy/70437463654940/projects/70437463662271) |

## Local Development Setup

Follow these steps to run dbt locally on your Mac.

### 1. Set Environment Variables

Open **Terminal** and run:

```bash
open -e ~/.zshrc
```

Add these lines at the end of the file (replace the values with your own):

```bash
export DBT_SNOWFLAKE_USER="your_snowflake_sso_email"
export DBT_DEVELOPMENT_SCHEMA="dbt_yourname"
```

Save the file (**Cmd+S**) and close it. Then reload your shell:

```bash
source ~/.zshrc
```

### 2. Verify Your Setup

Test your connection (a browser window will open for SSO login):

```bash
dbt debug
```

You should see "All checks passed!" if everything is configured correctly.

## Mesh validation

This project provides two complementary ways to validate dbt Mesh conventions: the `validate_mesh` macro and dbt Wizard's validation workflow.

### Validation workflows

| Workflow | What it does |
|---|---|
| dbt Wizard validation | Runs the appropriate validation workflow, reports Mesh violations, and can help investigate or remediate them. |
| `dbt build --select ...` | Runs the `on-run-start` hook against the resources selected by the command. A violation fails the build before the selected resources run. |
| `dbt build` with no selector | Runs the hook against the normal full-project selection. A violation fails the build. |
| `dbt run-operation validate_mesh` | Runs the macro directly. Use `selected_only: false` for a full-graph audit, or pass an explicit `selected_ids` list for selected-resource validation. |

### Using the macro directly

