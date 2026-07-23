# Project Instructions

## Git & GitHub activity

- Never add any Claude/AI attribution, signature, or "Co-Authored-By" trailer to commit
  messages, PR titles/descriptions, GitHub issues, issue/PR comments, or any other
  git/GitHub content in this repo. Write commit messages and issue/PR content exactly as
  the user would write them themselves — no mention of Claude or AI assistance anywhere.
- Never run `git commit` or `git push` unprompted — stage changes and give the commit
  message for the user to run themselves, unless explicitly told otherwise.
- This is a personal project — GitHub account must be `atkaridarshan04`, never the work
  account (`darshan-calfus`). Before running any `gh` command that creates or modifies
  GitHub-side content (`gh issue create`, `gh pr create`, comments, etc.), first run
  `gh auth status` to check the active account. If it isn't `atkaridarshan04`, run
  `gh auth switch --hostname github.com --user atkaridarshan04` before proceeding. Do not
  switch back afterward — leave `atkaridarshan04` active and let the user switch back
  manually if/when they move to work on something else.
