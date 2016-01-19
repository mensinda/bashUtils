# bashUtils

bashUtils is a collection of (more or less) useful functions.

Sourcing the loader.sh script and running the `loadBashUtils` function will give you access to all functions described below.

NOTE: Some functions use global variables. Variable names starting with `__CLASS` or `__INTERNAL` should be avoided

# Content
 - [Object Oriented BASH](#object-oriented-bash)
   - [Example](#example)
   - [Object operators](#object-operators)
 - [Bash Curses](#bash-curses)
 - [Bash C bindings](#bash-c-bindings)
   - [WARNING - read this](#warning-warning-warning)
   - [Function definition file Syntax](#function-definition-file-syntax)
 - [Logging functions](#logging)
 - [Util functions](#utils)

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
| : [attr] [var]     | Stores [attr] in [var]                                       |
| name               | Prints the object name to stdout                             |
| classname          | Prints the class name to stdout                              |
| hasFunc [func]     | Returns 0 if class has the function [func]                   |
| hasAttr [attr]     | Returns 0 if class has the attribute [attr]                  |
| isVisible [a/f]    | Returns 0 if the attribute / function is *currently* visible |
| destruct           | Destructs the object and runs the (optional) destructor      |

# Bash Curses

bashUtils provides classes to read and parse the terminfo file for the current terminal and create
ncurses like windows and mouse input.

## bTermInfo

The class `bTermInfo` is responsible for loading the terminfo file and setting the `COLUMNS` and
`LINES` environment variables.

All parsed data can be accessed via `<objectName> . <CapName>`. All CapNames are listed in the terminfo manpage.

|      Methode     |                        Description                       |
|------------------|----------------------------------------------------------|
| CONSTRUCTOR      | calls `updateScreenSize` and `loadTIfile`                |
| updateScreenSize | (re)sets the `COLUMNS` and `LINES` environment variables |
| loadTIfile       | (re)parses the terminfo file                             |

## bCurses

The main / init class.

|              Methode             |                               Description                               |
|----------------------------------|-------------------------------------------------------------------------|
| CONSTRUCTOR [TI]                 | loads information from the [TI] bTermInfo object                        |
| hideCursor                       | hides the cursor (default)                                              |
| showCursor                       | shows the cursor                                                        |
| append [child]                   | appends a drawable [child] (needs draw methode)                         |
| draw                             | draws all children                                                      |
| updateScreenSize                 | runns the updateScreenSize from bTermInfo                               |
| startLoop [key] [mouse] [resize] | starts the input loop; sends events to [key] [mouse] [resize] functions |
| stopLoop                         | stops the input loop                                                    |
| init                             | saves current state; clears the window; enables mouse support           |
| reset                            | restores the terminal state before init                                 |

### The key callback

Special key names are the CapNames from the terminfo manpage.

### The mouse callback

Parameters:

| Parameters |           Description          |
|------------|--------------------------------|
|    arg1    | Pressed button (or "released") |
|    arg2    | X coordinate                   |
|    arg2    | Y coordinate                   |

Buttons:

| Button |          Description          |
|--------|-------------------------------|
|  MB1   | Mouse button 1 (left click)   |
|  MB2   | Mouse button 2 (middle click) |
|  MB3   | Mouse button 3 (right click)  |
|  WU    | Wheel up                      |
|  WD    | Wheel down                    |
|  REL   | *ANY* button (MB*) released   |

# Bash C bindings

bashUtils provides a (base) class to create bindings for c-style functions and callbacks via c-style function pointers.

bashUtils uses a c program running in background to call the c functions.
This program can be automatically generated with a simple function definition file (bind.def) in the binding root directory.

Short example:
```bash
class Bind1 BASHBinding # Inheriting everything from BASHBinding
  public:
    :: f1 # f1 is a c function
ssalc

Bind1 binding /path/to/binding/source/root /path/to/an/empty/directory/for/FIFOs
binding . bbind_compile
binding . bbind_start

binding . f1 "arg1"
msg1 "Return value of c function f1: $OUT_0"

binding destruct

```

Setting `BASH_BINDING_START_WITH_GDB` to `'true'` will start the program with gdb.

[Here](https://github.com/mensinda/bindTest) is a working example with a simple c lib.

## :warning: WARNING :warning:

**WARNING To support c pointers bashUtils does some questionable casting!**

(pointer -> size_t -> c string -> **Your Script** -> c string -> size_t -> pointer)

A pointer in BASH is represented as an unsigend integer (base 10) with the prefix `\x01PTR`.
So it is *theoretically* possible to do pointer arithmetic in BASH!

Because bashUtils supports low level c pointes your script might be partialy responsible for memory management.
You can even malloc and free memory in your script (if you write the binding)!

I strongly recommend to avoid pointers whenever possible and to NEVER modify a pointer in BASH!

## Function definition file Syntax

This file is used to automatically generate the c program. It contains all information about the function pointer types and functions.

NOTE: The filename has to be `bind.def`.

### Section 1: Config

Commands:

#### subDir

Usage:

```
subdir: [<name>] <path>
# Example:
subdir: [lib1] ./lib1
```

Adds the `<path>` CMake subdirectory and `<path>` to the include directories. It will also link the final
program against `<name>`.

NOTE: This command assumes that `<name>` is a library added with the CMake command `add_library`!

### includeDir

Usage:

```
includeDir: <path>
# Example:
includeDir: /ust/local/include
```

Adds `<path>` to the include directories.

### include

Usage:

```
include: <filename>
# Example:
include: lib1.h
```

Adds `#include <filename>` to the c file.

### Section 2: Callback types [optional]

This section starts with the command `beginCallback:`.

Just copy and paste the typedef into this section (without the `typedef` keyword, argument *names* and the ';')
All typedefs will be automatically resolved.

Every argument cancontain metadata (default: none). Metadata can be set inside `|` chars.

|   matadata  |                                        Description                                         |
|-------------|--------------------------------------------------------------------------------------------|
| `:<argnum>` | The Argument expects an array with the size of the arg index `<argnum>` (first arg is 0)   |

### Section 3: Functions

This section starts with the command `beginBinding:`.

Just copy and paste the function prototypes into this section (without the argument *names* and the ';')
All typedefs will be automatically resolved.

Every argument contains metadata (default: in). Metadata can be manualy set inside `|` chars.

|   matadata  |                                        Description                                         |
|-------------|--------------------------------------------------------------------------------------------|
| `FPTR`      | The argument type is a function pointer defined in section 2                               |
| `in`        | Requires input from BASH                                                                   |
| `out`       | Mainly for pointers. Will generate a OUT var for the pointer and the data in bash          |
| `:<argnum>` | The Argument expects an array with the size of the arg index `<argnum>` (return type is 0) |
| `!<argnum>` | Same as `:<argnum>` but `<argnum>` can be an output only type (return)                     |
| `DUMMY`     | Wont be used to call the function but can be used as input for `:<argnum>`                 |

Usage:
```
void func( int *|<metadata goes here>| )
Example:
void func( int * |in out :2|, size_t )
```

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

# Thread Sync

Functions for thread synchronization. A thread can be locked with `FIFOwait` and unlocked from an other
thread via `FIFOcontinue`.

NOTE: those functions create temporary FIOS! Make sure you are using an empty directory to avoid collisions.

## FIFOwait

```bash
FIFOwait() {} # 1 Args: <fifoname>
```

## FIFOcontinue

```bash
FIFOcontinue() {} # 1 Args: <fifoname>
```
