# Sound credits / CC0

Recorded sources: The Free Firearm Sound Library / Still North Media.
Authors: Ben Jaszczak, Brian Nelson, Kevin Heras, Matthew Nanney.
Source and license: [OpenGameArt — The Free Firearm Sound Library](https://opengameart.org/content/the-free-firearm-sound-library), CC0 1.0.
All A1 procedural synthesis and edits are also dedicated to CC0 1.0.

Shots/tails: Prepared firearm recordings (original near selections and additional recordings of the same models); mechanics: Raw master tracks. Originals remain outside this repository.
Times refer to the original file; FIR delay is compensated. Exact edits/seeds and source SHA256 are in manifest.json.

A3: model voices (m4, shkval, guard, cowboy, osa, winchester) use Prepared near shots and Raw mechanics from the same library; spear and hive are synthesized from A1 voices. Edits are CC0 1.0.

W2: all mechanics use a second-order Butterworth high-pass at 80 Hz.

W4: shots use distinct Prepared takes (including additional recordings of the same model), original attacks and reflections, recorded 60-200 Hz body. Automatic reflections are separate non-retriggered tails, delayed 110 ms. No synthetic pitch variants of recorded shots; linear gain, reconstructed true-peak ceiling -2 dBFS. Special weapons add low body and reflections. Mechanics, casings, gore and other banks retain their previous samples and levels.

A4: [Zombies Sound Pack](https://opengameart.org/content/zombies-sound-pack) — artisticdude, CC0 1.0 (24 recordings).
[Monster Sound Pack, Volume 1](https://opengameart.org/content/monster-sound-pack-volume-1) — Ogrebane, CC0 1.0 (18 recordings; archive folder Monster-Sounds-Volume-2).
A4 voice edits, gore/player synthesis and UI edits are dedicated to CC0 1.0. Original voice packs: 24-bit stereo 44.1 kHz; export: PCM16 mono 48 kHz, including ambience. Loops use forward playback; ambience has 100 ms overlap, heartbeat 50 ms.

| Output file | Source / synthesis | Take; original crop; pitch |
|---|---|---|
| `weapons/pistol/shot_0.wav` | 1911/A_42P.wav | take 1; 0.939937–1.689938 s; ×1.0 |
| `weapons/pistol/shot_1.wav` | 1911/A_42P.wav | take 2; 5.000042–5.750042 s; ×1.0 |
| `weapons/pistol/shot_2.wav` | 1911/A_34P.wav | take 1; 1.540667–2.290667 s; ×1.0 |
| `weapons/pistol/shot_3.wav` | 1911/A_34P.wav | take 7; 6.653542–7.403542 s; ×1.0 |
| `weapons/revolver/shot_0.wav` | Smith & Wesson 642/V_27P.wav | take 1; 0.803875–1.703875 s; ×1.0 |
| `weapons/revolver/shot_1.wav` | Smith & Wesson 642/V_27P.wav | take 2; 6.217167–7.117167 s; ×1.0 |
| `weapons/revolver/shot_2.wav` | Smith & Wesson 642/V_22P.wav | take 1; 0.671396–1.571396 s; ×1.0 |
| `weapons/revolver/shot_3.wav` | Smith & Wesson 642/V_22P.wav | take 7; 5.504604–6.404604 s; ×1.0 |
| `weapons/smg/shot_0.wav` | PPSh/P_30P.wav | take 1; 0.967354–1.567354 s; ×1.0 |
| `weapons/smg/shot_1.wav` | PPSh/P_30P.wav | take 2; 4.385708–4.985708 s; ×1.0 |
| `weapons/smg/shot_2.wav` | PPSh/P_30P.wav | take 3; 8.241083–8.841083 s; ×1.0 |
| `weapons/smg/shot_3.wav` | PPSh/P_30P.wav | take 4; 11.419771–12.019771 s; ×1.0 |
| `weapons/smg/shot_4.wav` | PPSh/P_30P.wav | take 5; 15.088563–15.688562 s; ×1.0 |
| `weapons/rifle/shot_0.wav` | AK-47/C_28P.wav | take 1; 0.609667–1.359667 s; ×1.0 |
| `weapons/rifle/shot_1.wav` | AK-47/C_28P.wav | take 2; 3.255854–4.005854 s; ×1.0 |
| `weapons/rifle/shot_2.wav` | AK-47/C_28P.wav | take 3; 6.019167–6.769167 s; ×1.0 |
| `weapons/rifle/shot_3.wav` | AK-47/C_28P.wav | take 4; 9.154687–9.904687 s; ×1.0 |
| `weapons/sniper/shot_0.wav` | Mosin Nagant/M_21P.wav | take 1; 1.032292–2.232292 s; ×1.0 |
| `weapons/sniper/shot_1.wav` | Mosin Nagant/M_21P.wav | take 2; 5.018271–6.218271 s; ×1.0 |
| `weapons/sniper/shot_2.wav` | Mosin Nagant/M_21P.wav | take 3; 9.154125–10.354125 s; ×1.0 |
| `weapons/sniper/shot_3.wav` | Mosin Nagant/M_21P.wav | take 4; 14.135708–15.335708 s; ×1.0 |
| `weapons/shotgun/shot_0.wav` | Nova/O_21P.wav | take 1; 0.429438–1.529438 s; ×1.0 |
| `weapons/shotgun/shot_1.wav` | Nova/O_21P.wav | take 2; 3.463958–4.563958 s; ×1.0 |
| `weapons/shotgun/shot_2.wav` | Nova/O_17P.wav | take 1; 0.692375–1.792375 s; ×1.0 |
| `weapons/shotgun/shot_3.wav` | Nova/O_17P.wav | take 6; 3.705583–4.805583 s; ×1.0 |
| `casings/brass_small_0.wav` | synthesis: brass_small, 5 inharmonic modes, 3 impacts + grit | seed 104729 |
| `casings/brass_small_1.wav` | synthesis: brass_small, 5 inharmonic modes, 3 impacts + grit | seed 104730 |
| `casings/brass_small_2.wav` | synthesis: brass_small, 5 inharmonic modes, 3 impacts + grit | seed 104731 |
| `casings/brass_small_3.wav` | synthesis: brass_small, 5 inharmonic modes, 3 impacts + grit | seed 104732 |
| `casings/brass_small_4.wav` | synthesis: brass_small, 5 inharmonic modes, 3 impacts + grit | seed 104733 |
| `casings/brass_small_5.wav` | synthesis: brass_small, 5 inharmonic modes, 3 impacts + grit | seed 104734 |
| `casings/brass_rifle_0.wav` | synthesis: brass_rifle, 5 inharmonic modes, 3 impacts + grit | seed 104829 |
| `casings/brass_rifle_1.wav` | synthesis: brass_rifle, 5 inharmonic modes, 3 impacts + grit | seed 104830 |
| `casings/brass_rifle_2.wav` | synthesis: brass_rifle, 5 inharmonic modes, 3 impacts + grit | seed 104831 |
| `casings/brass_rifle_3.wav` | synthesis: brass_rifle, 5 inharmonic modes, 3 impacts + grit | seed 104832 |
| `casings/brass_rifle_4.wav` | synthesis: brass_rifle, 5 inharmonic modes, 3 impacts + grit | seed 104833 |
| `casings/brass_rifle_5.wav` | synthesis: brass_rifle, 5 inharmonic modes, 3 impacts + grit | seed 104834 |
| `casings/shell_0.wav` | synthesis: shell, 5 inharmonic modes, 3 impacts + grit | seed 104929 |
| `casings/shell_1.wav` | synthesis: shell, 5 inharmonic modes, 3 impacts + grit | seed 104930 |
| `casings/shell_2.wav` | synthesis: shell, 5 inharmonic modes, 3 impacts + grit | seed 104931 |
| `casings/shell_3.wav` | synthesis: shell, 5 inharmonic modes, 3 impacts + grit | seed 104932 |
| `casings/shell_4.wav` | synthesis: shell, 5 inharmonic modes, 3 impacts + grit | seed 104933 |
| `casings/shell_5.wav` | synthesis: shell, 5 inharmonic modes, 3 impacts + grit | seed 104934 |
| `casings/mag_drop_0.wav` | synthesis: mag_drop, 5 inharmonic modes, 3 impacts + grit | seed 105029 |
| `casings/mag_drop_1.wav` | synthesis: mag_drop, 5 inharmonic modes, 3 impacts + grit | seed 105030 |
| `casings/mag_drop_2.wav` | synthesis: mag_drop, 5 inharmonic modes, 3 impacts + grit | seed 105031 |
| `casings/mag_drop_3.wav` | synthesis: mag_drop, 5 inharmonic modes, 3 impacts + grit | seed 105032 |
| `casings/mag_drop_4.wav` | synthesis: mag_drop, 5 inharmonic modes, 3 impacts + grit | seed 105033 |
| `casings/mag_drop_5.wav` | synthesis: mag_drop, 5 inharmonic modes, 3 impacts + grit | seed 105034 |
| `explosions/grenade_0.wav` | synthesis: 49-66 Hz sub, filtered blast, rumble, reflections, debris | seed 105729 |
| `explosions/grenade_1.wav` | synthesis: 49-66 Hz sub, filtered blast, rumble, reflections, debris | seed 105730 |
| `explosions/grenade_2.wav` | synthesis: 49-66 Hz sub, filtered blast, rumble, reflections, debris | seed 105731 |
| `explosions/grenade_3.wav` | synthesis: 49-66 Hz sub, filtered blast, rumble, reflections, debris | seed 105732 |
| `weapons/launcher/shot_0.wav` | weapons/shotgun/shot_0.wav + synthesized thump + W4 body/reflections | ×0.57 |
| `weapons/rail/shot_0.wav` | synthesis: broadband electrical crack + descending whip + W4 body/reflections | seed 106729 |
| `weapons/launcher/shot_1.wav` | weapons/shotgun/shot_1.wav + synthesized thump + W4 body/reflections | ×0.585 |
| `weapons/rail/shot_1.wav` | synthesis: broadband electrical crack + descending whip + W4 body/reflections | seed 106730 |
| `weapons/launcher/shot_2.wav` | weapons/shotgun/shot_2.wav + synthesized thump + W4 body/reflections | ×0.6 |
| `weapons/rail/shot_2.wav` | synthesis: broadband electrical crack + descending whip + W4 body/reflections | seed 106731 |
| `weapons/pistol/mag_out_0.wav` | Master Tracks/1911/A_3.wav | take 1; 1.152167–1.423333 s; ×1.0 |
| `weapons/pistol/mag_out_1.wav` | Master Tracks/1911/A_3.wav | take 1; 1.152167–1.423333 s; ×1.015 |
| `weapons/pistol/mag_in_0.wav` | Master Tracks/1911/A_4.wav | take 1; 0.895062–0.959688 s; ×1.0 |
| `weapons/pistol/mag_in_1.wav` | Master Tracks/1911/A_4.wav | take 2; 2.950125–3.034333 s; ×1.0 |
| `weapons/pistol/rack_0.wav` | Master Tracks/1911/A_11.wav | take 1; 0.744958–0.806500 s; ×1.0 |
| `weapons/pistol/rack_1.wav` | Master Tracks/1911/A_11.wav | take 2; 2.566000–2.639063 s; ×1.0 |
| `weapons/pistol/dry_0.wav` | Master Tracks/1911/A_19.wav | take 1; 0.695958–0.743354 s; ×1.0 |
| `weapons/pistol/dry_1.wav` | Master Tracks/1911/A_19.wav | take 1; 0.695958–0.743354 s; ×1.015 |
| `weapons/smg/mag_out_0.wav` | Master Tracks/PPSh/P_7.wav | take 1; 0.140000–0.191375 s; ×1.0 |
| `weapons/smg/mag_out_1.wav` | Master Tracks/PPSh/P_7.wav | take 2; 0.540000–0.611688 s; ×1.0 |
| `weapons/smg/mag_in_0.wav` | Master Tracks/PPSh/P_6.wav | take 1; 0.280000–0.594063 s; ×1.0 |
| `weapons/smg/mag_in_1.wav` | Master Tracks/PPSh/P_6.wav | take 2; 2.213500–2.601208 s; ×1.0 |
| `weapons/smg/rack_0.wav` | Master Tracks/PPSh/P_8.wav | take 1; 0.771021–1.065396 s; ×1.0 |
| `weapons/smg/rack_1.wav` | Master Tracks/PPSh/P_8.wav | take 2; 2.755625–2.999938 s; ×1.0 |
| `weapons/smg/dry_0.wav` | Master Tracks/PPSh/P_1.wav | take 1; 0.972812–1.009708 s; ×1.0 |
| `weapons/smg/dry_1.wav` | Master Tracks/PPSh/P_1.wav | take 2; 4.059521–4.099167 s; ×1.0 |
| `weapons/rifle/mag_out_0.wav` | Master Tracks/AK-47/C_11.wav | take 1; 0.297750–0.326146 s; ×1.0 |
| `weapons/rifle/mag_out_1.wav` | Master Tracks/AK-47/C_11.wav | take 1; 0.297750–0.326146 s; ×1.015 |
| `weapons/rifle/mag_in_0.wav` | Master Tracks/AK-47/C_10.wav | take 1; 0.214312–0.341313 s; ×1.0 |
| `weapons/rifle/mag_in_1.wav` | Master Tracks/AK-47/C_10.wav | take 1; 0.214312–0.341313 s; ×1.015 |
| `weapons/rifle/rack_0.wav` | Master Tracks/AK-47/C_14.wav | take 1; 0.238792–0.610021 s; ×1.0 |
| `weapons/rifle/rack_1.wav` | Master Tracks/AK-47/C_14.wav | take 2; 1.165375–1.558125 s; ×1.0 |
| `weapons/rifle/dry_0.wav` | Master Tracks/AK-47/C_7.wav | take 1; 0.329375–0.373396 s; ×1.0 |
| `weapons/rifle/dry_1.wav` | Master Tracks/AK-47/C_7.wav | take 1; 0.329375–0.373396 s; ×1.015 |
| `weapons/sniper/rack_0.wav` | Master Tracks/Mosin Nagant/M_14.wav | take 1; 0.623979–1.578854 s; ×1.0512472129319956 |
| `weapons/sniper/rack_1.wav` | Master Tracks/Mosin Nagant/M_14.wav | take 2; 3.098854–4.121083 s; ×1.1379598662207357 |
| `weapons/sniper/mag_in_0.wav` | Master Tracks/Mosin Nagant/M_1.wav | take 1; 0.949375–1.414146 s; ×1.0 |
| `weapons/sniper/mag_in_1.wav` | Master Tracks/Mosin Nagant/M_1.wav | take 2; 3.174792–4.077833 s; ×1.0 |
| `weapons/sniper/mag_out_0.wav` | Master Tracks/Mosin Nagant/M_8.wav | take 1; 0.606854–0.849083 s; ×1.0 |
| `weapons/sniper/mag_out_1.wav` | Master Tracks/Mosin Nagant/M_8.wav | take 2; 3.734167–4.050000 s; ×1.0 |
| `weapons/sniper/dry_0.wav` | Master Tracks/Mosin Nagant/M_10.wav | take 1; 1.203917–1.241604 s; ×1.0 |
| `weapons/sniper/dry_1.wav` | Master Tracks/Mosin Nagant/M_10.wav | take 1; 1.203917–1.241604 s; ×1.015 |
| `weapons/shotgun/rack_0.wav` | Master Tracks/Nova/O_6.wav | take 1; 1.032125–1.449875 s; ×1.0 |
| `weapons/shotgun/rack_1.wav` | Master Tracks/Nova/O_6.wav | take 1; 1.032125–1.449875 s; ×1.015 |
| `weapons/shotgun/shell_in_0.wav` | Master Tracks/Nova/O_3.wav | take 1; 1.299479–1.893500 s; ×1.0 |
| `weapons/shotgun/shell_in_1.wav` | Master Tracks/Nova/O_3.wav | take 2; 6.902750–7.440000 s; ×1.0 |
| `weapons/shotgun/dry_0.wav` | Master Tracks/Nova/O_8.wav | take 1; 0.252937–0.317854 s; ×1.0 |
| `weapons/shotgun/dry_1.wav` | Master Tracks/Nova/O_8.wav | take 1; 0.252937–0.317854 s; ×1.015 |
| `weapons/revolver/cyl_open_0.wav` | Master Tracks/Smith & Wesson 642/V_9.wav | take 1; 1.243250–1.530604 s; ×1.0 |
| `weapons/revolver/cyl_open_1.wav` | Master Tracks/Smith & Wesson 642/V_9.wav | take 1; 1.243250–1.530604 s; ×1.015 |
| `weapons/revolver/eject_0.wav` | Master Tracks/Smith & Wesson 642/V_3.wav | take 1; 1.140000–1.194167 s; ×1.0 |
| `weapons/revolver/eject_1.wav` | Master Tracks/Smith & Wesson 642/V_3.wav | take 1; 1.140000–1.194167 s; ×1.015 |
| `weapons/revolver/load_0.wav` | Master Tracks/Smith & Wesson 642/V_18.wav | take 1; 1.331958–9.689937 s; ×1.0 |
| `weapons/revolver/load_1.wav` | Master Tracks/Smith & Wesson 642/V_18.wav | take 1; 1.331958–9.689937 s; ×1.015 |
| `weapons/revolver/cyl_close_0.wav` | Master Tracks/Smith & Wesson 642/V_10.wav | take 1; 1.440438–1.572188 s; ×1.0 |
| `weapons/revolver/cyl_close_1.wav` | Master Tracks/Smith & Wesson 642/V_10.wav | take 1; 1.440438–1.572188 s; ×1.015 |
| `weapons/revolver/dry_0.wav` | Master Tracks/Smith & Wesson 642/V_5.wav | take 1; 1.544021–1.575125 s; ×1.0 |
| `weapons/revolver/dry_1.wav` | Master Tracks/Smith & Wesson 642/V_5.wav | take 1; 1.544021–1.575125 s; ×1.015 |
| `weapons/rifle/tail_0.wav` | AK-47/C_28P.wav | take 1; 0.721167–1.571167 s; ×1.0 |
| `weapons/rifle/tail_1.wav` | AK-47/C_28P.wav | take 2; 3.367354–4.217354 s; ×1.0 |
| `weapons/rifle/tail_2.wav` | AK-47/C_28P.wav | take 3; 6.130667–6.980667 s; ×1.0 |
| `weapons/smg/tail_0.wav` | PPSh/P_30P.wav | take 1; 1.078854–1.728854 s; ×1.0 |
| `weapons/smg/tail_1.wav` | PPSh/P_30P.wav | take 2; 4.497208–5.147208 s; ×1.0 |
| `weapons/smg/tail_2.wav` | PPSh/P_30P.wav | take 3; 8.352583–9.002583 s; ×1.0 |
| `weapons/m4/shot_0.wav` | AR-15/D_32P.wav | take 1; 0.702229–1.502229 s; ×1.0 |
| `weapons/m4/shot_1.wav` | AR-15/D_32P.wav | take 2; 5.645917–6.445917 s; ×1.0 |
| `weapons/m4/shot_2.wav` | AR-15/D_24P.wav | take 1; 0.547312–1.347312 s; ×1.0 |
| `weapons/m4/shot_3.wav` | AR-15/D_24P.wav | take 3; 3.908437–4.708437 s; ×1.0 |
| `weapons/shkval/shot_0.wav` | Model 12/K_22P.wav | take 1; 0.840625–1.940625 s; ×1.0 |
| `weapons/shkval/shot_1.wav` | Model 12/K_22P.wav | take 2; 7.443875–8.543875 s; ×1.0 |
| `weapons/shkval/shot_2.wav` | Model 12/K_17P.wav | take 1; 0.905708–2.005708 s; ×1.0 |
| `weapons/shkval/shot_3.wav` | Model 12/K_17P.wav | take 5; 7.055542–8.155542 s; ×1.0 |
| `weapons/guard/shot_0.wav` | Walther PPQ/X_39P.wav | take 1; 1.405417–2.105417 s; ×1.0 |
| `weapons/guard/shot_1.wav` | Walther PPQ/X_39P.wav | take 2; 6.442792–7.142792 s; ×1.0 |
| `weapons/guard/shot_2.wav` | Walther PPQ/X_39P.wav | take 3; 10.658729–11.358729 s; ×1.0 |
| `weapons/guard/shot_3.wav` | Walther PPQ/X_31P.wav | take 1; 1.083792–1.783792 s; ×1.0 |
| `weapons/cowboy/shot_0.wav` | Ruger Single Six/S_14P.wav | take 1; 0.666063–1.266063 s; ×1.0 |
| `weapons/cowboy/shot_1.wav` | Ruger Single Six/S_14P.wav | take 3; 5.452958–6.052958 s; ×1.0 |
| `weapons/cowboy/shot_2.wav` | Ruger Single Six/S_11P.wav | take 1; 0.599083–1.199083 s; ×1.0 |
| `weapons/cowboy/shot_3.wav` | Ruger Single Six/S_11P.wav | take 4; 4.912083–5.512083 s; ×1.0 |
| `weapons/osa/shot_0.wav` | Carl Gustav M45/G_31P.wav | take 1; 0.308792–0.958792 s; ×1.0 |
| `weapons/osa/shot_1.wav` | Carl Gustav M45/G_31P.wav | take 2; 3.499750–4.149750 s; ×1.0 |
| `weapons/osa/shot_2.wav` | Carl Gustav M45/G_31P.wav | take 3; 6.726229–7.376229 s; ×1.0 |
| `weapons/osa/shot_3.wav` | Carl Gustav M45/G_20P.wav | take 1; 0.346208–0.996208 s; ×1.0 |
| `weapons/winchester/shot_0.wav` | Marlin 336/I_22P.wav | take 1; 0.738521–1.838521 s; ×1.0 |
| `weapons/winchester/shot_1.wav` | Marlin 336/I_22P.wav | take 2; 7.002146–8.102146 s; ×1.0 |
| `weapons/winchester/shot_2.wav` | Marlin 336/I_17P.wav | take 1; 0.600896–1.700896 s; ×1.0 |
| `weapons/winchester/shot_3.wav` | Marlin 336/I_17P.wav | take 4; 6.842604–7.942604 s; ×1.0 |
| `weapons/m4/mag_out_0.wav` | Master Tracks/AR-15/D_5.wav | take 1; 1.200750–1.700000 s; ×1.0 |
| `weapons/m4/mag_out_1.wav` | Master Tracks/AR-15/D_3.wav | take 2; 3.813938–4.032938 s; ×1.0 |
| `weapons/m4/mag_in_0.wav` | Master Tracks/AR-15/D_4.wav | take 1; 0.952375–1.400000 s; ×1.0 |
| `weapons/m4/mag_in_1.wav` | Master Tracks/AR-15/D_2.wav | take 2; 8.056271–8.154979 s; ×1.0 |
| `weapons/m4/rack_0.wav` | Master Tracks/AR-15/D_14.wav | take 1; 0.513687–0.775229 s; ×1.0 |
| `weapons/m4/rack_1.wav` | Master Tracks/AR-15/D_15.wav | take 2; 0.313937–0.558438 s; ×1.0 |
| `weapons/m4/dry_0.wav` | Master Tracks/AR-15/D_16.wav | take 1; 0.369729–0.413521 s; ×1.0 |
| `weapons/m4/dry_1.wav` | Master Tracks/AR-15/D_16.wav | take 1; 0.369729–0.413521 s; ×1.03 |
| `weapons/shkval/rack_0.wav` | Master Tracks/Model 12/K_2.wav | take 1; 0.784042–1.175833 s; ×1.0 |
| `weapons/shkval/rack_1.wav` | Master Tracks/Model 12/K_2.wav | take 2; 3.818625–4.190000 s; ×1.0 |
| `weapons/shkval/shell_in_0.wav` | Master Tracks/Model 12/K_3.wav | take 1; 1.598229–1.943104 s; ×1.0 |
| `weapons/shkval/shell_in_1.wav` | Master Tracks/Model 12/K_3.wav | take 2; 7.379771–7.750000 s; ×1.0 |
| `weapons/shkval/dry_0.wav` | Master Tracks/Model 12/K_7.wav | take 1; 1.088250–1.126583 s; ×1.0 |
| `weapons/shkval/dry_1.wav` | Master Tracks/Model 12/K_7.wav | take 2; 3.465771–3.500667 s; ×1.0 |
| `weapons/guard/mag_out_0.wav` | Master Tracks/Walther PPQ/X_5.wav | take 1; 1.357021–1.422688 s; ×1.0 |
| `weapons/guard/mag_out_1.wav` | Master Tracks/Walther PPQ/X_5.wav | take 2; 3.628938–3.668396 s; ×1.0 |
| `weapons/guard/mag_in_0.wav` | Master Tracks/Walther PPQ/X_4.wav | take 1; 0.890729–0.980000 s; ×1.0 |
| `weapons/guard/mag_in_1.wav` | Master Tracks/Walther PPQ/X_4.wav | take 2; 3.018229–3.140000 s; ×1.0 |
| `weapons/guard/rack_0.wav` | Master Tracks/Walther PPQ/X_11.wav | take 1; 0.756583–0.814708 s; ×1.0 |
| `weapons/guard/rack_1.wav` | Master Tracks/Walther PPQ/X_9.wav | take 2; 2.997208–3.037125 s; ×1.0 |
| `weapons/guard/dry_0.wav` | Master Tracks/Walther PPQ/X_19.wav | take 1; 0.828562–0.880000 s; ×1.0 |
| `weapons/guard/dry_1.wav` | Master Tracks/Walther PPQ/X_19.wav | take 2; 2.916458–2.960000 s; ×1.0 |
| `weapons/cowboy/cyl_open_0.wav` | Master Tracks/Ruger Single Six/S_0.wav | take 1; 0.393792–0.427187 s; ×1.0 |
| `weapons/cowboy/cyl_open_1.wav` | Master Tracks/Ruger Single Six/S_10.wav | take 2; 1.309958–1.337687 s; ×1.0 |
| `weapons/cowboy/cyl_close_0.wav` | Master Tracks/Ruger Single Six/S_1.wav | take 1; 0.487771–0.520833 s; ×1.0 |
| `weapons/cowboy/cyl_close_1.wav` | Master Tracks/Ruger Single Six/S_1.wav | take 1; 0.487771–0.520833 s; ×1.03 |
| `weapons/cowboy/eject_0.wav` | Master Tracks/Ruger Single Six/S_3.wav | take 1; 3.319958–17.857667 s; ×1.0 |
| `weapons/cowboy/eject_1.wav` | Master Tracks/Ruger Single Six/S_3.wav | take 2; 12.591542–8.480354 s; ×1.0 |
| `weapons/cowboy/load_0.wav` | Master Tracks/Ruger Single Six/S_2.wav | take 1; 1.568500–7.398958 s; ×1.0 |
| `weapons/cowboy/load_1.wav` | Master Tracks/Ruger Single Six/S_2.wav | take 2; 9.992688–13.050396 s; ×1.0 |
| `weapons/cowboy/hammer_0.wav` | Master Tracks/Ruger Single Six/S_6.wav | take 1; 4.087187–4.183208 s; ×1.0 |
| `weapons/cowboy/hammer_1.wav` | Master Tracks/Ruger Single Six/S_6.wav | take 2; 5.720000–5.783229 s; ×1.0 |
| `weapons/cowboy/dry_0.wav` | Master Tracks/Ruger Single Six/S_8.wav | take 1; 0.901062–0.932688 s; ×1.0 |
| `weapons/cowboy/dry_1.wav` | Master Tracks/Ruger Single Six/S_8.wav | take 2; 2.712792–2.741292 s; ×1.0 |
| `weapons/osa/mag_out_0.wav` | Master Tracks/Carl Gustav M45:Swedish K/G_9.wav | take 1; 1.211729–1.255479 s; ×1.0 |
| `weapons/osa/mag_out_1.wav` | Master Tracks/Carl Gustav M45:Swedish K/G_9.wav | take 2; 0.467792–0.530000 s; ×1.0 |
| `weapons/osa/mag_in_0.wav` | Master Tracks/Carl Gustav M45:Swedish K/G_8.wav | take 1; 0.519563–0.554000 s; ×1.0 |
| `weapons/osa/mag_in_1.wav` | Master Tracks/Carl Gustav M45:Swedish K/G_8.wav | take 2; 1.886958–1.922021 s; ×1.0 |
| `weapons/osa/rack_0.wav` | Master Tracks/Carl Gustav M45:Swedish K/G_2.wav | take 1; 0.936688–1.198312 s; ×1.0 |
| `weapons/osa/rack_1.wav` | Master Tracks/Carl Gustav M45:Swedish K/G_2.wav | take 2; 4.938104–5.209375 s; ×1.0 |
| `weapons/osa/dry_0.wav` | Master Tracks/Carl Gustav M45:Swedish K/G_3.wav | take 1; 0.715583–0.771708 s; ×1.0 |
| `weapons/osa/dry_1.wav` | Master Tracks/Carl Gustav M45:Swedish K/G_3.wav | take 2; 2.406229–2.457208 s; ×1.0 |
| `weapons/winchester/rack_0.wav` | Master Tracks/Marlin 336/I_10.wav | take 1; 0.848333–1.280000 s; ×1.0 |
| `weapons/winchester/rack_1.wav` | Master Tracks/Marlin 336/I_9.wav | take 2; 1.064583–1.480000 s; ×1.0 |
| `weapons/winchester/shell_in_0.wav` | Master Tracks/Marlin 336/I_0.wav | take 1; 3.518750–3.715417 s; ×1.0 |
| `weapons/winchester/shell_in_1.wav` | Master Tracks/Marlin 336/I_0.wav | take 2; 8.100333–8.280000 s; ×1.0 |
| `weapons/winchester/dry_0.wav` | Master Tracks/Marlin 336/I_8.wav | take 1; 0.916292–0.953875 s; ×1.0 |
| `weapons/winchester/dry_1.wav` | Master Tracks/Marlin 336/I_8.wav | take 1; 0.916292–0.953875 s; ×1.03 |
| `weapons/spear/shot_0.wav` | synthesis: rail A1 voice (seed 106729) pitch x0.8, reflections, 46 Hz thump + rumble | seed 108729 |
| `weapons/spear/shot_1.wav` | synthesis: rail A1 voice (seed 106730) pitch x0.78, reflections, 46 Hz thump + rumble | seed 108730 |
| `weapons/spear/shot_2.wav` | synthesis: rail A1 voice (seed 106731) pitch x0.82, reflections, 46 Hz thump + rumble | seed 108731 |
| `weapons/spear/shot_3.wav` | synthesis: rail A1 voice (seed 106732) pitch x0.79, reflections, 46 Hz thump + rumble | seed 108732 |
| `weapons/hive/shot_0.wav` | weapons/shotgun/shot_0.wav pitch x0.600 (launcher recipe) + synthesized wet pops | seed 110729 |
| `weapons/hive/stick_0.wav` | synthesis: wet slap, 170 Hz thud, squelch, three rising bubble pops | seed 109729 |
| `weapons/hive/shot_1.wav` | weapons/shotgun/shot_1.wav pitch x0.612 (launcher recipe) + synthesized wet pops | seed 110730 |
| `weapons/hive/stick_1.wav` | synthesis: wet slap, 170 Hz thud, squelch, three rising bubble pops | seed 109730 |
| `weapons/hive/shot_2.wav` | weapons/shotgun/shot_2.wav pitch x0.624 (launcher recipe) + synthesized wet pops | seed 110731 |
| `weapons/hive/stick_2.wav` | synthesis: wet slap, 170 Hz thud, squelch, three rising bubble pops | seed 109731 |
| `weapons/hive/shot_3.wav` | weapons/shotgun/shot_3.wav pitch x0.636 (launcher recipe) + synthesized wet pops | seed 110732 |
| `weapons/hive/stick_3.wav` | synthesis: wet slap, 170 Hz thud, squelch, three rising bubble pops | seed 109732 |
| `zombies/groan_0.wav` | zombies/zombie-1.wav | ×1.0 |
| `zombies/groan_1.wav` | zombies/zombie-2.wav | ×0.95 |
| `zombies/groan_2.wav` | zombies/zombie-3.wav | ×1.06 |
| `zombies/groan_3.wav` | zombies/zombie-7.wav | ×0.92 |
| `zombies/groan_4.wav` | zombies/zombie-8.wav | ×1.0 |
| `zombies/groan_5.wav` | zombies/zombie-14.wav | ×1.09 |
| `zombies/groan_6.wav` | zombies/zombie-15.wav | ×0.9 |
| `zombies/groan_7.wav` | zombies/zombie-18.wav | ×1.03 |
| `zombies/groan_8.wav` | zombies/zombie-20.wav | ×0.96 |
| `zombies/groan_9.wav` | zombies/zombie-21.wav | ×1.07 |
| `zombies/groan_10.wav` | zombies/zombie-22.wav | ×0.87 |
| `zombies/groan_11.wav` | zombies/zombie-23.wav | ×1.12 |
| `zombies/groan_12.wav` | zombies/zombie-4.wav | ×0.8 |
| `zombies/groan_13.wav` | zombies/zombie-17.wav | ×1.18 |
| `zombies/attack_0.wav` | zombies/zombie-24.wav | seed 134829 |
| `zombies/attack_1.wav` | zombies/zombie-5.wav | seed 134830 |
| `zombies/attack_2.wav` | zombies/zombie-11.wav | seed 134831 |
| `zombies/attack_3.wav` | zombies/zombie-13.wav + synthesized bite | seed 134832 |
| `zombies/attack_4.wav` | monsters/Monster-Sounds-Volume-2/Monster-5.wav + synthesized bite | seed 134833 |
| `zombies/attack_5.wav` | monsters/Monster-Sounds-Volume-2/Monster-7.wav + synthesized bite | seed 134834 |
| `zombies/death_0.wav` | zombies/zombie-12.wav (pitch glide down) + drips | seed 134929 |
| `zombies/death_1.wav` | zombies/zombie-19.wav (pitch glide down) + drips | seed 134930 |
| `zombies/death_2.wav` | zombies/zombie-9.wav (pitch glide down) + drips | seed 134931 |
| `zombies/death_3.wav` | zombies/zombie-10.wav (pitch glide down) + drips | seed 134932 |
| `zombies/death_4.wav` | zombies/zombie-6.wav (pitch glide down) + drips | seed 134933 |
| `zombies/death_5.wav` | monsters/Monster-Sounds-Volume-2/Monster-1.wav (pitch glide down) + drips | seed 134934 |
| `zombies/death_6.wav` | monsters/Monster-Sounds-Volume-2/Monster-2.wav (pitch glide down) + drips | seed 134935 |
| `zombies/death_7.wav` | monsters/Monster-Sounds-Volume-2/Monster-3.wav (pitch glide down) + drips | seed 134936 |
| `zombies/runner_0.wav` | monsters/Monster-Sounds-Volume-2/Monster-4.wav (pitch up, saturation, tremolo) | seed 135029 |
| `zombies/runner_1.wav` | monsters/Monster-Sounds-Volume-2/Monster-6.wav (pitch up, saturation, tremolo) | seed 135030 |
| `zombies/runner_2.wav` | monsters/Monster-Sounds-Volume-2/Monster-7.wav (pitch up, saturation, tremolo) | seed 135031 |
| `zombies/runner_3.wav` | monsters/Monster-Sounds-Volume-2/Monster-8.wav (pitch up, saturation, tremolo) | seed 135032 |
| `zombies/runner_4.wav` | monsters/Monster-Sounds-Volume-2/monster-16.wav (pitch up, saturation, tremolo) | seed 135033 |
| `zombies/runner_5.wav` | monsters/Monster-Sounds-Volume-2/monster-18.wav (pitch up, saturation, tremolo) | seed 135034 |
| `zombies/fat_0.wav` | monsters/Monster-Sounds-Volume-2/monster-11.wav (pitch down) + gurgles + sub | seed 135129 |
| `zombies/fat_1.wav` | monsters/Monster-Sounds-Volume-2/monster-12.wav (pitch down) + gurgles + sub | seed 135130 |
| `zombies/fat_2.wav` | monsters/Monster-Sounds-Volume-2/monster-13.wav (pitch down) + gurgles + sub | seed 135131 |
| `zombies/fat_3.wav` | monsters/Monster-Sounds-Volume-2/monster-14.wav (pitch down) + gurgles + sub | seed 135132 |
| `zombies/fat_4.wav` | monsters/Monster-Sounds-Volume-2/monster-15.wav (pitch down) + gurgles + sub | seed 135133 |
| `zombies/fat_5.wav` | zombies/zombie-16.wav (pitch down) + gurgles + sub | seed 135134 |
| `zombies/spit_0.wav` | synthesis: spray, thud, drips + monsters/Monster-Sounds-Volume-2/monster-9.wav fragment | seed 135229 |
| `zombies/spit_1.wav` | synthesis: spray, thud, drips + monsters/Monster-Sounds-Volume-2/monster-10.wav fragment | seed 135230 |
| `zombies/spit_2.wav` | synthesis: spray, thud, drips + monsters/Monster-Sounds-Volume-2/monster-17.wav fragment | seed 135231 |
| `zombies/spit_3.wav` | synthesis: spray, thud, drips + monsters/Monster-Sounds-Volume-2/monster-14.wav fragment | seed 135232 |
| `zombies/boss_roar_0.wav` | monsters/Monster-Sounds-Volume-2/Monster-2.wav + zombies/zombie-17.wav + monsters/Monster-Sounds-Volume-2/Monster-1.wav (3 layers, pitch x0.5-0.8, saturation, sub 40 Hz) | seed 135329 |
| `zombies/boss_roar_1.wav` | monsters/Monster-Sounds-Volume-2/Monster-3.wav + zombies/zombie-16.wav + monsters/Monster-Sounds-Volume-2/Monster-7.wav (3 layers, pitch x0.5-0.8, saturation, sub 40 Hz) | seed 135330 |
| `zombies/boss_roar_2.wav` | monsters/Monster-Sounds-Volume-2/Monster-1.wav + zombies/zombie-18.wav + monsters/Monster-Sounds-Volume-2/Monster-2.wav (3 layers, pitch x0.5-0.8, saturation, sub 40 Hz) | seed 135331 |
| `gore/hit_0.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135729 |
| `gore/hit_1.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135730 |
| `gore/hit_2.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135731 |
| `gore/hit_3.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135732 |
| `gore/hit_4.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135733 |
| `gore/hit_5.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135734 |
| `gore/hit_6.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135735 |
| `gore/hit_7.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135736 |
| `gore/hit_8.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135737 |
| `gore/hit_9.wav` | synthesis: bandpass flesh slap, 70-125 Hz thud, snap, drips | seed 135738 |
| `gore/splat_0.wav` | synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment (monsters/Monster-Sounds-Volume-2/monster-14.wav) | seed 136729 |
| `gore/splat_1.wav` | synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment (monsters/Monster-Sounds-Volume-2/monster-10.wav) | seed 136730 |
| `gore/splat_2.wav` | synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment (monsters/Monster-Sounds-Volume-2/monster-12.wav) | seed 136731 |
| `gore/splat_3.wav` | synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment (monsters/Monster-Sounds-Volume-2/monster-14.wav) | seed 136732 |
| `gore/splat_4.wav` | synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment (monsters/Monster-Sounds-Volume-2/monster-10.wav) | seed 136733 |
| `gore/splat_5.wav` | synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment (monsters/Monster-Sounds-Volume-2/monster-14.wav) | seed 136734 |
| `gore/splat_6.wav` | synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment (monsters/Monster-Sounds-Volume-2/monster-13.wav) | seed 136735 |
| `gore/splat_7.wav` | synthesis: slap + sub thud, bubbling gush, chunk slaps, drip tail + monster gurgle fragment (monsters/Monster-Sounds-Volume-2/monster-15.wav) | seed 136736 |
| `gore/gib_0.wav` | synthesis: wet burst + sub, tearing, bone crack series, chunk slaps 50-300 ms, drips | seed 137729 |
| `gore/gib_1.wav` | synthesis: wet burst + sub, tearing, bone crack series, chunk slaps 50-300 ms, drips | seed 137730 |
| `gore/gib_2.wav` | synthesis: wet burst + sub, tearing, bone crack series, chunk slaps 50-300 ms, drips | seed 137731 |
| `gore/gib_3.wav` | synthesis: wet burst + sub, tearing, bone crack series, chunk slaps 50-300 ms, drips | seed 137732 |
| `gore/gib_4.wav` | synthesis: wet burst + sub, tearing, bone crack series, chunk slaps 50-300 ms, drips | seed 137733 |
| `gore/gib_5.wav` | synthesis: wet burst + sub, tearing, bone crack series, chunk slaps 50-300 ms, drips | seed 137734 |
| `gore/bone_0.wav` | synthesis: stepped crack series (three broad noise resonances), knock | seed 138729 |
| `gore/bone_1.wav` | synthesis: stepped crack series (three broad noise resonances), knock | seed 138730 |
| `gore/bone_2.wav` | synthesis: stepped crack series (three broad noise resonances), knock | seed 138731 |
| `gore/bone_3.wav` | synthesis: stepped crack series (three broad noise resonances), knock | seed 138732 |
| `gore/bone_4.wav` | synthesis: stepped crack series (three broad noise resonances), knock | seed 138733 |
| `gore/bone_5.wav` | synthesis: stepped crack series (three broad noise resonances), knock | seed 138734 |
| `ambience/horde_0.wav` | synthesis: 26 groans of zombies/groan (pitch .7-1.12, distance lowpass, pan) + rumble + murmur + 7 shuffling walkers, mono, circular layers + 100 ms crossfade | seed 141729 |
| `ambience/horde_1.wav` | synthesis: 76 groans of zombies/groan (pitch .7-1.12, distance lowpass, pan) + rumble + murmur + 22 shuffling walkers, mono, circular layers + 100 ms crossfade | seed 141730 |
| `player/hurt_0.wav` | synthesis: glottal harmonic source through vowel formants + breath, saturation, body-hit layer | seed 143729 |
| `player/hurt_1.wav` | synthesis: glottal harmonic source through vowel formants + breath, saturation, body-hit layer | seed 143730 |
| `player/hurt_2.wav` | synthesis: glottal harmonic source through vowel formants + breath, saturation, body-hit layer | seed 143731 |
| `player/hurt_3.wav` | synthesis: glottal harmonic source through vowel formants + breath, saturation, body-hit layer | seed 143732 |
| `player/hurt_4.wav` | synthesis: glottal harmonic source through vowel formants + breath, saturation, body-hit layer | seed 143733 |
| `player/hurt_5.wav` | synthesis: glottal harmonic source through vowel formants + breath, saturation, body-hit layer | seed 143734 |
| `player/heartbeat_0.wav` | synthesis: lub-dub, noisy sub thuds + muffled valve click, exactly 1.000 s loop | seed 142729 |
| `ui/click_0.wav` | weapons/pistol/dry_0.wav x0.96 (A2 mechanics), lowpass 4.5 kHz, soft attack | ×0.96 |
| `ui/click_1.wav` | weapons/pistol/dry_1.wav x1.06 (A2 mechanics), lowpass 4.5 kHz, soft attack | ×1.06 |
| `ui/click_2.wav` | weapons/smg/dry_0.wav x1.0 (A2 mechanics), lowpass 4.5 kHz, soft attack | ×1.0 |
| `ui/confirm_0.wav` | weapons/pistol/dry_1.wav + weapons/smg/dry_0.wav x1.28 (A2 mechanics), two clicks 75 ms apart | ×1.28 |
| `ui/confirm_1.wav` | weapons/rifle/dry_0.wav + weapons/pistol/dry_0.wav x1.28 (A2 mechanics), two clicks 75 ms apart | ×1.28 |
| `ui/deny_0.wav` | weapons/revolver/dry_0.wav x0.6 (A2 mechanics), lowpass 1.1 kHz + dull thud, two soft knocks | seed 144229 |
| `ui/deny_1.wav` | weapons/revolver/dry_0.wav x0.52 (A2 mechanics), lowpass 1.1 kHz + dull thud, two soft knocks | seed 144230 |
| `weapons/m4/tail_0.wav` | AR-15/D_32P.wav | take 1; 0.813729–1.663729 s; ×1.0 |
| `weapons/m4/tail_1.wav` | AR-15/D_32P.wav | take 2; 5.757417–6.607417 s; ×1.0 |
| `weapons/osa/tail_0.wav` | Carl Gustav M45/G_31P.wav | take 1; 0.420292–1.070292 s; ×1.0 |
| `weapons/osa/tail_1.wav` | Carl Gustav M45/G_31P.wav | take 2; 3.611250–4.261250 s; ×1.0 |
| `weapons/osa/tail_2.wav` | Carl Gustav M45/G_31P.wav | take 3; 6.837729–7.487729 s; ×1.0 |
