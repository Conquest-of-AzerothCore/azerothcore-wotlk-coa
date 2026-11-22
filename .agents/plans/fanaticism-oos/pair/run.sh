#!/bin/bash
# usage: run.sh <n> <stages>
cd /home/fab/Projects/coa-wt-sun-cleric-oos || exit 1
df -h /home | tail -1
coa-verify --worktree /home/fab/Projects/coa-wt-sun-cleric-oos --ram --stages "$2" --gameplay-db-workers 4 --scenario $(cat .agents/plans/fanaticism-oos/pair/scenarios.txt) > .agents/plans/fanaticism-oos/pair/run$1.log 2>&1
echo "exit $?" >> .agents/plans/fanaticism-oos/pair/run$1.log
