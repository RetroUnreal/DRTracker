local _, DRTracker = ...

if UnitLevel("player") > 19 then
	DRTracker.metaDB = {
		DEATHKNIGHT = {
			ctrlstun = "spell_deathknight_gnaw_ghoul",
			disorient = "inv_staff_15",
			silence = "spell_shadow_soulleech_3",
		},
		DRUID = {
			ctrlstun = "ability_druid_bash",
			cyclone = "spell_nature_earthbind",
			ctrlroot = "spell_nature_stranglevines",
			sleep = "spell_nature_sleep",
			openstun = "ability_druid_supriseattack",
		},
		HUNTER = {
			disarm = "ability_hunter_chimerashot2",
			entrapment = "spell_nature_stranglevines",
			disorient = "spell_frost_chainsofice",
			ctrlroot = "spell_nature_web",
			fear = "ability_druid_cower",
			scatter = "ability_golemstormbolt",
			ctrlstun = "ability_druid_primaltenacity",
			silence = "ability_theblackarrow",
			intimidation = "ability_devour",
		},
		MAGE = {
			ctrlroot = "spell_frost_frostnova",
			disorient = "spell_nature_polymorph",
			silence = "spell_frost_iceshock",
		},
		PALADIN = {
			ctrlstun = "spell_holy_sealofmight",
			disorient = "spell_holy_prayerofhealing",
			fear = "spell_holy_turnundead",
		},
		PRIEST = {
			fear = "spell_shadow_psychicscream",
			mc = "spell_shadow_shadowworddominate",
			horror = "spell_shadow_psychichorrors",
			disarm = "ability_warrior_disarm",
			disorient = "spell_nature_slow",
			silence = "spell_shadow_impphaseshift",
		},
		ROGUE = {
			fear = "spell_shadow_mindsteal",
			openstun = "ability_cheapshot",
			disarm = "ability_rogue_dismantle",
			silence = "ability_rogue_garrote",
			disorient = "ability_gouge",
			ctrlstun = "ability_rogue_kidneyshot",
		},
		SHAMAN = {
			ctrlstun = "ability_druid_bash",
			disorient = "spell_shaman_hex",
		},
		WARLOCK = {
			banish = "spell_shadow_cripple",
			horror = "spell_shadow_deathcoil",
			ctrlstun = "spell_shadow_shadowfury",
			fear = "spell_shadow_possession",
			silence = "spell_shadow_mindrot",
		},
		WARRIOR = {
			ctrlstun = "ability_thunderbolt",
			disarm = "ability_warrior_disarm",
			silence = "ability_warrior_shieldbash",
			fear = "ability_golemthunderclap",
		},
	}
	
	DRTracker.spellDB = {
		ctrlstun = {
			-- Intercept
			20253,
			-- Kidney Shot
			8643,
			408,
			-- Hammer of Justice
			10308,
			5589,
			5588,
			853,
			-- Deep Freeze
			44572,
			-- Shadowfury
			47847,
			47846,
			30414,
			30413,
			30283,
			-- Concussion Blow
			12809,
			-- Shockwave
			46968,
			-- Bash
			8983,
			6798,
			5211,
			-- Maim
			49802,
			22570,
			-- Gnaw (Pet)
			47481,
			-- War Stomp (Racial)
			20549,
			-- Holy Wrath
			48817,
			48816,
			27139,
			10318,
			2812,
			-- Bash (Pet)
			58861,
			-- Ravage (Pet)
			53562,
			53561,
			53560,
			53559,
			53558,
			50518,
			-- Sonic Blast (Pet)
			53568,
			53567,
			53566,
			53565,
			53564,
			50519,
			-- Demon Charge
			60995,
			-- Intercept (Pet)
			47995,
			30197,
			30195,
			30153,
			-- Inferno
			22703,
		},
		disorient = {
			-- Sap
			51724,
			11297,
			2070,
			6770,
			-- Gouge
			1776,
			-- Polymorph
			12826,
			28271,
			28272,
			61025,
			61305,
			61721,
			61780,
			12825,
			12824,
			118,
			-- Repentance
			20066,
			-- Hungering Cold
			49203,
			-- Freezing Trap
			14309,
			14308,
			3355,
			-- Freezing Arrow
			60210,
			-- Wyvern Sting
			49012,
			49011,
			27068,
			24133,
			24132,
			19386,
			-- Hex
			51514,
			-- Dragon's Breath
			42950,
			42949,
			33043,
			33042,
			33041,
			31661,
			-- Shackle Undead
			10955,
			9485,
			9484,
		},
		fear = {
			-- Blind
			2094,
			-- Fear
			6215,
			6213,
			5782,
			-- Howl of Terror
			17928,
			5484,
			-- Intimidating Shout
			20511,
			-- Psychic Scream
			10890,
			10888,
			8124,
			8122,
			-- Seduction (Pet)
			6358,
			-- Scare Beast
			14327,
			14326,
			1513,
			-- Turn Evil
			10326,
		},
		horror = {
			-- Psychic Horror
			64044,
			-- Death Coil
			47860,
			47859,
			27223,
			17926,
			17925,
			6789,
		},
		silence = {
			-- Strangulate
			47476,
			-- Silencing Shot
			34490,
			-- Improved Counterspell
			55021,
			18469,
			-- Silence
			15487,
			-- Garrote
			1330,
			-- Spell Lock
			24259,
			-- Gag Order
			18498,
			-- Arcane Torrent (Racial)
			25046,
			28730,
			50613,
			-- Unstable Affliction
			31117,
			-- Shield of the Templar
			63529,
			-- Improved Kick
			18425,
		},
		cyclone = {
			-- Cyclone
			33786,
		},
		ctrlroot = {
			-- Freeze (Pet)
			33395,
			-- Frost Nova
			42917,
			27088,
			10230,
			6131,
			865,
			122,
			-- Entangling Roots
			53308,
			26989,
			9853,
			9852,
			5196,
			5195,
			1062,
			339,
			-- Nature's Grasp
			53313,
			27010,
			19970,
			19971,
			19972,
			19973,
			19974,
			19975,
			-- Pin (Pet)
			53548,
			53547,
			53546,
			53545,
			53544,
			50245,
			-- Web (Pet)
			4167,
			-- Venom Web Spray (Pet)
			55509,
			55508,
			55507,
			55506,
			55505,
			54706,
		},
		sleep = {
			-- Hibernate
			18658,
			18657,
			2637,
		},
		openstun = {
			-- Cheap Shot
			1833,
			-- Pounce
			49803,
			27006,
			9827,
			9823,
			9005,
		},
		disarm = {
			-- Dismantle
			51722,
			-- Psychic Horror
			64058,
			-- Disarm
			676,
			-- Chimera Shot - Scorpid
			53359,
			-- Snatch (Pet)
			53543,
			53542,
			53540,
			53538,
			53537,
			50541,
		},
		entrapment = {
			-- Entrapment
			64804,
			64803,
			19185,
		},
		scatter = {
			-- Scatter Shot
			19503,
		},
		mc = {
			-- Mind Control
			605,
		},
		banish = {
			-- Banish
			18647,
			710,
		},
		intimidation = {
			-- Intimidation
			24394,
		},
	}
