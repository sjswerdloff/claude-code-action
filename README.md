# Claude Code Action (Security Enhanced Fork)

A GitHub Action for running [Claude Code](https://github.com/anthropics/claude-code) on your repository with enhanced security features. This fork of the original action adds several security improvements while maintaining the core functionality.

## Description

This action allows you to run Claude Code in your GitHub Actions workflow with additional security measures. Claude Code is an agentic coding tool from Anthropic that understands your codebase, and helps you code through natural language commands.

## Security Enhancements

This fork includes the following security improvements:

1. **Isolated branch workflow** - Changes are made on a separate branch and submitted as PRs for review
2. **Security-focused prompt prefixing** - Automatically adds security guidance to all prompts
3. **Protected paths** - Prevents access to sensitive files and directories
4. **PR review workflow** - Creates PRs with mandatory review checklists
5. **Improved isolation** - Uses the same container isolation but with better data protection

## Prerequisites

- An Anthropic API key
- GitHub token with PR creation permissions (Ensure that this token is stored securely as a secret, for example as secrets.GITHUB_TOKEN)

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `prompt` | The prompt to send to Claude Code | Yes |
| `acknowledge-dangerously-skip-permissions-responsibility` | Set to "true" to acknowledge that you have read and agreed to the disclaimer shown when running `claude code --dangerously-skip-permissions` | Yes |

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `ANTHROPIC_API_KEY` | Your Anthropic API key | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `result` | The output from Claude Code |

## Usage

```yaml
name: Run Claude Code with Security Enhancements

on:
  workflow_dispatch:
    inputs:
      prompt:
        description: 'Describe the bug to fix'
        required: true
        type: string
  issues:
    types: [opened, labeled]

jobs:
  run-claude-code:
    # Only run if the issue has the "ai-fix" label or for manual workflow_dispatch
    if: github.event_name == 'workflow_dispatch' || contains(github.event.issue.labels.*.name, 'ai-fix')
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          # Fetch full history for proper PR creation
          fetch-depth: 0

      # If triggered by an issue, get the issue body as the prompt
      - name: Get issue content
        if: github.event_name == 'issues'
        id: issue
        run: |
          echo "ISSUE_BODY<<EOF" >> $GITHUB_ENV
          echo "${{ github.event.issue.body }}" >> $GITHUB_ENV
          echo "EOF" >> $GITHUB_ENV

      - name: Run Claude Code
        id: claude
        uses: sjswerdloff/claude-code-action@main
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          # Use issue body as prompt if available, otherwise use workflow input
          prompt: ${{ github.event_name == 'issues' && env.ISSUE_BODY || github.event.inputs.prompt }}
          acknowledge-dangerously-skip-permissions-responsibility: "true"

      # Comment on the issue if that's what triggered this
      - name: Comment on issue
        if: github.event_name == 'issues'
        uses: actions/github-script@v6
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Claude has analyzed this issue and created a PR with a potential fix. Please review the changes.'
            })
```

## About the `--dangerously-skip-permissions` Flag and Security Mitigations

This action uses the `--dangerously-skip-permissions` flag with Claude Code, which allows Claude to modify files without permission prompts. However, this fork implements several security mitigations to reduce the risks:

1. **All changes are made on a separate branch** - No direct modifications to your main branch
2. **Changes are submitted as Pull Requests** - Requires human review before merging
3. **Protected paths configuration** - Sensitive files are excluded from Claude's access
4. **Security-focused prompts** - Automatic prefixing with security instructions
5. **Review checklist** - Standardized checklist for reviewing AI-generated code

By setting `acknowledge-dangerously-skip-permissions-responsibility` to "true", you acknowledge that you understand the remaining risks despite these mitigations.

## How This Enhances Security

The original action allowed Claude to make changes directly to your repository. This enhanced version:

1. Creates changes on an isolated branch
2. Automatically creates a PR that requires review
3. Blocks modifications to security-sensitive paths
4. Enforces a review process with a security checklist
5. Can be triggered from issues with specific labels for better control

## Output

The action will modify files on a new branch and create a Pull Request. It will output a summary from Claude Code to the workflow logs. The output is also available as the `result` output variable. If triggered from an issue, it will also comment on the issue with a link to the created PR.

## License

See the [LICENSE](LICENSE) file for details.
