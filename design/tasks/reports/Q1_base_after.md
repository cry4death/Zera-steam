Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Failed to read the root certificate store.
   at: get_system_ca_certificates (platform/windows/os_windows.cpp:2582)
BASETEST isolated before base ready ok
BASETEST route --sim=600 ok
BASETEST route --bench=500 ok
BASETEST route --boss ok
BASETEST route --alarm ok
BASETEST route --ui-test ok
BASETEST route --weapons-test ok
BASETEST route --loadout ok
BASETEST route --loadout-w1 ok
BASETEST route --s3-test ok
BASETEST route --meta-test ok
BASETEST route --meta-preset=maxed ok
BASETEST route --meta={} ok
BASETEST route --save-file=user://test.json ok
BASETEST route --fresh-save ok
BASETEST route --kinds ok
BASETEST route --gore-stress ok
BASETEST normal launch stays on base ok
BASETEST route --audio-test ok
BASETEST settings mouse open FAIL
BASETEST settings back ok
BASETEST settings keyboard open ok
BASETEST keyboard tab 2 ok
BASETEST mouse tab 3 FAIL
BASETEST gamepad RB tab 4 FAIL
BASETEST start level=5 points=4 ok
BASETEST barracks confirmation before spend ok
BASETEST barracks cancel keeps point ok
BASETEST barracks fire_1+mag_1 points=2 ok
BASETEST barracks locked fire_3 refused ok
BASETEST workshop m4 damage=2 mag=1 dna=460 ok
BASETEST workshop insufficient dna refused ok
BASETEST arsenal favorite rifle=m4 ok
BASETEST crate opening started crates=2 ok
BASETEST crate result recorded ok
BASETEST crate card closed ok
BASETEST rare model found ok
BASETEST rare owned cowboy ok
BASETEST open all total=4 crates=0 ok
BASETEST open all dna_not_lost ok
BASETEST open all single military ok
BASETEST single military closes ok
BASETEST to battle: dna=713 favorite_rifle=m4
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=195.00 seed=81073
BASETEST battle favorite+workshop applied ok
BASETEST defeat rewards once+paused ok
MAP loaded id=quarantine_checkpoint size=(2560.0, 1440.0) load_ms=194.97 seed=81073
BASETEST battle favorite+workshop applied ok
BASETEST restart main scene+meta kept ok
BASETEST victory rewards once+paused ok

TIMEOUT
