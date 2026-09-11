# Return Codes

IASI Quarto returns a cumulative bitmask.

The low nibble describes non-error outcomes:

```text
0x00  OK
0x01  NothingToDo
0x02  Info
0x04  Warning
0x08  Attention
```

The high nibble is reserved for errors:

```text
0x10  Error
0x20  Severe
0x40  Fatal
0x80  Reserved
```

Return-code values are accumulated with bitwise OR. The final value therefore
summarizes every relevant condition observed during an action.

The execution context owns the cumulative value as `context$rc`.

Examples:

```text
0x09 = NothingToDo + Attention
0x14 = Warning + Error
```

`NothingToDo` means the operation was valid but did not require effective work.
It also applies when an action does not apply to a discovered project.

Missing or invalid IASI project types are `Attention`: they do not abort
discovery, but they indicate configuration that should be reviewed.

Every error condition must set an error bit before execution unwinds. The public
action wrapper guarantees `Error` for otherwise-unclassified `stop()` calls.
Specific code may set a stronger error bit before stopping.

Public API functions return the cumulative bitmask invisibly.
