# Catalogue audit — 0.2.0-beta1

## Coverage

| Class | Templates | PvE-compatible | PvP-compatible |
| --- | ---: | ---: | ---: |
| Druid | 25 | 24 | 18 |
| General | 15 | 13 | 10 |
| Hunter | 22 | 15 | 18 |
| Mage | 21 | 18 | 16 |
| Paladin | 20 | 17 | 14 |
| Priest | 21 | 19 | 14 |
| Rogue | 21 | 13 | 18 |
| Shaman | 22 | 20 | 13 |
| Warlock | 24 | 18 | 19 |
| Warrior | 23 | 17 | 19 |

Total: 214 templates; all IDs and macro names unique. Maximum body: 142 bytes. Every body is within 255 bytes; every macro name is within 16 ASCII characters. No focus-unit templates or scripted combat actions.

## Completed checks

- Executed TOC-ordered Lua files and event initialization in LuaTeX with a mocked WoW API.
- Exercised window open/close, all 214 detail views, search and favorites.
- Tested create/update without duplicates, stored-body verification, account isolation, unknown name collisions, external edit protection and exact-body legacy migration.
- Tested combat guards, wrong class/client locale, empty and overlong input, full slots, pack preflight, preservation of custom bodies and deletion snapshot checks.
- Checked recommended packs for every class/mode against 18 empty character slots.
- Reviewed an off-game rendering of Lua anchor positions; corrected conflicting row/detail anchors and editor/status spacing. The renderer approximates fonts and is not a game screenshot.

Run `lua Tests/check.lua .` from the addon folder (Lua 5.2+), or `texlua Tests/check.lua .`. Tests are not loaded by the addon.

## Limits

The tests simulate API behavior; they do not emulate the secure WoW UI or execute spells. Spell effects, client rendering, combat taint, talent combinations and actual Classic/Hardcore encounters still need the in-game checklist. 214 curated entries cover major use cases, not every possible player-specific macro. No WoW: Forever compatibility claim.

## Reference checks

