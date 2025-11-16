# Disk Cleanup Tools

This directory contains comprehensive tools for managing disk space on macOS.

## Files

1. **DISK_CLEANUP_GUIDE.md** - Complete guide explaining macOS storage and cleanup strategies
2. **cleanup-disk.sh** - Interactive script to automate cleanup
3. **DISK_CLEANUP_README.md** - This file

## Quick Start

### Option 1: Interactive Mode (Recommended)
```bash
./cleanup-disk.sh
```

This will:
1. Analyze your disk usage
2. Show you what's taking up space
3. Let you choose a cleanup level
4. Confirm before deleting anything

### Option 2: Dry Run (See What Would Be Deleted)
```bash
./cleanup-disk.sh --dry-run
```

Safe way to see what would be cleaned without actually deleting anything.

### Option 3: Automated Cleanup
```bash
# Level 1 - Safe cleanup (NPM, Homebrew, temp files)
./cleanup-disk.sh --auto --level=1

# Level 2 - Moderate cleanup (adds Python caches, Docker, browsers)
./cleanup-disk.sh --auto --level=2

# Level 3 - Aggressive cleanup (adds ML models, Playwright, etc.)
./cleanup-disk.sh --auto --level=3
```

## Cleanup Levels Explained

### Level 1: Safe & Quick (Recommended)
**What it cleans:**
- NPM cache (~12 GB in your case)
- Homebrew cache (~5 GB)
- Temporary files (~18 GB)
- Trash
- Pre-commit cache (~700 MB)

**Expected savings:** 30-40 GB
**Risk:** None - all easily rebuildable
**Time to rebuild:** Minutes

### Level 2: Moderate
**Everything in Level 1, plus:**
- UV Python cache (~10 GB)
- Pip cache (~700 MB)
- Docker unused images/containers
- Browser caches (Arc, Chrome, Edge) (~5 GB)

**Expected savings:** 50-60 GB
**Risk:** Low - requires re-downloading packages
**Time to rebuild:** 10-30 minutes depending on usage

### Level 3: Aggressive
**Everything in Level 2, plus:**
- Huggingface ML models (~65 GB in your case!)
- Playwright browser binaries (~2.4 GB)
- Trunk cache (~3 GB)
- Grype security scanner cache (~1.2 GB)

**Expected savings:** 100+ GB
**Risk:** Medium - large downloads to restore
**Time to rebuild:** Hours for ML models, minutes for others

## Your Current Situation

Based on the analysis, your disk has:

```
Total: 494.38 GB
Used: 454.71 GB (92%)
Available: ~40 GB

Major space consumers:
- Huggingface models: 65 GB
- .cache/tmp: 18 GB
- data2: 16 GB
- NPM cache: 12 GB
- UV cache: 10 GB
- Homebrew: 5 GB
```

### Recommended Actions

#### Immediate (Get ~50 GB back quickly):
```bash
./cleanup-disk.sh --auto --level=2
```

#### If you need more space (Get ~120 GB back):
```bash
./cleanup-disk.sh --auto --level=3
```
**Note:** Only do this if you don't actively need the Huggingface models.

#### Conservative approach (Get ~35 GB back):
```bash
./cleanup-disk.sh --auto --level=1
```

## Safety Features

The script includes multiple safety features:

1. **Analysis First** - Shows what will be cleaned before doing anything
2. **Confirmation Prompts** - Asks before deleting (unless --auto)
3. **Dry Run Mode** - Test without deleting
4. **Detailed Logging** - All actions logged to `/tmp/disk-cleanup-*.log`
5. **Size Reporting** - Shows space freed for each operation
6. **Skip Empty** - Automatically skips empty directories

## Understanding the Output

```bash
./cleanup-disk.sh
```

You'll see:
1. **Analysis Phase** - Current disk usage and cache sizes
2. **Cleanup Selection** - Choose what to clean
3. **Progress Updates** - What's being cleaned in real-time
4. **Summary** - Total space freed and final disk usage

## Manual Cleanup Commands

If you prefer manual control, see `DISK_CLEANUP_GUIDE.md` for individual commands.

### Quick manual commands:
```bash
# Clean NPM cache
npm cache clean --force

# Clean Homebrew
brew cleanup -s

# Clean temp files
rm -rf ~/.cache/tmp/*

# Clean trash
rm -rf ~/.Trash/*

# Clean UV cache
uv cache clean

# Clean pip cache
pip cache purge
```

## After Cleanup

