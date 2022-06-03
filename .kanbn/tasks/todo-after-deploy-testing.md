---
created: 2022-06-03T15:50:37.233Z
updated: 2022-06-03T15:53:42.146Z
assigned: ""
progress: 0
tags: []
---

# TODO-after-deploy-testing

## Sub-tasks

- [ ] make the contracts as abstract which are not to be deployed.
- [ ] ☐ Clear the commented state variables (already present in the .sol files): state vars, using statements
- [ ] remove `setAddresses()` function from all the main contracts & shift to `LibMojoDiamond.sol` file.
- [ ] replace `msg.sender` with `_msgSender()` in all files.
- [ ] comment `stabilityPoolAddress`, stability pool wherever used - `require`, `setAddresses()`
- [ ] remove SP from `_requireCallerIsBOorTroveMorTMLorSP`
