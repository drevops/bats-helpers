# Interactive scripts

A script that asks questions is driven by naming it in `SCRIPT_FILE` and handing `tui_run` one answer per prompt, in the order the script asks for them:

```bash
@test "Installer" {
  export SCRIPT_FILE="./install.sh"

  tui_run "My site" "" "yes"

  assert_output_contains "Installation complete"
}
```

Source: [`src/tui.bash`](../src/tui.bash)

| Function                  | Description                                                          | Arguments      | Returns |
|---------------------------|----------------------------------------------------------------------|----------------|---------|
| `tui_run`                 | Runs the script named by `SCRIPT_FILE`, feeding it answers on STDIN  | `[answers...]` | None    |
| `tui_assert_prompts`      | Asserts the prompts appeared in order, ignoring case                 | `[prompts...]` | None    |
| `tui_assert_prompts_case` | Asserts the prompts appeared in order, case-sensitively              | `[prompts...]` | None    |

| Variable                   | Read by                                         | Description                                                   |
|----------------------------|-------------------------------------------------|---------------------------------------------------------------|
| `SCRIPT_FILE`              | `tui_run`                                       | Path to the script to run, relative to the current directory  |
| `BATS_HELPERS_TUI_TIMEOUT` | `tui_run`                                       | Whole seconds the script is given to finish. Defaults to `60`  |
| `BATS_HELPERS_TUI_ANSWERS` | `tui_assert_prompts`, `tui_assert_prompts_case` | Set by `tui_run` to the number of answers submitted           |

Each answer is submitted followed by a newline, and an empty answer submits a blank line, so a prompt is left at its default by passing `""`. Every other answer reaches the script byte for byte: an apostrophe, a `%` directive, a backslash escape or a space is not decoded on the way in.

`tui_run` fills `output`, `status` and `lines` the way `run` does, so the script is asserted on with the usual command assertions.

## Deadline

Every run is bounded. A script that keeps asking after its answers are spent is terminated and reported, rather than blocking until the whole suite is killed:

```text
-- Script did not finish within the deadline --
script (1 line):
./install.sh
deadline (1 line):
60 second(s)
elapsed (1 line):
60 second(s)
output (2 lines):
Welcome to the installer
Site name: 
--
```

The report carries everything the script printed before it was terminated, so the last prompt it reached names the answer that is missing.

`BATS_HELPERS_TUI_TIMEOUT` sets the deadline, and defaults to `60`:

```bash
export BATS_HELPERS_TUI_TIMEOUT=5
```

It is in whole seconds, because `SECONDS` is the only clock available across the Bash versions the library supports. It cannot be turned off: a script that legitimately takes longer is given a larger number, which keeps every run bounded by something.

## Prompt order

Answers are matched to prompts by position alone, so a test that answered every question one field early looks exactly like one that answered correctly. `tui_assert_prompts` asserts what the script asked, and in which order:

```bash
tui_run "My site" "" "yes"

tui_assert_prompts "Site name" "Machine name" "Install profile"
```

Each prompt is searched for in what is left of the output after the prompt before it matched, so the same prompts in another order are reported rather than passed:

```text
-- Prompt does not appear in the remaining output --
prompt (1 line):
Install profile
matched (1 line):
2 of 3
match mode (1 line):
literal
case (1 line):
insensitive
remaining output (2 lines):
 [my_site]: 
Installation complete
--
```

The remainder starts immediately after the prompt that matched, which is why it opens mid-line.

The number of prompts must also match the number of answers the last run submitted, in either direction, which is what catches an answer sequence that has drifted:

```text
-- Answer count does not match the prompt count --
answers : 3
prompts : 2
--
```

`BATS_HELPERS_TUI_ANSWERS` holds that count. Calling the assertion before any script has run is an error rather than a pass.

A prompt is matched as a substring, ignoring case; `tui_assert_prompts_case` matches case-sensitively. A prompt that is not found is reported with the match mode and the case setting that were in force, and with a note when the opposite setting would have found it, exactly as the [match mode](match-modes.md) assertions report. Only what the script prints itself can be asserted on: Bash writes a `read -p` prompt only when STDIN is a terminal, so a script asking that way leaves nothing in the output to match.

Nothing in the output marks a prompt as one, either. A script that echoes its answers back can therefore satisfy a prompt with an answer holding the same text, so pick prompt text an answer cannot stand in for.
