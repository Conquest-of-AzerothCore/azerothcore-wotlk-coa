# Contributing to this CoA fork

Keep the core and the CoA server component coherent. Include the applicable generator/policy and tests with a change.
Do not upload client archives, private captures, credentials or live DB dumps.

Read AGENTS.md and the relevant `.agents/docs` instructions. Preserve applied SQL bytes and existing player progress.
Record source/native checks, linked builds, deployment and real gameplay tests separately. Do not infer gameplay acceptance
from a compiler or an open server port. Builds/deployments are explicit operations, not part of every edit.

Use focused changes, preserve upstream attribution, and report remaining verification limits in the PR.
GitHub Actions currently performs repository checks only; it does not claim to validate a server build.
The inherited upstream workflows and issue templates are kept under `.github/upstream-*` for reference.
