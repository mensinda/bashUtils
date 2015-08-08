# bashUtils

bashUtils is a collection of (more or less) useful functions.

Sourcing the loader.sh script and running the `loadBashUtils` function will give you access to all functions described below.

NOTE: Some functions use global variables. Variable names starting with `__CLASS` or `__INTERNAL` should be avoided


# Object Oriented BASH

## Example:

```bash
# base.sh

class Base
  private:
    -- var

  protected:
    :: print

  public:
    :: Base
    :: ~Base
ssalc

Base::print() {
  msg1 "Base: var: '$($1 . var)'"
}

Base::Base() {
  msg1 "Constructing Base"
  $1 . var "Hello World"
}

Base::~Base() {
  msg1 "Destructing Base"
}
```

```bash
# vector.sh

class Vector Base # Start class definition
  private:
    -- x
    -- y
    -- z
    :: privateFunc

  public:
    :: Vector  # Constructor
    :: ~Vector # Destructor
    :: show
ssalc        # End class definition

# $1 is always a 'pointer' to this
Vector::Vector() {
  msg1 "Constructing $($1 classname)"

  $1 . x "$2" # Sets attr x to 0
  $1 . y "$3"
  $1 . z "$4"
}

Vector::~Vector() {
  msg1 "Destructing $($1 classname)"
}

Vector::privateFunc() {
  msg1 "PRIVATE echo: ${@:2}"
}

Vector::show() {
  msg1 "Vector '$($1 name)':"
  msg2 "X: $($1 . x)"
  msg2 "Y: $($1 . y)"
  msg2 "Z: $($1 . z)"
  $1 . privateFunc "Hello" "World" # Output: "PRIVATE echo: Hello World"
  $1 . print # In Base class
  # $1 . var # ERROR
}
```

```bash
# main.sh

Vector vec1 5 5 6
vec1 . show
#vec1 . privateFunc # ERROR: privateFunc is private
#vec1 . y 5         # ERROR: y is private
vec1 destruct
#vec1 . show        # Bash error: vec1: command not found
```

## Object operators

|      Operator      |                         Description                          |
|--------------------|--------------------------------------------------------------|
| . [func] [options] | Calls [func] with [options]                                  |
| . [attr]           | Prints value of [attr] to stdout                             |
| . [attr] [value]   | Sets [attr] to [value]                                       |
| name               | Prints the object name to stdout                             |
| classname          | Prints the class name to stdout                              |
| hasFunc [func]     | Returns 0 if class has the function [func]                   |
| hasAttr [attr]     | Returns 0 if class has the attribute [attr]                  |
| isVisible [a/f]    | Returns 0 if the attribute / function is *currently* visible |
| destruct           | Destructs the object and runs the (optional) destructor      |

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

## assertDoesNotContain

```bash
assertDoesNotContain() {} # 2 Args: <string> <substring>
```

[dies](#die) if string contains substring

# Network

## downloadFile

```bash
downloadFile() {} # 3 Args: <source> <output> <error>
```

Tries to download file `source` to `output`. On error:
`error=die`: Program [dies](#die); else it prints a warning / error.

NOTE: this function [requires](#programRequired) wget

# Config

Config options can be read and set vie the `CONFIG` array

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
