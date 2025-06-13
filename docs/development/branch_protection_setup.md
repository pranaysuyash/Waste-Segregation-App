# Branch Protection Setup Guide

## 🛡️ Setting Up Required Status Checks

This guide shows you how to configure branch protection rules that require specific CI checks to pass before merging to main.

## **Step 1: Push CI Workflows to Repository**

First, ensure all CI workflows are committed and pushed:

```bash
git add .github/workflows/
git commit -m "Add CI workflows for branch protection"
git push origin main
```

## **Step 2: Configure Branch Protection Rules**

### **GitHub Repository Settings:**

1. **Navigate to Repository Settings**
   - Go to your repository on GitHub
   - Click **Settings** tab
   - Click **Branches** in the left sidebar

2. **Add Branch Protection Rule**
   - Click **Add rule**
   - Branch name pattern: `main`

3. **Configure Required Settings:**

#### ✅ **Essential Rules (Recommended):**

- **☑️ Require a pull request before merging**
  - Require approvals: `1`
  - Dismiss stale PR approvals when new commits are pushed: `✓`
  - Require review from code owners: `✓` (if you have CODEOWNERS file)

- **☑️ Require status checks to pass before merging**
  - Require branches to be up to date before merging: `✓`
  - **Required status checks:**
    - `Build Flutter App` (from build_and_test.yml)
    - `Run Tests` (from build_and_test.yml)  
    - `Golden Tests & Visual Diff` (from build_and_test.yml)
    - `Code Quality` (from build_and_test.yml)

- **☑️ Require linear history**
  - Prevents merge commits, keeps history clean

- **☑️ Block force pushes**
  - Prevents destructive force pushes to main

#### ⚠️ **Optional Rules (Consider for high-security projects):**

- **☐ Require signed commits**
  - Only if your team uses GPG signing

- **☐ Restrict pushes that create files that exceed 100MB**
  - Prevents large file commits

- **☐ Restrict creations/updates/deletions**
  - Only for highly restricted repositories

## **Step 3: Verify Status Checks Are Available**

After pushing your workflows, GitHub needs to see them run at least once:

1. **Create a test PR** to trigger the workflows
2. **Check that status checks appear** in the branch protection settings
3. **Select the required checks** from the dropdown

### **Expected Status Checks:**

```
✅ Build Flutter App
✅ Run Tests  
✅ Golden Tests & Visual Diff
✅ Code Quality
```

## **Step 4: Test the Protection**

1. **Create a test branch:**
   ```bash
   git checkout -b test-branch-protection
   echo "test" > test_file.txt
   git add test_file.txt
   git commit -m "Test branch protection"
   git push origin test-branch-protection
   ```

2. **Create a PR** and verify:
   - ❌ Merge button is disabled until checks pass
   - 🔄 Status checks are running
   - ✅ Merge becomes available after all checks pass

## **Step 5: Configure Status Check Behavior**

### **For Golden Tests Specifically:**

The golden test workflow will:
- ✅ **Pass** if no visual changes detected
- ❌ **Fail** if visual regressions found
- 📊 **Comment on PR** with visual diff details
- 📁 **Upload artifacts** with before/after images

### **Handling Golden Test Failures:**

When golden tests fail in a PR:

1. **Download the artifacts** to see visual diffs
2. **Determine if changes are intentional:**
   - **Intentional**: Update golden files and commit
   - **Regression**: Fix the UI issue

3. **Update golden files if needed:**
   ```bash
   ./scripts/testing/golden_test_manager.sh update
   git add test/golden/
   git commit -m "Update golden files for intentional UI changes"
   git push
   ```

## **Step 6: Team Workflow**

### **For Developers:**
- All changes must go through PRs
- Status checks must pass before merge
- Visual regressions block merges automatically

### **For AI Agents:**
- Same rules apply - no direct pushes to main
- Golden test failures provide clear feedback
- Visual diff artifacts help understand changes

## **🎯 Benefits of This Setup**

### **Protection:**
- 🛡️ **No broken deployments** - main branch stays stable
- 🎨 **Visual regression protection** - UI changes are caught automatically
- 📊 **Quality gates** - code quality and tests must pass

### **Speed:**
- 🚀 **Confident rapid development** - regressions caught automatically
- 🤖 **AI-friendly** - clear pass/fail feedback for agents
- 📈 **Scalable** - works for teams of any size

## **Troubleshooting**

### **Status Checks Not Appearing:**
1. Ensure workflows are in `.github/workflows/` directory
2. Push workflows to main branch first
3. Trigger workflows by creating a test PR
4. Wait for workflows to complete at least once

### **Golden Tests Always Failing:**
1. Run `./scripts/testing/golden_test_manager.sh update` to generate initial golden files
2. Commit the golden files to establish baseline
3. Subsequent runs will compare against these baselines

### **Build Failures:**
1. Check workflow logs in GitHub Actions tab
2. Ensure Flutter version matches your local development
3. Verify all dependencies are properly specified

## **Example Branch Protection Configuration**

```yaml
# Example configuration (for reference)
Branch Protection Rules for 'main':
  ✅ Require a pull request before merging
    - Require approvals: 1
    - Dismiss stale PR approvals: ✓
    - Require review from code owners: ✓
  
  ✅ Require status checks to pass before merging
    - Require branches to be up to date: ✓
    - Required status checks:
      ✅ Build Flutter App
      ✅ Run Tests
      ✅ Golden Tests & Visual Diff  
      ✅ Code Quality
  
  ✅ Require linear history
  ✅ Block force pushes
  ❌ Require signed commits (optional)
  ❌ Restrict creations (optional)
  ❌ Restrict updates (optional)
  ❌ Restrict deletions (optional)
```

This setup provides comprehensive protection while maintaining development velocity! 🚀 