---
description: Calibrate MiMo Token Plan credits for the deepseek-status status line
argument-hint: <used credits> / <total credits>
allowed-tools: Bash(bash *)
---

Run the MiMo Token Plan calibration helper with the provided usage numbers.

Calibration result:

!`script="${CLAUDE_PLUGIN_ROOT}/scripts/mimocorrection.sh"; if [[ ! -f "$script" ]]; then script="$PWD/scripts/mimocorrection.sh"; fi; bash "$script" $ARGUMENTS`

Report the result to the user. If the helper prints usage information or an error, explain the expected format:

`/mimocorrection 20,720,328 / 700,000,000`
