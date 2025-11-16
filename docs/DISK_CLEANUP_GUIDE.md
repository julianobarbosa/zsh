# macOS Disk Space Management Guide

## Understanding macOS Storage Categories

### System Data
The largest contributor to disk usage, typically includes:
- **Cache files**: Browser caches, app caches, system caches
- **Time Machine snapshots**: Local backups (can be huge)
- **Docker containers/images**: Development environments
- **Virtual machines**: VM disk images
- **Log files**: System and application logs
- **Development caches**: npm, pip, Homebrew, Python packages, etc.

### Common Cache Locations

#### User Caches (~/.cache)
- `~/.cache/huggingface` - ML models and datasets
- `~/.cache/uv` - Python UV package manager cache
- `~/.cache/tmp` - Temporary files
- `~/.cache/pre-commit` - Pre-commit hook environments
- `~/.cache/trunk` - Trunk code checker cache
- `~/.cache/grype` - Security scanner cache

#### System Caches (~/Library/Caches)
- `~/Library/Caches/Homebrew` - Package manager cache
- `~/Library/Caches/ms-playwright` - Browser automation
- `~/Library/Caches/pip` - Python package cache
- `~/Library/Caches/pypoetry` - Poetry Python cache
- `~/Library/Caches/Arc` - Arc browser cache
- `~/Library/Caches/Google` - Chrome/Google apps cache

#### Development Tool Caches
- `~/.npm` - Node.js package cache
- `~/.yarn` - Yarn package cache
- `~/.docker` - Docker data
- `~/Library/Caches/go-build` - Go build cache
- `~/Library/Caches/node-gyp` - Node native modules

## Investigation Commands

### Check Overall Disk Usage
```bash
# View storage overview
df -h

# Detailed disk usage analysis
du -sh ~/* 2>/dev/null | sort -hr | head -20
```

### Check Specific Cache Directories
```bash
# User cache directory
du -sh ~/.cache/* 2>/dev/null | sort -hr

# System cache directory
du -sh ~/Library/Caches/* 2>/dev/null | sort -hr | head -20

# Development caches
du -sh ~/.npm ~/.yarn ~/.cache 2>/dev/null
```

### Check Time Machine Snapshots
```bash
# List local snapshots
tmutil listlocalsnapshots /

# Check snapshot sizes
tmutil listlocalsnapshotdates / | grep "-" | while read snapshot; do \
  tmutil calculatedrift "$snapshot"; \
done
```

### Check Docker Usage
```bash
# Docker disk usage
docker system df

# Detailed Docker usage
docker system df -v
```

### Find Large Files
```bash
# Find files larger than 1GB in home directory
find ~ -type f -size +1G 2>/dev/null -exec ls -lh {} \; | awk '{print $9, $5}'

# Find largest files in home directory
find ~ -type f 2>/dev/null -exec du -h {} + | sort -rh | head -50
```

## Cleanup Strategies

### Level 1: Safe & Quick Wins (Conservative)

These commands are safe to run without concern:

#### 1. NPM Cache
```bash
# Check size
du -sh ~/.npm

# Clean
npm cache clean --force

# Expected savings: 5-20 GB
```

#### 2. Homebrew Cache
```bash
# Check size
du -sh ~/Library/Caches/Homebrew

# Clean old versions
brew cleanup

# Deep clean (removes all cached downloads)
brew cleanup -s

# Expected savings: 2-10 GB
```

#### 3. Temporary Files
```bash
# Clean system temp (safe)
sudo rm -rf /tmp/*

# Clean user cache temp
rm -rf ~/.cache/tmp/*

# Expected savings: 5-20 GB
```

#### 4. Trash
```bash
# Empty trash
rm -rf ~/.Trash/*

# Expected savings: varies
```

#### 5. Pre-commit Cache
```bash
# Clean pre-commit environments
pre-commit clean
pre-commit gc

# Expected savings: 500 MB - 2 GB
```

### Level 2: Development Tool Cleanup (Moderate)

These are safe but may require re-downloading packages:

#### 1. Python Caches
```bash
# UV cache
uv cache clean

# Pip cache
pip cache purge

# Poetry cache
poetry cache clear pypi --all

# Expected savings: 5-15 GB
```

#### 2. Docker Cleanup
```bash
# Remove unused containers, images, networks
docker system prune -a

# Remove volumes too (careful - check first!)
docker system prune -a --volumes

# Expected savings: varies, can be 10-50 GB
```

#### 3. Browser Caches
```bash
# Arc browser
rm -rf ~/Library/Caches/Arc/*

# Chrome
rm -rf ~/Library/Caches/Google/Chrome/*

# Edge
rm -rf ~/Library/Caches/Microsoft\ Edge/*

# Expected savings: 2-5 GB
```

### Level 3: Aggressive Cleanup (Review First)

These remove larger caches that may take time to rebuild:

#### 1. Huggingface Models
```bash
# Check what's there first
ls -lh ~/.cache/huggingface/hub/

# Remove all models (only if you don't need them!)
rm -rf ~/.cache/huggingface

# Remove specific models
rm -rf ~/.cache/huggingface/hub/models--<model-name>

# Expected savings: 20-100 GB
```

