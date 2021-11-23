Inventory.Blueprints = Inventory.Blueprints or {}

function Inventory.Blueprints.CreateBlank()
	return Inventory.ItemObjects.Blueprint:new(nil, "blueprint")
end

Inventory.Blueprints.Costs = {
	[1] = 10,
	[2] = 35,
	[3] = 125,
	--[[[4] = 350,]]
	--[5] = -200
}

Inventory.Blueprints.Types = {

	["pistol"] = {
		Name = "Pistol",
		CostMult = 1,
		Order = 1,

		BPIcon = {
			IconURL = "https://i.imgur.com/nf4lmzF.png",
			IconName = "bp_icons/pistol_big.png",

			IconW = 92,
			IconH = 64,
			IconScale = 0.9
		}
	},

	["ar"] = {
		Name = "Assault Rifle",
		CostMult = 1.75,

		BPIcon = {
			IconURL = "https://i.imgur.com/T9biQqd.png",
			IconName = "bp_icons/ar_big.png",

			IconW = 290,
			IconH = 108
		}
	},

	["smg"] = {
		Name = "SMG",
		CostMult = 1.75,

		BPIcon = {
			IconURL = "https://i.imgur.com/4Fz3Le9.png",
			IconName = "bp_icons/smg_big.png",

			IconW = 176,
			IconH = 74,
		}
	},

	["shotgun"] = {
		Name = "Shotgun",
		CostMult = 1.25,
		CatIcon = {
			IconURL = "https://i.imgur.com/hTA3WB7.png",
			IconName = "trash.png",
		},

		BPIcon = {
			IconURL = "https://i.imgur.com/eUr9whr.png",
			IconName = "bp_icons/sg_big.png",

			IconW = 230,
			IconH = 57,
		}
	},

	["sr"] = {
		Name = "Sniper Rifle",
		CostMult = 1.75,
		CatIcon = {
			IconURL = "https://i.imgur.com/85zETmx.png",
			IconName = "pepebugh.png",
			IconW = 64,
			IconH = 48
		},

		BPIcon = {
			IconURL = "https://i.imgur.com/sY19kWY.png",
			IconName = "bp_icons/sr_big.png",

			IconW = 349,
			IconH = 85,
		}
	},

	["dmr"] = {
		Name = "DMR",
		CostMult = 1.75,

		BPIcon = {
			IconURL = "https://i.imgur.com/guESdWb.png",
			IconName = "bp_icons/dmr_big.png",

			IconW = 294,
			IconH = 74,
		}
	},

	["random"] = {
		Name = "Random",
		CostMult = 1,
		Default = true,
		Order = 2,

		CatIcon = {
			Render = function(w, h)
				draw.SimpleText("?", "MRB72", w/2, h/2, color_white, 1, 1)
			end,

			RenderW = 48,
			RenderH = 48,
			RenderName = "bp_small_random",

			IconW = 24,
			IconPad = 4
		},

		BPIcon = {
			IconURL = "https://i.imgur.com/IFKPusX.png",
			IconName = "randombp.png",

			IconW = 64,
			IconH = 64,
			IconAng = -20,
			Flip = false
		}
	}
}

Inventory.Blueprints.WeaponPool = {}

local pool = Inventory.Blueprints.WeaponPool

pool.ar = {
	"arccw_fml_fas_akm15_whyphonemademedothis",
	"arccw_go_galil_ar",
	"arccw_go_ace",
	"arccw_go_aug",

	"arccw_go_ak47",
	"arccw_go_ar15",
	"arccw_go_famas",
	"arccw_go_m4",
	"arccw_go_sg556",

	"arccw_mifl_fas2_g36c",
	"arccw_mifl_fas2_ak47",
	"arccw_mifl_fas2_rpk",
	"arccw_mifl_fas2_sg55x",
	"arccw_mifl_fas2_m4a1",
	"arccw_mifl_fas2_famas",
}

pool.shotgun = {
	"arccw_fml_fas2_custom_mass26",
	"arccw_mifl_fas2_toz34",
	"arccw_fml_fas_m870",

	"arccw_go_nova",
	"arccw_go_m1014",

	"arccw_mifl_fas2_m3",
}


pool.smg = {
	"arccw_go_mac10",
	"arccw_go_mp5",
	"arccw_go_mp7",
	"arccw_go_mp9",
	"arccw_go_p90",
	"arccw_go_bizon",
	"arccw_go_ump",

	"arccw_mifl_fas2_mp5",
	"arccw_fml_fas_m11",
	"arccw_fml_fas_sterling",
}

pool.sr = {
	"arccw_contender",

	"arccw_go_awp",
	"arccw_go_ssg08",

	"arccw_fml_fas_m82",
	"arccw_fml_fas_m24",

	"arccw_mifl_fas2_m24",
}

pool.dmr = {
	"arccw_m14",
	"arccw_fml_fas_sg550",

	"arccw_go_g3",
	"arccw_go_scar",

	"arccw_mifl_fas2_sr25",
	"arccw_mifl_fas2_g3",
}

pool.pistol = {
	"arccw_mifl_fas2_m1911",
	"arccw_mifl_fas2_ragingbull",
	"arccw_mifl_fas2_p226",
	"arccw_mifl_fas2_deagle",

	"arccw_go_deagle",
	"arccw_go_fiveseven",
	"arccw_go_cz75",
	"arccw_go_tec9",
}

Inventory.Blueprints.WeaponPoolReverse = {}
for k,v in pairs(pool) do
	for _, gun in ipairs(v) do
		Inventory.Blueprints.WeaponPoolReverse[gun] = k
	end
end

function Inventory.Blueprints.GetCost(tier, typ)
	local baseCost = Inventory.Blueprints.Costs[tier]
	if not baseCost then printf("!!! no cost for tier %s !!!", tier) return false end

	local dat = typ and Inventory.Blueprints.Types[typ]
	if typ and not dat then printf("!!! no data for type %s !!!", typ) return false end

	return math.floor(baseCost * (dat and dat.CostMult or 1))
end