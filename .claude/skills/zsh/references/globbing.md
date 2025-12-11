# Zsh Globbing Reference

Complete reference for zsh glob patterns, extended globbing, and qualifiers.

## Contents
- Basic Patterns
- Extended Globbing
- Recursive Globbing
- Glob Qualifiers
- Numeric Ranges
- Practical Examples

## Basic Patterns

```zsh
*           # Match any string (except /)
?           # Match any single character
[abc]       # Match a, b, or c
[a-z]       # Match any lowercase letter
[^abc]      # Match anything except a, b, or c
[!abc]      # Same as [^abc]
```

### Examples

```zsh
*.txt           # All .txt files
file?.txt       # file1.txt, fileA.txt, etc.
file[0-9].txt   # file0.txt through file9.txt
file[!0-9].txt  # fileA.txt, fileB.txt (not digits)
*.{jpg,png,gif} # All image files (brace expansion)
```

## Extended Globbing

Enable with: `setopt EXTENDED_GLOB`

```zsh
^pattern        # Negation (anything except pattern)
pattern~except  # Pattern except matches of except
x#              # Zero or more of x
x##             # One or more of x
(a|b)           # Either a or b
```

### Negation

```zsh
# All except .txt files
ls ^*.txt

# All except specific files
ls ^(readme|license).md

# Combine with other patterns
ls ^*.@(log|tmp)       # Not .log or .tmp
```

### Excluding Matches

```zsh
# All .txt except those starting with test
ls *.txt~test*.txt

# All Python files except tests
ls **/*.py~**/*test*.py

# Source files except backup and generated
ls *.c~*.bak~*_gen.c
```

### Repetition

```zsh
# Zero or more
(foo)#          # '', 'foo', 'foofoo', etc.

# One or more
(foo)##         # 'foo', 'foofoo', etc.

# Match repeated patterns
ls (a)#.txt     # .txt, a.txt, aa.txt, aaa.txt
```

## Recursive Globbing

```zsh
**/*            # All files recursively
***/*           # Follow symlinks too

# Examples
**/*.py         # All Python files in subdirectories
**/test_*.py    # All test files recursively
src/**/*.ts     # TypeScript files under src/
```

### With Glob Qualifiers

```zsh
**/*.py(.)      # Only regular Python files
**/*(/oc)       # Directories by creation time
**/*(.)         # All regular files recursively
```

## Glob Qualifiers

Qualifiers refine glob matches. Format: `pattern(qualifiers)`

### File Type Qualifiers

```zsh
(.)             # Regular files only
(/)             # Directories only
(@)             # Symbolic links
(=)             # Sockets
(p)             # Named pipes (FIFOs)
(*)             # Executable files
(%)             # Device files
(%b)            # Block devices
(%c)            # Character devices

# Examples
ls *(.)         # Regular files only
ls *(/om)       # Directories sorted by modification
ls *(@)         # Symlinks only
```

### Permission Qualifiers

```zsh
(r)             # Readable by owner
(w)             # Writable by owner
(x)             # Executable by owner
(R)             # Readable by world
(W)             # Writable by world
(X)             # Executable by world
(s)             # Setuid
(S)             # Setgid
(t)             # Sticky bit

# Examples
ls *(.x)        # Executable regular files
ls *(.r)        # Readable files
ls *(/w)        # Writable directories
```

### Ownership Qualifiers

```zsh
(U)             # Owned by effective UID
(G)             # Owned by effective GID
(u:name:)       # Owned by user 'name'
(g:name:)       # Owned by group 'name'
(u0)            # Owned by root (UID 0)

# Examples
ls *(U)         # Files I own
ls *(^U)        # Files I don't own
ls *(u:www-data:) # Owned by www-data
```

### Size Qualifiers

```zsh
(L[+-]n)        # Size comparison (in bytes)
(Lk[+-]n)       # Size in kilobytes
(Lm[+-]n)       # Size in megabytes
(Lg[+-]n)       # Size in gigabytes

# Comparisons
(L+100)         # Larger than 100 bytes
(L-100)         # Smaller than 100 bytes
(L100)          # Exactly 100 bytes

# Examples
ls *(Lk+100)    # Files > 100KB
ls *(Lm-10)     # Files < 10MB
ls *(Lg+1)      # Files > 1GB
ls *(Lm1)       # Files exactly 1MB
```

### Time Qualifiers

```zsh
# Modification time
(m[+-]n)        # Days
(mh[+-]n)       # Hours
(mm[+-]n)       # Minutes
(ms[+-]n)       # Seconds
(mw[+-]n)       # Weeks
(mM[+-]n)       # Months

# Access time (use 'a' instead of 'm')
(a[+-]n)        # Access time in days
(ah[+-]n)       # Hours

# Change time (use 'c' instead of 'm')
(c[+-]n)        # Change time in days

# Examples
ls *(m-7)       # Modified in last 7 days
ls *(mh-1)      # Modified in last hour
ls *(mm-30)     # Modified in last 30 minutes
ls *(m+30)      # Modified more than 30 days ago
ls *(a-1)       # Accessed today
```

### Sorting Qualifiers