### What happens to deleted caches?

- **NPM/Yarn:** Re-downloads packages on next `npm install`
- **Homebrew:** Re-downloads on next `brew install`
- **Pip/UV:** Re-downloads Python packages as needed
- **Docker:** Re-pulls images as needed
- **Huggingface:** Re-downloads models when you use them
- **Playwright:** Run `npx playwright install` to restore
- **Pre-commit:** Reinstalls hooks on next run

### Verify cleanup success:

```bash
# Check disk usage
df -h /

# Check specific caches
du -sh ~/.cache ~/.npm ~/Library/Caches/Homebrew
```

## Troubleshooting

### Script fails with "Permission denied"
```bash
chmod +x cleanup-disk.sh
```

### "System Data" still shows large after cleanup
1. Restart your Mac (macOS caches the storage calculation)
2. Wait a few minutes for macOS to recalculate
3. Check Storage settings again

### Want to see what's in a cache before deleting?
```bash
# List contents
ls -lh ~/.cache/huggingface/

# Check size
du -sh ~/.cache/huggingface/*
```

### Accidentally deleted something important?
- Most caches are automatically rebuilt when needed
- Check the log file for what was deleted: `/tmp/disk-cleanup-*.log`
- For Homebrew: `brew install <package>` again
- For NPM: `npm install` in your project
- For Python: Packages reinstall automatically

## Best Practices

### Regular Maintenance Schedule

**Weekly:**
```bash
./cleanup-disk.sh --auto --level=1
```

**Monthly:**
```bash
./cleanup-disk.sh --auto --level=2
```

**Quarterly:**
```bash
# Review and manually clean large items
./cleanup-disk.sh --dry-run
```

### Prevention

1. **Monitor regularly:**
   ```bash
   # Add to ~/.zshrc
   alias diskcheck='df -h / && du -sh ~/.cache ~/.npm ~/Library/Caches/Homebrew'
   ```

2. **Clean as you go:**
   - Run `brew cleanup` after installing packages
   - Run `npm cache clean` periodically
   - Empty trash regularly

3. **Use external storage:**
   - Move large datasets to external drives
   - Store ML models externally if possible
   - Archive old projects

## Advanced Usage

### Custom cleanup:
```bash
./cleanup-disk.sh
# Then select option 4 for custom cleanup
```

### Combine with analysis:
```bash
# First, see what's there
du -sh ~/.cache/* | sort -hr

# Then run cleanup
./cleanup-disk.sh --auto --level=2

# Verify
df -h /
```

### Script in cron/launchd:
```bash
# Add to crontab for weekly cleanup
0 2 * * 0 /path/to/cleanup-disk.sh --auto --level=1 >> /tmp/weekly-cleanup.log 2>&1
```

## Additional Resources

- Full guide: See `DISK_CLEANUP_GUIDE.md` for comprehensive information
- Apple Support: https://support.apple.com/en-us/HT206996
- Script log files: `/tmp/disk-cleanup-*.log`

## Need Help?

### Common Questions

**Q: Is it safe to run?**
A: Yes. Level 1 and 2 are completely safe. Level 3 removes larger caches but they're all rebuildable.

**Q: Will it delete my files?**
A: No. It only deletes caches and temporary files, never your actual documents or projects.

**Q: How often should I run it?**
A: Weekly with Level 1, monthly with Level 2.

**Q: What if I need the caches back?**
A: They rebuild automatically when needed. NPM downloads packages, Homebrew downloads apps, etc.

**Q: Can I undo the cleanup?**
A: You can't undo, but all deleted items are caches that rebuild automatically.

## Your Specific Recommendations

Based on your current usage (454.71 GB of 494.38 GB used):

### Immediate action (if you're running out of space):
```bash
./cleanup-disk.sh --auto --level=3
```
This will free up ~100-120 GB.

### Conservative approach:
```bash
./cleanup-disk.sh --auto --level=2
```
This will free up ~50-60 GB and avoid deleting ML models.

### Minimal cleanup:
```bash
./cleanup-disk.sh --auto --level=1
```
This will free up ~35-40 GB with zero risk.

### After cleanup, set up monitoring:
```bash
# Add to ~/.zshrc
alias diskstatus='df -h / | grep -v Filesystem && echo "\n--- Large Caches ---" && du -sh ~/.cache ~/.npm ~/Library/Caches/Homebrew 2>/dev/null'
```

Then run `diskstatus` weekly to monitor your disk usage.
