# Zsh Parameter Expansion Reference

Complete reference for zsh parameter/variable expansion and manipulation.

## Contents
- Basic Expansion
- Default Values
- String Operations
- Pattern Matching
- Array Operations
- Parameter Flags
- Modifiers

## Basic Expansion

```zsh
var="value"

$var              # Basic expansion
${var}            # Explicit bracing (recommended)
${#var}           # Length of value
${+var}           # 1 if set, 0 if unset
```

## Default Values

```zsh
# Use default if unset or empty
${var:-default}           # Use default, don't assign
${var-default}            # Use default if unset (not if empty)

# Assign default if unset or empty
${var:=default}           # Assign and use default
${var=default}            # Assign if unset (not if empty)

# Error if unset or empty
${var:?error message}     # Error if unset or empty
${var?error message}      # Error if unset only

# Use alternative if set
${var:+alternative}       # Alternative if set and non-empty
${var+alternative}        # Alternative if set (even if empty)
```

### Examples

```zsh
unset name
echo ${name:-Anonymous}   # Anonymous

name=""
echo ${name:-Anonymous}   # Anonymous (empty counts as unset with :-)
echo ${name-Anonymous}    # (empty string, not unset)

name="John"
echo ${name:+Hello $name} # Hello John
echo ${name:-Anonymous}   # John
```

## String Operations

### Substring Extraction

```zsh
var="Hello World"

${var:offset}             # From offset to end
${var:0:5}                # From 0, length 5: "Hello"
${var:6}                  # From 6 to end: "World"
${var:6:3}                # From 6, length 3: "Wor"
${var: -5}                # Last 5 chars: "World" (space required!)
${var: -5:3}              # Last 5, then 3: "Wor"
${var:0:-3}               # All but last 3: "Hello Wo"
```

### Case Modification

```zsh
var="Hello World"

${var:u}                  # HELLO WORLD (uppercase all)
${var:l}                  # hello world (lowercase all)
${var:U}                  # HELLO WORLD (same as :u in zsh)
${var:L}                  # hello world (same as :l in zsh)

# First character
${(U)var}                 # HELLO WORLD
${(L)var}                 # hello world
${(C)var}                 # Hello World (capitalize words)

# With flags
var="HELLO WORLD"
echo ${(L)var}            # hello world
```

### Pattern Removal

```zsh
var="path/to/file.txt.bak"

# Remove from beginning (shortest match)
${var#*/}                 # to/file.txt.bak

# Remove from beginning (longest match)
${var##*/}                # file.txt.bak

# Remove from end (shortest match)
${var%.*}                 # path/to/file.txt

# Remove from end (longest match)
${var%%.*}                # path/to/file

# Common use: basename and dirname
file="/home/user/document.pdf"
echo ${file##*/}          # document.pdf (basename)
echo ${file%/*}           # /home/user (dirname)
```

### Search and Replace

```zsh
var="Hello World World"

# Replace first occurrence
${var/World/Universe}     # Hello Universe World

# Replace all occurrences
${var//World/Universe}    # Hello Universe Universe

# Replace at beginning (anchor)
${var/#Hello/Hi}          # Hi World World

# Replace at end (anchor)
${var/%World/Universe}    # Hello World Universe

# Delete (replace with nothing)
${var//World}             # Hello
${var// /_}               # Hello_World_World

# With patterns (EXTENDED_GLOB)
setopt EXTENDED_GLOB
${var//[aeiou]/X}         # HXllX WXrld WXrld
```

## Pattern Matching

### With [[ ]]

```zsh
var="hello.txt"

# Glob matching
[[ $var == *.txt ]]       # true
[[ $var == hello.* ]]     # true
[[ $var == *llo* ]]       # true

# Regex matching (POSIX ERE)
[[ $var =~ ^hello ]]      # true
[[ $var =~ \.txt$ ]]      # true

# Capture groups with BASH_REMATCH or match
[[ "hello123" =~ ([a-z]+)([0-9]+) ]]
echo $match[1]            # hello
echo $match[2]            # 123
```

### Parameter Patterns

```zsh
# Remove matching elements (arrays)
arr=(one two three two)
echo ${arr:#two}          # one three (remove matches)
echo ${arr:#*o*}          # three (remove containing 'o')

# Keep matching elements
echo ${(M)arr:#*o*}       # one two two (keep containing 'o')
```

## Array Operations

### Basic Operations

```zsh
# Define arrays (1-indexed in zsh!)
arr=(one two three)
typeset -a arr2=(a b c)

# Access elements
echo $arr[1]              # one (first element)
echo $arr[-1]             # three (last element)
echo $arr[2,3]            # two three (range)

# All elements
echo $arr                 # one two three (as words)
echo ${arr[@]}            # one two three
echo ${arr[*]}            # one two three (single word with IFS)
echo "$arr"               # one two three (single string)

# Length
echo ${#arr}              # 3 (count)
echo ${#arr[@]}           # 3
echo ${#arr[1]}           # 3 (length of first element)
```

### Modification

```zsh
arr=(one two three)

# Append
arr+=(four)               # one two three four
arr+=("item with space")

# Prepend
arr=(zero $arr)           # zero one two three four

# Modify element
arr[2]=TWO                # one TWO three four

# Remove element
arr[3]=()                 # one TWO four (removes index 3)
arr=(${arr[@]:0:1} ${arr[@]:2})  # Remove second element

# Slice
echo ${arr[@]:1:2}        # Elements 1-2 (0-indexed for slice!)
```

### Associative Arrays

