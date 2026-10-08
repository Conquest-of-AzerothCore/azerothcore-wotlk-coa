# Git coordination

- Before any user-authorized push, fetch the target branch and inspect its latest commits.
- Preserve remote commits and unrelated local changes. If the remote advanced, integrate
  its changes and resolve conflicts using both versions before pushing.
- Use normal fast-forward pushes only. Never force-push, reset away remote work, or replace
  another contributor's changes with an older local copy.
- Verify the remote commit after pushing. These rules do not authorize unsolicited pushes.