Character/account macro indexing and the PickupMacro drag flow were checked against [the Blizzard Macro UI source mirror](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroUI.lua). This is a retrieved source snapshot, not certification against a running 1.15.9 client. Macro GCD/conditional constraints were cross-checked with [Macros: Essential Information](https://us.forums.blizzard.com/en/wow/t/macros-essential-information/21139).

## Template index

### Druid

- Abolish Poison mouseover — BOTH / UTILITY (`dru_poison`)
- Bash — PVP / CC (`dru_bash`)
- Cat powershift — BOTH / UTILITY (`dru_catshift`)
- Cure Poison mouseover — BOTH / UTILITY (`dru_cure`)
- Dire Bear powershift — PVE / DEFENSE (`dru_bearshift`)
- Entangling Roots mouseover — BOTH / CC (`dru_roots`)
- Enter Bear / Dire Bear Form — BOTH / DEFENSE (`dru_bear`)
- Enter Cat Form safely — BOTH / UTILITY (`dru_cat`)
- Faerie Fire (Feral) mouseover — BOTH / OFFENSE (`dru_feralff`)
- Faerie Fire mouseover — BOTH / OFFENSE (`dru_ff`)
- Growl mouseover — PVE / UTILITY (`dru_growl`)
- Healing Touch mouseover — PVE / HEALING (`dru_ht`)
- Hibernate mouseover — PVE / CC (`dru_hibernate`)
- Innervate mouseover — BOTH / UTILITY (`dru_innervate`)
- Mark of the Wild mouseover — BOTH / UTILITY (`dru_mark`)
- Maul queue — PVE / OFFENSE (`dru_maul`)
- Nature’s Swiftness + Healing Touch — BOTH / HEALING (`dru_nsht`)
- Prowl — BOTH / UTILITY (`dru_prowl`)
- Rebirth mouseover — PVE / UTILITY (`dru_rebirth`)
- Regrowth mouseover — BOTH / HEALING (`dru_regrowth`)
- Rejuvenation mouseover — BOTH / HEALING (`dru_rejuv`)
- Remove Curse mouseover — BOTH / UTILITY (`dru_decurse`)
- Return to caster form — BOTH / UTILITY (`dru_unshift`)
- Thorns mouseover — PVE / UTILITY (`dru_thorns`)
- Travel Form — BOTH / UTILITY (`dru_travel`)

### General

- Assist party member 1 — PVE / TARGETING (`gen_party1`)
- Assist target — PVE / TARGETING (`gen_assist`)
- Clear target — PVP / TARGETING (`gen_cleartarget`)
- Lower trinket — BOTH / UTILITY (`gen_trinket2`)
- Mark Cross — PVE / UTILITY (`gen_cross`)
- Mark Skull — PVE / UTILITY (`gen_skull`)
- Remove target marker — PVE / TARGETING (`gen_clearraid`)
- Return to previous target — BOTH / TARGETING (`gen_lasttarget`)
- Start Attack — BOTH / OFFENSE (`gen_startattack`)
- Stop Attack — PVP / UTILITY (`gen_stopattack`)
- Stop casting — BOTH / UTILITY (`gen_stopcast`)
- Stop casts, attacks and pet — BOTH / UTILITY (`gen_stopall`)
- Target nearest enemy — BOTH / TARGETING (`gen_targetenemy`)
- Target your pet target — BOTH / TARGETING (`gen_targetpet`)
- Upper trinket — BOTH / UTILITY (`gen_trinket1`)

### Hunter

- Aimed Shot — BOTH / OFFENSE (`hun_aimed`)
- Auto Shot without toggling off — BOTH / OFFENSE (`hun_autoshot`)
- Call Pet — BOTH / PET (`hun_call`)
- Concussive Shot mouseover — PVP / CC (`hun_concussive`)
- Deterrence — PVP / DEFENSE (`hun_deterrence`)
- Distracting Shot mouseover — PVE / UTILITY (`hun_distract`)
- Feign Death — BOTH / DEFENSE (`hun_fd`)
- Freezing Trap — PVP / CC (`hun_freezing`)
- Frost Trap — PVP / CC (`hun_frosttrap`)
- Hunter’s Mark + Pet Attack — BOTH / OFFENSE (`hun_markpet`)
- Mend Pet — PVE / PET (`hun_mendpet`)
- Multi-Shot — PVE / OFFENSE (`hun_multishot`)
- Pet Attack — BOTH / PET (`hun_petattack`)
- Pet Follow + Passive — BOTH / PET (`hun_petfollow`)
- Pet Stay — BOTH / PET (`hun_petstay`)
- Pet attack / Shift recall — BOTH / PET (`hun_petmod`)
- Revive Pet — BOTH / PET (`hun_revive`)
- Scatter Shot mouseover — PVP / CC (`hun_scatter`)
- Scorpid Sting mouseover — PVE / OFFENSE (`hun_scorpid`)
- Serpent Sting mouseover — BOTH / OFFENSE (`hun_serpent`)
- Viper Sting mouseover — PVP / OFFENSE (`hun_viper`)
- Wing Clip — PVP / CC (`hun_wingclip`)

### Mage

- Arcane Intellect mouseover — BOTH / UTILITY (`mag_int`)
- Arcane Power — PVE / OFFENSE (`mag_arcpower`)
- Blink — BOTH / DEFENSE (`mag_blink`)
- Blizzard — PVE / OFFENSE (`mag_blizzard`)
- Blizzard at cursor — PVE / OFFENSE (`mag_cursor`)
- Cancel Ice Block — BOTH / UTILITY (`mag_cancelblock`)
- Cold Snap — BOTH / UTILITY (`mag_coldsnap`)
- Cone of Cold — BOTH / OFFENSE (`mag_coc`)
- Counterspell mouseover — BOTH / UTILITY (`mag_cs`)
- Evocation without clipping — PVE / UTILITY (`mag_evocation`)
- Fire Blast mouseover — PVP / OFFENSE (`mag_fireblast`)
- Frost Nova — BOTH / CC (`mag_nova`)
- Frostbolt Rank 1 — PVP / CC (`mag_fbolt1`)
- Ice Barrier — BOTH / DEFENSE (`mag_barrier`)
- Ice Block — BOTH / DEFENSE (`mag_block`)
- Polymorph / Shift Rank 1 — BOTH / CC (`mag_modpoly`)
- Polymorph mouseover — BOTH / CC (`mag_poly`)
- Presence of Mind + Polymorph — PVP / CC (`mag_pompoly`)
- Remove Lesser Curse mouseover — BOTH / UTILITY (`mag_decurse`)
- Scorch — PVE / OFFENSE (`mag_scorch`)
- Wand without toggling off — BOTH / OFFENSE (`M_wand`)

### Paladin

- Blessing of Freedom mouseover — PVP / UTILITY (`pal_freedom`)
- Blessing of Kings mouseover — BOTH / UTILITY (`pal_bok`)
- Blessing of Might mouseover — PVE / UTILITY (`pal_bom`)
- Blessing of Protection mouseover — BOTH / DEFENSE (`pal_bop`)
- Blessing of Sacrifice mouseover — PVP / DEFENSE (`pal_sac`)
- Blessing of Wisdom mouseover — PVE / UTILITY (`pal_bow`)
- Cancel Blessing of Protection — BOTH / UTILITY (`pal_cancelbop`)
- Cancel Divine Shield — BOTH / UTILITY (`pal_cancelds`)
- Cleanse mouseover — BOTH / UTILITY (`pal_cleanse`)
- Divine Shield — BOTH / DEFENSE (`pal_ds`)
- Exorcism — PVE / OFFENSE (`pal_exo`)
- Flash of Light mouseover — BOTH / HEALING (`pal_fol`)
- Hammer of Justice mouseover — PVP / CC (`pal_hoj`)
- Holy Light / Shift Flash of Light — BOTH / HEALING (`pal_modheal`)
- Holy Light mouseover — PVE / HEALING (`pal_hl`)
- Judgement + start attack — BOTH / OFFENSE (`pal_judge`)
- Lay on Hands mouseover — BOTH / HEALING (`pal_loh`)
- Purify with self fallback — BOTH / UTILITY (`pal_purify`)
- Redemption mouseover — PVE / UTILITY (`pal_redemption`)
- Turn Undead mouseover — PVE / CC (`pal_turn`)

### Priest

- Abolish Disease mouseover — BOTH / UTILITY (`pri_abolish`)
- Cure Disease mouseover — BOTH / UTILITY (`pri_cure`)
- Dispel Magic smart mouseover — BOTH / UTILITY (`pri_dispel`)
- Fade — PVE / DEFENSE (`pri_fade`)
- Flash Heal mouseover — BOTH / HEALING (`pri_flash`)
- Greater Heal mouseover — PVE / HEALING (`pri_gheal`)
- Heal Rank 2 mouseover — PVE / HEALING (`pri_rankheal`)
- Inner Focus + Greater Heal — PVE / HEALING (`pri_inner`)
- Leave Shadowform — BOTH / UTILITY (`pri_cshadow`)
- Mind Blast — BOTH / OFFENSE (`pri_mblast`)
- Mind Flay without clipping — BOTH / OFFENSE (`pri_mindflay`)
- Power Infusion mouseover — PVE / UTILITY (`pri_pi`)
- Power Word: Fortitude mouseover — BOTH / UTILITY (`pri_fort`)
- Power Word: Shield mouseover — BOTH / DEFENSE (`pri_pws`)
- Psychic Scream — PVP / CC (`pri_scream`)
- Renew mouseover — BOTH / HEALING (`pri_renew`)
- Resurrection mouseover — PVE / UTILITY (`pri_res`)
- Shackle Undead mouseover — PVE / CC (`pri_shackle`)
- Shadow Word: Pain mouseover — BOTH / OFFENSE (`pri_swp`)
- Silence mouseover — PVP / CC (`pri_silence`)
- Wand without toggling off — BOTH / OFFENSE (`P_wand`)

### Rogue

- Adrenaline Rush — BOTH / OFFENSE (`rog_adrenaline`)
- Ambush — PVP / OFFENSE (`rog_ambush`)
- Backstab + attack — BOTH / OFFENSE (`rog_backstab`)
- Blade Flurry — PVE / OFFENSE (`rog_bladeflurry`)
- Blind mouseover — PVP / CC (`rog_blind`)
- Cheap Shot — PVP / OFFENSE (`rog_cheap`)
- Evasion — BOTH / DEFENSE (`rog_evasion`)
- Eviscerate — BOTH / OFFENSE (`rog_evis`)
- Gouge — PVP / CC (`rog_gouge`)
- Hemorrhage + attack — BOTH / OFFENSE (`rog_hemo`)
- Kick mouseover — BOTH / UTILITY (`rog_kick`)
- Kidney Shot on current target — PVP / CC (`rog_kidney`)
- Pick Pocket without attacking — BOTH / UTILITY (`rog_pick`)
- Preparation — PVP / UTILITY (`rog_prep`)
- Riposte — BOTH / OFFENSE (`rog_riposte`)
- Sap mouseover — PVP / CC (`rog_sap`)
- Sinister Strike + attack — PVE / OFFENSE (`rog_sinister`)
- Slice and Dice — PVE / OFFENSE (`rog_slice`)
- Sprint — BOTH / UTILITY (`rog_sprint`)
- Stealth without toggling off — BOTH / UTILITY (`rog_stealth`)
- Vanish — PVP / DEFENSE (`rog_vanish`)

### Shaman

- Ancestral Spirit mouseover — PVE / UTILITY (`sha_res`)
- Chain Heal mouseover — PVE / HEALING (`sha_chainheal`)
- Chain Lightning — PVE / OFFENSE (`sha_chainlight`)
- Cure Disease mouseover — BOTH / UTILITY (`sha_curedisease`)
- Cure Poison mouseover — BOTH / UTILITY (`sha_curepoison`)
- Disease Cleansing Totem — PVE / UTILITY (`sha_diseasecl`)
- Earth Shock Rank 1 interrupt — BOTH / UTILITY (`sha_earthr1`)
- Earth Shock interrupt — BOTH / UTILITY (`sha_earth`)
- Frost Shock mouseover — PVP / CC (`sha_frostshock`)
- Ghost Wolf — BOTH / UTILITY (`sha_ghostwolf`)
- Grounding Totem — PVP / DEFENSE (`sha_grounding`)
- Healing Wave mouseover — PVE / HEALING (`sha_hw`)
- Lesser Healing Wave mouseover — BOTH / HEALING (`sha_lhw`)
- Lightning Shield — BOTH / DEFENSE (`sha_lightshield`)
- Mana Tide Totem — PVE / UTILITY (`sha_manatide`)
- Nature’s Swiftness + Healing Wave — BOTH / HEALING (`sha_nsheal`)
- Poison Cleansing Totem — PVE / UTILITY (`sha_poisoncl`)
- Purge mouseover — BOTH / UTILITY (`sha_purge`)
- PvE totem sequence — PVE / UTILITY (`sha_totems`)
- Searing Totem — PVE / OFFENSE (`sha_searing`)
- Stormstrike — BOTH / OFFENSE (`sha_stormstrike`)
- Tremor Totem — BOTH / DEFENSE (`sha_tremor`)

### Warlock

- Banish mouseover — PVE / CC (`loc_banish`)
- Corruption mouseover — BOTH / OFFENSE (`loc_corruption`)
- Curse of Agony mouseover — BOTH / OFFENSE (`loc_agony`)
- Curse of Exhaustion mouseover — PVP / CC (`loc_exhaust`)
- Curse of Shadow mouseover — PVE / OFFENSE (`loc_shadow`)
- Curse of Tongues mouseover — PVP / CC (`loc_tongues`)
- Curse of the Elements mouseover — PVE / OFFENSE (`loc_elements`)
- Death Coil mouseover — PVP / CC (`loc_deathcoil`)
- Demon attack — BOTH / PET (`loc_petattack`)
- Devour Magic mouseover — BOTH / PET (`loc_devour`)
- Devour Magic on yourself — BOTH / PET (`loc_selfdevour`)
- Drain Life — BOTH / OFFENSE (`loc_drainlife`)
- Drain Soul without clipping — PVE / OFFENSE (`loc_drainsoul`)
- Fear mouseover — BOTH / CC (`loc_fear`)
- Health Funnel without clipping — BOTH / PET (`loc_healthfunnel`)
- Howl of Terror — PVP / CC (`loc_howl`)
- Life Tap — BOTH / UTILITY (`loc_lifetap`)
- Pet Recall + Passive — BOTH / PET (`loc_petpass`)
- Rain of Fire at cursor — PVE / OFFENSE (`loc_cursor`)
- Seduction mouseover — PVP / PET (`loc_seduce`)
- Shadowburn mouseover — PVP / OFFENSE (`loc_shadowburn`)
- Spell Lock mouseover — BOTH / PET (`loc_spelllock`)
- Voidwalker Sacrifice — BOTH / DEFENSE (`loc_sacrifice`)
- Wand without toggling off — BOTH / OFFENSE (`L_wand`)

### Warrior

- Battle Stance / Charge — BOTH / OFFENSE (`war_dancecharge`)
- Berserker Rage — PVP / DEFENSE (`war_bersrage`)
- Berserker Stance / Pummel — PVP / UTILITY (`war_dancepummel`)
- Bloodrage — BOTH / UTILITY (`war_bloodrage`)
- Bloodthirst + attack — BOTH / OFFENSE (`war_blood`)
- Charge + start attack — BOTH / OFFENSE (`war_charge`)
- Cleave queue — BOTH / OFFENSE (`war_cleave`)
- Defensive Stance / Taunt — PVE / UTILITY (`war_dancetaunt`)
- Disarm mouseover — PVP / CC (`war_disarm`)
- Execute — BOTH / OFFENSE (`war_execute`)
- Hamstring — PVP / CC (`war_hamstring`)
- Heroic Strike queue — BOTH / OFFENSE (`war_hs`)
- Intercept — PVP / OFFENSE (`war_intercept`)
- Intimidating Shout — PVP / CC (`war_intshout`)
- Last Stand — PVE / DEFENSE (`war_laststand`)
- Mortal Strike + attack — BOTH / OFFENSE (`war_mortal`)
- Overpower — BOTH / OFFENSE (`war_overpower`)
- Pummel mouseover — BOTH / UTILITY (`war_pummel`)
- Revenge + attack — BOTH / OFFENSE (`war_revenge`)
- Shield Bash mouseover — BOTH / UTILITY (`war_shbash`)
- Shield Wall — BOTH / DEFENSE (`war_shwall`)
- Sunder Armor mouseover — PVE / OFFENSE (`war_sunder`)
- Taunt mouseover — PVE / UTILITY (`war_taunt`)
