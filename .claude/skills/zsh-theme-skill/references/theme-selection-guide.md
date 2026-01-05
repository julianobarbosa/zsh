# Theme Selection Guide

Detailed criteria for choosing the right Oh My Zsh theme.

## Selection Matrix

### By Use Case

| Use Case | Recommended Theme | Why |
|----------|-------------------|-----|
| Team standard | robbyrussell | Universal compatibility |
| Personal dev machine | powerlevel10k | Best performance + features |
| Remote/SSH sessions | minimal, clean | Fast, no rendering issues |
| Presentations/demos | agnoster, powerlevel10k | Professional appearance |
| Large monorepos | powerlevel10k | Async git status |
| Slow terminal | minimal | No external calls |
| VS Code terminal | robbyrussell, af-magic | Avoids font issues |

### By Priority

#### Performance Priority

```
Fastest                                              Slowest
minimal → clean → dst → robbyrussell → af-magic → agnoster → spaceship
   │                                                           │
   └── No git ─────────────────── Sync git ─────── Full features
```

**Recommendation:** `powerlevel10k` with instant prompt if you want speed AND features.

#### Visual Appeal Priority

```
Minimal                                              Maximum
minimal → dst → robbyrussell → af-magic → bira → agnoster → powerlevel10k
                                                       │           │
                                           Powerline fonts    Nerd fonts
```

#### Information Density Priority

| Level | Themes | Shows |
|-------|--------|-------|
| Minimal | minimal, clean | Directory only |
| Low | dst, robbyrussell | Dir + git branch |
| Medium | af-magic, ys, bira | Dir + git status + user |
| High | agnoster, bureau | Full git + context |
| Maximum | powerlevel10k | Everything, configurable |

## Font Compatibility Matrix

| Theme | No Fonts | Powerline | Nerd Fonts |
|-------|----------|-----------|------------|
| robbyrussell | ✅ | ✅ | ✅ |
| af-magic | ✅ | ✅ | ✅ |
| ys | ✅ | ✅ | ✅ |
| minimal | ✅ | ✅ | ✅ |
| agnoster | ⚠️ Degraded | ✅ | ✅ |
| powerlevel10k | ⚠️ ASCII mode | ⚠️ Limited | ✅ |
| spaceship | ⚠️ Degraded | ⚠️ Limited | ✅ |

Legend:
- ✅ Full support
- ⚠️ Works with limitations

## Terminal Compatibility

### iTerm2 (macOS)
All themes work. For best experience:
- Install Nerd Fonts
- Use powerlevel10k

### Terminal.app (macOS)
Limited Unicode support:
- Use robbyrussell, af-magic, ys
- Avoid Powerline themes

### VS Code Integrated Terminal
Font rendering can be inconsistent:
- Recommended: robbyrussell, af-magic
- If using Nerd Fonts: powerlevel10k works

### Windows Terminal
Good Unicode support:
- All themes work with proper fonts
- Recommended: powerlevel10k (WSL)

### Linux Console (TTY)
Very limited:
- Use minimal, clean
- No Unicode themes

### SSH Sessions
Depends on local terminal:
- Safe choice: robbyrussell
- If local has fonts: any theme works

## Specific Theme Recommendations

### For Backend Developers
```
Primary:   powerlevel10k (local dev)
Secondary: robbyrussell (SSH/servers)
```
Why: Git status awareness critical, needs to work everywhere.

### For DevOps/SRE
```
Primary:   powerlevel10k with k8s context
Secondary: ys (detailed, no special fonts)
```
Why: Need cluster context visibility, often SSH into various systems.

### For Frontend Developers
```
Primary:   powerlevel10k or spaceship
Secondary: af-magic
```
Why: Node version display useful, usually have font support.

### For Data Scientists
```
Primary:   powerlevel10k with conda/venv segments
Secondary: robbyrussell
```
Why: Python environment visibility important.

### For System Administrators
```
Primary:   minimal or clean (servers)
Secondary: ys (when more info needed)
```
Why: Minimal overhead, clear identification of systems.

## Migration Paths

### From robbyrussell → More Features
```
robbyrussell → af-magic → agnoster → powerlevel10k
     │             │           │            │
  Minimal     + user/host  + powerline  + everything
```

### From Complex → Simpler
```
powerlevel10k → agnoster → af-magic → robbyrussell → minimal
       │            │           │            │           │
  Everything    Powerline    Basic+      Minimal      Bare
```

## Final Recommendations

### The Safe Default
```zsh
ZSH_THEME="robbyrussell"
```
- Works everywhere
- No dependencies
- Familiar to all

### The Power User Choice
```zsh
ZSH_THEME="powerlevel10k/powerlevel10k"
```
- Install Nerd Fonts first
- Run `p10k configure`
- Best performance + features

### The Middle Ground
```zsh
ZSH_THEME="af-magic"
```
- More info than robbyrussell
- No special fonts needed
- Clean appearance
