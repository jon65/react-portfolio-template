# CI/CD Workflow Execution Order

This repository uses **chained workflows** that execute in a specific order using GitHub Actions `workflow_run` triggers.

## Workflow Execution Flow

```
┌─────────────────┐
│   Push to main  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  1. CI Workflow │  ← Runs on every push/PR
│  (ci.yml)       │
│  - Build        │
│  - Test         │
└────────┬────────┘
         │ (if successful)
         ▼
┌─────────────────┐
│ 2. Deploy       │  ← Triggers automatically
│    Staging      │     after CI succeeds
│ (deploy-        │
│  staging.yml)   │
└────────┬────────┘
         │ (if successful)
         ▼
┌─────────────────┐
│ 3. Deploy       │  ← Triggers automatically
│    Production   │     after staging succeeds
│ (deploy-        │     OR can be manual
│  production.yml)│
└─────────────────┘
```

## Workflow Files

### 1. `ci.yml` - Continuous Integration
**Triggers:**
- On every push to any branch
- On pull requests to `main`
- Manual trigger (`workflow_dispatch`)

**Jobs:**
- `build`: Compiles the application
- `test`: Runs tests and linting

**Output:**
- Build artifacts (uploaded for 7 days)

---

### 2. `deploy-staging.yml` - Staging Deployment
**Triggers:**
- Automatically after `ci.yml` completes successfully on `main` branch
- Manual trigger (`workflow_dispatch`)

**Jobs:**
- `deploy-staging`: Deploys to staging environment

**Conditions:**
- Only runs if CI workflow succeeded
- Uses `staging` environment (can require approval)

---

### 3. `deploy-production.yml` - Production Deployment
**Triggers:**
- Automatically after `deploy-staging.yml` completes successfully
- Manual trigger (`workflow_dispatch`) - recommended for production

**Jobs:**
- `deploy-production`: Deploys to production environment

**Conditions:**
- Only runs if staging deployment succeeded (or manual trigger)
- Uses `production` environment (should require approval)

---

## How `workflow_run` Works

The `workflow_run` trigger allows one workflow to trigger after another completes:

```yaml
on:
  workflow_run:
    workflows: ["CI - Build and Test"]  # Name of the workflow to wait for
    types:
      - completed                       # Wait for completion
    branches:
      - main                            # Only on main branch
```

**Key Points:**
- The workflow name must match exactly (case-sensitive)
- `types: completed` means it triggers regardless of success/failure
- Use `if: github.event.workflow_run.conclusion == 'success'` to only run on success
- The triggered workflow runs on the default branch, so use `github.event.workflow_run.head_sha` to checkout the correct commit

---

## Manual Execution

You can manually trigger any workflow:
1. Go to **Actions** tab in GitHub
2. Select the workflow you want to run
3. Click **Run workflow** button
4. Select branch and click **Run workflow**

---

## Environment Protection

Set up environment protection rules in GitHub:
1. Go to **Settings** → **Environments**
2. Create `staging` and `production` environments
3. Add required reviewers for production
4. Add deployment branches (e.g., only `main`)

This ensures production deployments require approval.

---

## Troubleshooting

### Workflow not triggering
- Check that workflow names match exactly
- Verify the triggering workflow completed (check Actions tab)
- Ensure you're on the correct branch (`main`)

### Artifacts not found
- Artifacts are only available for 7 days (configured in `ci.yml`)
- Each workflow rebuilds the application to ensure consistency

### Deployment fails
- Check EC2 secrets are configured correctly
- Verify SSH key has proper permissions
- Check EC2 security group allows SSH from GitHub Actions IPs

