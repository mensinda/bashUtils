# Logging

|  Fuction  |            Description           |
|-----------|----------------------------------|
| `msg1`    | Log Info level 1                 |
| `msg2`    | Log Info level 2                 |
| `msg3`    | Log Info level 3                 |
| `msg4`    | Log Info level 4                 |
| `found`   | Special msg for finding          |
| `found2`  | Special msg for finding (level 2)|
| `warning` | Warning                          |
| `error`   | Error                            |

## ask

```bash
ask() {} # 3 Args: <question> <default> <VAR>
```

Prints a question to stdout and reads a line from stdin

| Parameter | Type  |         Description         |
|-----------|-------|-----------------------------|
| question  | `STR` | What to ask for             |
| default   | `ANY` | Default value (empty line)  |
| VAR       | `PTR` | Name of the destenation Var |


# Utils

## printNumChar

```bash
printNumChar() {} # 2 Args: <char> <num>
```

Prints `num` times `char`

## die

Prints [logging](#Loging) message `$*`, a backtrace and exits

## die_badArg

```bash
die_badArg() # 1 Args: <badArg>
```

Prints a badArg error and [dies](#die)

## die_parseError

```bash
die_parseError() {} # 1 Args: <filename>
```

Prints a parseError error and [dies](#die)

## die_expected

```bash
die_expected() {} # 2 Args: <expected> <wrong string>
```

## argsRequired

```bash
argsRequired() {} # 2 Args: <expected args> <num args>
```

[Dies](#die) if `expected args` != `num args`

## fileRequired

```bash
fileRequired() {} # 2 Args: <filename> <error>
```

Test if file exists. When it does not it [dies](#die) `error=require` or creates
the file `error=create`

## programRequired

```bash
programRequired() {} # 1 Args: <program>
```

Test if program exists in path. When it does not it [dies](#die)

## assertEqual

```bash
assertEqual() {} # 2 Args: <value> <expected>
```

# Network

## downloadFile

```bash
downloadFile() {} # 3 Args: <source> <output> <error>
```

Tries to download file `source` to `output`. On error:
`error=die`: Program [dies](#die); else it prints a warning / error.

NOTE: this function [requires](#programRequired) wget

# Config

Conig options can be read and set vie the `CONFIG` array

## addToConfig

```bash
addToConfig() {} # 3 Args: <name> <default> <description>
```

Adds a config option

## parseConfigFile

```bash
parseConfigFile() {} # 1 Args: <filenema>
```

## generateConfigFile

```bash
generateConfigFile() {} # 1 Args: <filenema>
```