```zsh
# Declare
typeset -A hash
declare -A hash           # Same as typeset

# Initialize
hash=(key1 val1 key2 val2)
hash=([key1]=val1 [key2]=val2)

# Access
echo ${hash[key1]}        # val1

# Set
hash[key3]=val3

# All keys
echo ${(k)hash}           # key1 key2 key3

# All values
echo ${(v)hash}           # val1 val2 val3

# Key-value pairs
for key val in ${(kv)hash}; do
    echo "$key: $val"
done

# Check if key exists
if [[ -v hash[key1] ]]; then
    echo "exists"
fi

# Delete key
unset 'hash[key1]'
```

## Parameter Flags

Flags modify how parameters are expanded: `${(flags)var}`

### String Flags

```zsh
var="hello world"

${(U)var}                 # HELLO WORLD (uppercase)
${(L)var}                 # hello world (lowercase)
${(C)var}                 # Hello World (capitalize)
${(Q)var}                 # Remove one level of quotes
${(qq)var}                # 'hello world' (single quote)
${(qqq)var}               # $'hello world' (dollar quote)
${(qqqq)var}              # "hello world" (double quote)
```

### Array Flags

```zsh
arr=(one two three one two)

${(u)arr}                 # one two three (unique)
${(o)arr}                 # one one three two two (sort ascending)
${(O)arr}                 # two two three one one (sort descending)
${(oi)arr}                # Case-insensitive sort
${(on)arr}                # Numeric sort
```

### Join and Split

```zsh
arr=(one two three)

# Join array with delimiter
${(j:,:)arr}              # one,two,three
${(j:-:)arr}              # one-two-three
${(j::)arr}               # onetwothree (no delimiter)

# Split string into array
str="one,two,three"
${(s:,:)str}              # (one two three)

path="/usr/local/bin"
${(s:/:)path}             # ('' usr local bin)
```

### Length and Index

```zsh
arr=(one two three)

${(c)#arr}                # 3 (count, same as ${#arr})
${#${(j::)arr}}           # 11 (total character count)

# Get index of element
echo ${arr[(i)two]}       # 2 (index of 'two')
echo ${arr[(I)two]}       # 2 (last index of 'two')
```

### Escaping and Quoting

```zsh
var='hello $world'

${(q)var}                 # hello\ \$world (backslash escape)
${(qq)var}                # 'hello $world' (single quotes)
${(qqq)var}               # $'hello $world' (dollar quotes)
${(qqqq)var}              # "hello \$world" (double quotes)

# Expand variables then quote
var="hello world"
${(Q)${(qq)var}}          # hello world (quote then unquote)
```

### Type Flags

```zsh
# Tied parameters (link scalar to array)
typeset -T PATH path :    # PATH and path are linked

# Pad/truncate
var="test"
${(l:10:)var}             # "      test" (left pad to 10)
${(r:10:)var}             # "test      " (right pad to 10)
${(l:10:-:)var}           # "------test" (pad with -)
${(l:10::.:)var}          # ".....test" (pad with .)
```

## Modifiers

Modifiers follow a colon and modify the result.

### Path Modifiers

```zsh
file="/home/user/document.pdf"

${file:h}                 # /home/user (head/directory)
${file:t}                 # document.pdf (tail/basename)
${file:r}                 # /home/user/document (root/no extension)
${file:e}                 # pdf (extension)

# Combinations
${file:t:r}               # document (basename without extension)
${${file:t}:r}            # document (same thing)

# Absolute path
${file:a}                 # Resolve to absolute path
${file:A}                 # Resolve symlinks too
```

### History Modifiers

```zsh
# In history expansion
!!:h                      # Head of last command
!!:t                      # Tail of last command
!!:r                      # Remove extension
!!:e                      # Extension only

# Substitution in history
^old^new                  # Replace in last command
!!:s/old/new              # Same thing
!!:gs/old/new             # Global substitution
```

## Nested Expansion

```zsh
# Nested substitutions
file="HELLO.TXT"
${${file:l}:r}            # hello (lowercase, then remove extension)

# Multiple flags
arr=(One Two Three)
${(L)${(j:,:)arr}}        # one,two,three (join, then lowercase)

# Complex nesting
var="  hello world  "
${${var## }%% }           # "hello world" (trim both ends)
```

## Practical Examples

### Safe Variable Assignment

```zsh
# Use default for config
config_file=${CONFIG_FILE:-~/.config/app/config.yaml}

# Error if required var missing
db_host=${DATABASE_HOST:?Database host must be set}
```

### Path Manipulation

```zsh
# Get filename parts
path="/var/log/app/debug.log.gz"
dir=${path:h}             # /var/log/app
file=${path:t}            # debug.log.gz
name=${${path:t}:r}       # debug.log
name=${${${path:t}:r}:r}  # debug
ext=${path:e}             # gz
```

### Array Processing

```zsh
# Process all files
files=(*.txt)
echo ${files:r}           # Remove .txt from all
echo ${files/%.txt/.md}   # Change extension for all

# Filter array
paths=(/usr/bin /usr/local/bin /opt/bin)
echo ${paths:#/usr/*}     # /opt/bin (exclude /usr/*)
```

### String Manipulation

```zsh
# Trim whitespace (requires zsh/parameter)
var="  hello world  "
echo ${var//[[:space:]]#}              # Trim leading
echo ${${var%%[[:space:]]#}##[[:space:]]#}  # Trim both

# Convert delimiter
csv="a,b,c,d"
echo ${csv//,/$'\n'}      # Each on new line
arr=(${(s:,:)csv})        # Split to array
```
