# Export Notes & Team Git Practice

## Week 8 — Multi-Platform Export & Team Git

---

## Platform Exports

### Platform 1: Windows (PC)

**Steps taken:**

1. Opened **Project → Export** in Godot.
2. Clicked **Add…** and selected **Windows Desktop**.
3. Downloaded export templates via **Editor → Manage Export Templates** (Godot 4.7).
4. Set export path to `exports/windows/AppleRun.exe`.
5. Clicked **Export Project** → confirmed the `.exe` and `.pck` were created.
6. Tested the `.exe` by running it outside Godot — game launched, menus and levels worked correctly.

**Platform-specific notes:** No extra tweaks needed for PC. Window is 1280×720 with stretch mode `canvas_items`.

---

### Platform 2: Web (HTML5)

**Steps taken:**

1. Added a **Web** preset in Project → Export.
2. Enabled **Threads** support and set `index.html` as the export file.
3. Export path: `exports/web/index.html`.
4. Tested locally using Python's built-in HTTP server:
   ```bash
   python -m http.server 8080
   ```
   Then opened `http://localhost:8080` in Chrome.
5. **Platform-specific tweak:** Disabled `AudioStreamPlayer2D` auto-bus binding because browsers require a user gesture before audio plays. Added a one-frame delay in `main.gd` before starting music on Web:
   ```gdscript
   if OS.get_name() == "Web":
       await get_tree().process_frame
   music.play()
   ```

---

## Common Export Gotchas

| Issue | Fix |
|-------|-----|
| Export templates not installed | Editor → Manage Export Templates → Download |
| `.pck` missing next to `.exe` | Make sure "Export PCK/ZIP" is unchecked OR keep both files together |
| Web audio silent | Add user-gesture check; defer `music.play()` by one frame |
| Web: SharedArrayBuffer warning | Enable COOP/COEP headers on your server (or use itch.io which handles this) |
| Black screen on Web | Use GL Compatibility renderer (already set in this project) |

---

## Team Git Practice

### Branch Workflow

```bash
# 1. Create a feature branch
git checkout -b week8-export-practice

# 2. Make a change (e.g. update README)
echo "Export test" >> README.md

# 3. Commit and push the branch
git add README.md
git commit -m "Week 8: branch practice - export notes"
git push origin week8-export-practice

# 4. Open a Pull Request on GitHub:
#    Base: main  ←  Compare: week8-export-practice
#    Title: "Week 8: Multi-platform export + Git practice"
```

### Merge Conflict Practice

```bash
# On main branch, edit the same line in README.md
git checkout main
echo "Main branch edit" >> README.md
git commit -am "Main: readme edit"

# Merge the feature branch → conflict!
git merge week8-export-practice
# Git will mark the conflict in README.md like:
# <<<<<<< HEAD
# Main branch edit
# =======
# Export test
# >>>>>>> week8-export-practice

# Resolve: keep both lines, save the file, then:
git add README.md
git commit -m "Week 8: resolve merge conflict"
```

**What I learned:** Merge conflicts happen when two branches edit the same lines. Git marks both versions between `<<<<<<<` and `>>>>>>>`. You manually pick which version to keep (or combine them), then commit the resolution.

---

## Showcase Feedback

*Showcased the game to class after Week 8 export.*

**Observations from peers:**
- Jumping felt responsive and satisfying.
- Suggested adding a score display on the game-over/return-to-menu screen so players can see their final score.
- Enemy speed on Level 2 felt slightly too fast for first-time players.

**Applied change:** Added score display to the README and noted it as a future UI improvement. Enemy CHASE_SPEED in `snail_fsm.gd` tuned from 100 → 90 px/s.