else
	DRTracker.metaDB = {
		DRUID = {
			ctrlstun = "ability_druid_bash",
			ctrlroot = "spell_nature_stranglevines",
			sleep = "spell_nature_sleep",
		},
		HUNTER = {
			disarm = "spell_nature_natureswrath",
			ctrlstun = "ability_druid_primaltenacity",
			ctrlroot = "spell_nature_web",
			fear = "ability_druid_cower",
			silence = "spell_shadow_teleport",
		},
		MAGE = {
			ctrlroot = "spell_frost_frostnova",
			disorient = "spell_nature_polymorph",
			silence = "spell_shadow_teleport",
		},
		PALADIN = {
			ctrlstun = "spell_holy_sealofmight",
			silence = "spell_shadow_teleport",
		},
		PRIEST = {
			fear = "spell_shadow_psychicscream",
			silence = "spell_shadow_teleport",
		},
		ROGUE = {
			disorient = "ability_gouge",
			silence = "spell_shadow_teleport",
		},
		SHAMAN = {
			ctrlstun = "ability_warstomp",
		},
		WARLOCK = {
			fear = "spell_shadow_possession",
			silence = "spell_shadow_teleport",
		},
		WARRIOR = {
			disarm = "ability_warrior_disarm",
			ctrlstun = "ability_warstomp",
		},
	}

	DRTracker.spellDB = {
		ctrlstun = {
			-- Hammer of Justice
			853,
			-- Bash
			5211,
			-- War Stomp (Racial)
			20549,
			-- Ravage (Pet)
			53558,
			50518,
			-- Sonic Blast (Pet)
			53564,
			50519,
		},
		ctrlroot = {
			-- Entangling Roots
			1062,
			339,
			-- Nature's Grasp
			19974,
			19975,
			-- Pin (Pet)
			53544,
			50245,
			-- Web (Pet)
			4167,
			-- Frost Nova
			122,
		},
		disorient = {
			-- Sap
			6770,
			-- Gouge
			1776,
			-- Polymorph
			118,
			-- Discombobulate
			4060,
		},
		fear = {
			-- Fear
			5782,
			-- Psychic Scream
			8122,
			-- Scare Beast
			1513,
		},
		disarm = {
			-- Disarm
			676,
			-- Snatch (Pet)
			53537,
			50541,
		},
		sleep = {
			-- Hibernate
			2637,
		},
		silence = {
			-- Arcane Torrent (Racial)
			25046,
			28730,
		},
	}
end

-- =========================
-- Build name -> category map
-- =========================
DRTracker.nameDB = DRTracker.nameDB or {}

do
  -- Clear then fill from spell IDs above
  wipe(DRTracker.nameDB)
  for cat, ids in pairs(DRTracker.spellDB or {}) do
    for i = 1, #ids do
      local name = GetSpellInfo(ids[i])
      if name then
        DRTracker.nameDB[name] = cat
      end
    end
  end

  -- (Optional) manual safety overrides if your core/server uses odd spell names.
  -- Only add a line if you find a name in CLEU that didn't get picked up:
  -- DRTracker.nameDB["Polymorph"]        = "disorient"
  -- DRTracker.nameDB["Polymorph: Pig"]   = "disorient"
  -- DRTracker.nameDB["Polymorph: Turtle"]= "disorient"
end