#### 2. Playwright Browsers
```bash
# Remove cached browsers (reinstallable with: playwright install)
rm -rf ~/Library/Caches/ms-playwright

# Expected savings: 1-3 GB
```

#### 3. Node Modules
```bash
# Find and remove node_modules directories (careful!)
find ~ -name "node_modules" -type d -prune 2>/dev/null

# Remove them (review list first!)
find ~ -name "node_modules" -type d -prune -exec rm -rf '{}' +

# Expected savings: 5-50 GB
```

#### 4. Time Machine Local Snapshots
```bash
# List snapshots
tmutil listlocalsnapshots /

# Delete specific snapshot
sudo tmutil deletelocalsnapshots <snapshot-date>

# Disable local snapshots
sudo tmutil disablelocal

# Expected savings: 10-100 GB
```

### Level 4: Advanced Analysis

#### Find Large Directories
```bash
# Find top 50 largest directories
du -h ~ 2>/dev/null | sort -rh | head -50

# Find large directories in specific path
du -h -d 2 ~/Library 2>/dev/null | sort -rh | head -20
```

#### Use ncdu (Interactive)
```bash
# Install ncdu
brew install ncdu

# Analyze home directory
ncdu ~

# Analyze specific directory
ncdu ~/Library/Caches
```

#### Use DaisyDisk or Similar
Commercial tools provide visual analysis:
- DaisyDisk (paid)
- GrandPerspective (free)
- OmniDiskSweeper (free)

## Maintenance Best Practices

### Regular Cleanup Schedule

1. **Weekly**
   - Empty trash
   - Clear browser caches
   - Clean temporary files

2. **Monthly**
   - Run `brew cleanup`
   - Clear npm/pip caches
   - Check Docker usage

3. **Quarterly**
   - Review large files/directories
   - Clean old projects
   - Review Huggingface models
   - Delete unused applications

### Prevention Strategies

1. **Configure Cache Limits**
```bash
# Limit npm cache size
npm config set cache-max 512000000  # 512 MB

# Configure Docker to limit storage
# Edit Docker Desktop settings -> Resources -> Disk image size
```

2. **Use External Storage**
   - Move large datasets to external drives
   - Use cloud storage for archives
   - Store VM images externally

3. **Regular Monitoring**
```bash
# Add to ~/.zshrc for weekly reminder
alias diskcheck='df -h / && echo "\n--- Large Caches ---" && du -sh ~/.cache ~/.npm ~/Library/Caches/Homebrew 2>/dev/null'
```

4. **Project Cleanup**
   - Archive old projects
   - Remove `node_modules` from inactive projects
   - Clean up Docker images regularly

## Troubleshooting

### "System Data" Still Large After Cleanup

1. **Restart Computer**
   - macOS may not immediately update storage calculations
   - Restart forces recalculation

2. **Check for Large Log Files**
```bash
# Find large log files
find ~/Library/Logs -type f -size +100M 2>/dev/null -exec ls -lh {} \;

# Clean system logs (careful!)
sudo rm -rf ~/Library/Logs/*
sudo rm -rf /var/log/*
```

3. **Check iOS Backups**
```bash
# Check backup size
du -sh ~/Library/Application\ Support/MobileSync/Backup/

# Remove old backups (use iTunes/Finder to manage)
```

4. **Check Mail Downloads**
```bash
# Check Mail attachments
du -sh ~/Library/Mail/V*/MailData/

# Clean from Mail.app: Mailbox -> Erase Deleted Items
```

### Cache Rebuilding

After cleanup, some tools may need to rebuild caches:

```bash
# Homebrew will re-download on next install
brew install <package>

# NPM will re-download on next install
npm install

# Playwright browsers
npx playwright install

# Pre-commit hooks
pre-commit install-hooks
```

## Safety Checklist

Before running cleanup commands:

- [ ] Back up important data
- [ ] Review what will be deleted
- [ ] Understand what each cache is for
- [ ] Start with conservative cleanup
- [ ] Test after cleanup
- [ ] Keep cleanup logs
- [ ] Don't delete anything you don't understand

## Quick Reference Card

```bash
# Quick disk check
df -h /

# Quick cache size check
du -sh ~/.cache ~/.npm ~/Library/Caches/Homebrew

# Quick safe cleanup
npm cache clean --force && brew cleanup -s && rm -rf ~/.cache/tmp/*

# Emergency cleanup (aggressive)
npm cache clean --force \
  && brew cleanup -s \
  && rm -rf ~/.cache/tmp/* \
  && docker system prune -a \
  && pip cache purge \
  && rm -rf ~/.Trash/*
```

## Resources

- [Apple Support: Free up storage on Mac](https://support.apple.com/en-us/HT206996)
- [Docker: Prune unused objects](https://docs.docker.com/config/pruning/)
- [Homebrew: FAQ](https://docs.brew.sh/FAQ)
- [NPM: Clean cache](https://docs.npmjs.com/cli/cache)