```zsh
(on)            # Sort by name (ascending)
(On)            # Sort by name (descending)
(oL)            # Sort by size (smallest first)
(OL)            # Sort by size (largest first)
(om)            # Sort by modification time (newest first)
(Om)            # Sort by modification time (oldest first)
(oa)            # Sort by access time
(oc)            # Sort by inode change time
(od)            # Sort by directory depth (directories only)

# Examples
ls *(.om)       # Files sorted by modification time
ls *(.oL)       # Files sorted by size (smallest first)
ls *(.OL)       # Files sorted by size (largest first)
ls *(om[1])     # Most recently modified file
ls *(oL[1,5])   # 5 smallest files
```

### Index/Slicing Qualifiers

```zsh
[n]             # nth match (1-indexed)
[n,m]           # Matches n through m

# Examples
ls *(om[1])     # Most recent file
ls *(om[1,5])   # 5 most recent files
ls *(om[-1])    # Oldest file (last in sorted list)
ls *(.OL[1,10]) # 10 largest files
```

### Combining Qualifiers

```zsh
# Multiple qualifiers are ANDed
ls *(.m-7Lk+100)     # Files: modified <7 days AND >100KB
ls *(/U)             # Directories I own
ls *(ULk+100)        # Files I own >100KB

# OR conditions with commas
ls *(.|/)            # Files OR directories
ls *(.x|/)           # Executables OR directories
```

### Modifier Qualifiers

```zsh
(:h)            # Head (directory path)
(:t)            # Tail (filename only)
(:r)            # Root (remove extension)
(:e)            # Extension only
(:l)            # Lowercase
(:u)            # Uppercase
(:a)            # Absolute path
(:A)            # Absolute path (resolve symlinks)
(:q)            # Quote special characters

# Examples
echo *.txt(:t)        # Filenames only
echo *.txt(:r)        # Without .txt extension
echo *.txt(:h)        # Directories only
echo /tmp/test.txt(:a) # Absolute path
```

## Numeric Ranges

```zsh
<n-m>           # Match numbers from n to m
<->             # Match any number
<-n>            # Match numbers up to n
<n->            # Match numbers from n

# Examples
ls file<1-10>.txt     # file1.txt through file10.txt
ls log.<->.txt        # log.1.txt, log.234.txt, etc.
ls data<100-199>.csv  # data100.csv through data199.csv
ls chapter<-5>.md     # chapter1.md through chapter5.md
```

## Approximate Matching

Enable with: `setopt EXTENDED_GLOB`

```zsh
(#a1)pattern    # Allow 1 error in pattern
(#a2)pattern    # Allow 2 errors

# Examples
ls (#a1)readme*       # Matches readne*, remade*, etc.
ls (#a2)*.txt         # Very fuzzy .txt matching
```

## Case Insensitive Matching

```zsh
(#i)pattern     # Case insensitive
(#I)pattern     # Case sensitive (default)
(#l)pattern     # Lowercase matches uppercase

# Examples
ls (#i)readme*        # README, readme, ReadMe, etc.
ls (#i)*.TXT          # .txt, .TXT, .Txt
```

## Practical Examples

### Find Large Log Files

```zsh
# Logs > 100MB, modified in last week
ls /var/log/**/*.log(.Lm+100m-7)

# Top 10 largest logs
ls /var/log/**/*.log(.OL[1,10])
```

### Clean Up Old Files

```zsh
# Files older than 30 days
rm **/*.tmp(m+30)

# Empty files
rm **/*(.L0)

# Files not accessed in 90 days
rm old_archive/**/*(.a+90)
```

### Development Workflows

```zsh
# All source files (not in node_modules)
ls **/*.{ts,tsx,js,jsx}~**/node_modules/*

# Test files only
ls **/*test*.{js,ts}(.)

# Recently modified source
ls src/**/*(.m-1)
```

### System Administration

```zsh
# World-writable files (security check)
ls -la **/*(.W)

# Files not owned by expected user
ls **/*(.^u:app:)

# Setuid executables
ls /**/*(.s)
```

### File Organization

```zsh
# Images by size (largest first)
ls **/*.{jpg,png,gif}(.OL)

# Newest configuration files
ls ~/.config/**/*(.om[1,10])

# Directories without .git
ls -d */ ^.git/
```

## Options Affecting Globbing

```zsh
setopt EXTENDED_GLOB      # Enable ^, ~, #
setopt NULL_GLOB          # Empty result instead of error
setopt GLOB_DOTS          # Include dotfiles
setopt NO_CASE_GLOB       # Case insensitive
setopt NUMERIC_GLOB_SORT  # Sort numbers correctly
setopt MARK_DIRS          # Append / to directories
setopt GLOB_COMPLETE      # Complete with glob patterns
setopt GLOB_STAR_SHORT    # ** without / matches files too
```

## Error Handling

```zsh
# Default: error on no match
ls *.nonexistent  # Error: no matches

# NULL_GLOB: empty result
setopt NULL_GLOB
ls *.nonexistent  # No output, no error

# CSH_NULL_GLOB: error only if all patterns fail
setopt CSH_NULL_GLOB
ls *.txt *.nonexistent  # Works if *.txt matches

# NO_NOMATCH: pass pattern literally
setopt NO_NOMATCH
ls *.nonexistent  # Tries to list literal "*.nonexistent"
```
