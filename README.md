# LevelsRanks + Rank Tags

| Requirement | Version |
| :--- | :--- |
| SourceMod | `1.11+` |
| ClientMod API | required (`clientmod` + `multicolors` includes for chat colors) |
| Game | `CS:S V34 Vanilla`   `CS:S ClientMod` |

## Map :
```
+-- addons/sourcemod/
|   |
|   +-- plugins/
|   |   +-- levelsranks.smx
|   |   +-- levelsranks_tag.smx
|   |
|   +-- scripting/
|   |   +-- levelsranks.sp
|   |   +-- levelsranks_tag.sp
|   |   +-- levels_ranks/
|   |   |   +-- api.sp
|   |   |   +-- commands.sp
|   |   |   +-- custom_functions.sp
|   |   |   +-- database.sp
|   |   |   +-- defines.sp
|   |   |   +-- events.sp
|   |   |   +-- menus.sp
|   |   |   +-- settings.sp
|   |   +-- include/
|   |       +-- lvl_ranks.inc
|   |
|   +-- configs/levels_ranks/
|   |   +-- rank_colors.ini
|   |   +-- settings.ini
|   |   +-- settings_ranks.ini
|   |   +-- settings_stats.ini
|   |   +-- tags.ini
|   |
|   +-- translations/
|   |   +-- lr_core.phrases.txt
|   |   +-- lr_core_ranks.phrases.txt
|   |
|   +-- data/sqlite/
|       +-- lr_base.sq3
|
+-- cstrike/cfg/sourcemod/levels_ranks/
    +-- lr_teamtags.cfg

```
