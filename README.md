# LevelsRanks + Rank Tags

Player levelling and statistics system for **Counter-Strike: Source v34**, with a
separate chat module that shows colored rank and team tags in `say` / `say_team`.

| Requirement | Version |
| :--- | :--- |
| SourceMod | `1.11+` |
| ClientMod API | required (`clientmod` + `multicolors` includes for chat colors) |
| Game | `CS:S V34 Vanilla`   `CS:S ClientMod` |

## Files

```
+-- addons/sourcemod/
|   
|   +-- scripting/
|   |   +-- levelsranks.sp            <- core entry point
|   |   +-- levelsranks_tag.sp        <- rank-tag chat module
|   |   +-- levels_ranks/             <- core modules (included by the core)
|   |   |   +-- api.sp
|   |   |   +-- commands.sp
|   |   |   +-- custom_functions.sp
|   |   |   +-- database.sp
|   |   |   +-- defines.sp
|   |   |   +-- events.sp
|   |   |   +-- menus.sp
|   |   |   +-- settings.sp
|   |   +-- include/
|   |       +-- lvl_ranks.inc         <- public API for other plugins
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
|       +-- lr_base.sq3               <- bundled SQLite database
|
+-- cstrike/cfg/sourcemod/
    +-- lr_teamtags.cfg               <- rank-tag module config
```

### Plugins
| File | What it does |
| :--- | :--- |
| `levelsranks.sp` | **Core entry point.** Loads translations, registers all core commands, hooks game events, loads the configs, connects to the database, and `#include`s the 8 modules below. |
| `levelsranks_tag.sp` | **Rank-tag chat module.** Hooks `say` / `say_team` and prints messages with the rank tag, team tag (`[T]/[CT]/[SPEC]`), `(TEAM)` text and colors. Loads `tags.ini` + `rank_colors.ini`. Requires ClientMod. |
| `include/lvl_ranks.inc` | **Public API** for other plugins > natives (`LR_*`), forwards (`LR_On*`), enums and constants. Include with `<lvl_ranks>`. |

### Core modules
| File | What it does |
| :--- | :--- |
| `defines.sp` | Numeric constants and enums (hook types, setting IDs, stat IDs, query IDs). |
| `settings.sp` | `SetSettings()` — reads the three settings `.ini` files into memory (main settings, stat values, rank thresholds). |
| `database.sp` | Database layer — SQLite/MySQL connection, table creation, and every SQL query (load, create, save, clean, reset, top). |
| `commands.sp` | Command callbacks (`sm_lvl*`) and the in-chat triggers (`!rank`, `!top`, ...). |
| `menus.sp` | All menus — main menu, admin panel, my stats, top players, all-ranks list. |
| `custom_functions.sp` | Helpers — experience popups, rank up/down checks, name sanitising, SteamID/account conversion, player reset. |
| `events.sp` | Game-event handlers — shots/hits, player death (exp maths), bomb, hostage, round start/end, kill-streak bonuses. |
| `api.sp` | Implements the public API — `AskPluginLoad2` engine check, registers all natives, creates forwards and the `CallForward_*` helpers. |

### Configuration
| File | What it does |
| :--- | :--- |
| `settings.ini` | Main settings — table name, statistics type, admin flag, messages, sounds, DB save mode, cleanup. |
| `settings_ranks.ini` | Rank thresholds — experience required per rank for each statistics mode (`value_0/1/2`). |
| `settings_stats.ini` | Experience gained/lost per action for each system (Funded_System, Rating_Extended, Rating_Simple) plus kill-streak bonuses. |
| `rank_colors.ini` | Chat color (hex) for each rank, used by the tag module. |
| `tags.ini` | Chat tag text (e.g. `[Silver I]`) for each rank, used by the tag module. |

### Other files
| File | What it does |
| :--- | :--- |
| `data/sqlite/lr_base.sq3` | Bundled SQLite database (used automatically when no MySQL config exists). |
| `translations/lr_core.phrases.txt` | Core chat and menu phrases. |
| `translations/lr_core_ranks.phrases.txt` | Rank names — block names must match `settings_ranks.ini`. |
| `cstrike/cfg/sourcemod/lr_teamtags.cfg` | Config for the rank-tag module (colors, toggles, team-tag position). |

## Commands

### Admin commands
| Command | Access | What it does | Example |
| :--- | :--- | :--- | :--- |
| `sm_lvl_reload` | root (`z`) | Reloads all config files without a restart. | `sm_lvl_reload` |
| `sm_lvl_del <#userid\|name\|steamid>` | root (`z`) | Resets one player's statistics. | `sm_lvl_del STEAM_0:1:12345` |
| `sm_lr_reloadtags` | root (`z`) | Reloads `tags.ini`. | `sm_lr_reloadtags` |
| `sm_lr_reloadrankcolors` | root (`z`) | Reloads `rank_colors.ini`. | `sm_lr_reloadrankcolors` |
| `sm_lr_reloadchatcfg` | root (`z`) | Reloads the chat color cache from the ConVars. | `sm_lr_reloadchatcfg` |

### Server console commands
| Command | Access | What it does | Example |
| :--- | :--- | :--- | :--- |
| `sm_lvl_reset <all\|exp\|stats>` | **server console only** | Clears database data. `all` = drop the table, `exp` = reset value/rank, `stats` = reset kills/deaths/etc. | `sm_lvl_reset exp` |

> `sm_lvl_reset all` deletes the whole statistics table.

### Players Commands
| Type this | What it does |
| :--- | :--- |
| `!rank` or `rank` | Shows your rank (to everyone if `lr_show_rankmessage` = 1). |
| `!top` or `top` | TOP 10 players by experience. |
| `!toptime` or `toptime` | TOP 10 players by playtime. |
| `!session` or `session` | Your current session statistics. |
| `!lvl` | Opens the statistics menu. |


### Rank-tag module settings

| ConVar | Default | What it does |
| :--- | :--- | :--- |
| `sm_lr_tags_enable` | `1` | Enable the whole module. |
| `sm_lr_tags_general` | `1` | Format normal (global) chat. |
| `sm_lr_tags_teamchat` | `1` | Format team chat. |
| `sm_lr_tags_show_rank` | `1` | Show the rank tag. |
| `sm_lr_tags_show_teamtag` | `1` | Show the team tag `[T] / [CT] / [SPEC]`. |
| `sm_lr_tags_show_teamtext` | `0` | Show `(TEAM)` in team chat. |
| `sm_lr_tags_teamtag_position` | `before_name` | Team tag position: `before_name` or `after_name`. |
| `sm_lr_tags_color_rank` | `#CBB8D9` | Default rank-tag color. |
| `sm_lr_tags_color_teamtext` | `#5C9E9A` | `(TEAM)` color. |
| `sm_lr_tags_color_t_tag` | `#C98B47` | `[T]` color. |
| `sm_lr_tags_color_ct_tag` | `#5E81AC` | `[CT]` color. |
| `sm_lr_tags_color_spec_tag` | `#C97B63` | `[SPEC]` color. |
| `sm_lr_tags_color_t_name` | `#9DBA8A` | T player-name color. |
| `sm_lr_tags_color_ct_name` | `#7FA6C9` | CT player-name color. |
| `sm_lr_tags_color_spec_name` | `#D9B86C` | SPEC player-name color. |
| `sm_lr_tags_color_t_msg` | `default` | T message color. |
| `sm_lr_tags_color_ct_msg` | `default` | CT message color. |
| `sm_lr_tags_color_spec_msg` | `default` | SPEC message color. |
| `sm_lr_tags_color_default_msg` | `default` | Default message color. |

---
