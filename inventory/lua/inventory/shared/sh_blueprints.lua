Inventory.Blueprints = Inventory.Blueprints or {}

function Inventory.Blueprints.CreateBlank()
	return Inventory.ItemObjects.Blueprint:new(nil, "blueprint")
end

Inventory.Blueprints.Costs = {
	[1] = 5,
	[2] = 20,
	[3] = 50,
	[4] = 125,
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
	"arccw_famas",
	"arccw_galil556",
	"arccw_sg552",
	"arccw_ak47",
	"arccw_aug",
	"arccw_augpara",
	"arccw_m4a1",

	"arccw_go_ace",
	"arccw_go_ak47",
	"arccw_go_ar15",
	"arccw_go_aug",
	"arccw_go_famas",
	"arccw_go_m4",
	"arccw_go_sg556",

	"arccw_fml_fas_m4a1",
	"arccw_fml_fas_akm15_whyphonemademedothis",
	"arccw_fml_fas_famas",
	"arccw_fml_fas_g36c",
	"arccw_fml_fas_m16a2",
}

pool.shotgun = {
	"arccw_go_mag7",
	"arccw_go_870",
	"arccw_go_nova",
	"arccw_go_m1014",
	"arccw_m1014",
}


pool.smg = {
	"arccw_go_mac10",
	"arccw_go_mp5",
	"arccw_go_mp7",
	"arccw_go_mp9",
	"arccw_go_p90",
	"arccw_go_bizon",
	"arccw_go_ump",

	"arccw_fml_fas_mp5",
	"arccw_fml_fas_m11",

	"arccw_bizon",
	"arccw_vector",
	"arccw_mp7",
	"arccw_fml_fas_sterling",

}

pool.sr = {
	"arccw_go_awp",
	"arccw_go_ssg08",

	"arccw_fml_fas_m82",
	"arccw_fml_fas_m24",

	"arccw_m107",
	"arccw_m14",
}

pool.dmr = {
	"arccw_g3a3",

	"arccw_fml_fas_m14",
	"arccw_fml_fas_g3a3",
	"arccw_fml_fas_sr25",

	"arccw_go_g3",
	"arccw_go_scar",
	"arccw_fml_fas_sg550",
}

pool.pistol = {

	"arccw_deagle50",
	"arccw_deagle357",
	"arccw_ragingbull",
	"arccw_makarov",

	"arccw_go_deagle",
	"arccw_go_fiveseven",
	"arccw_go_cz75",
	"arccw_go_r8",
	"arccw_go_tec9",

	"arccw_fml_fas_deagle",

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

	local dat = Inventory.Blueprints.Types[typ]
	if not dat then printf("!!! no data for type %s !!!", typ) return false end

	return math.floor(baseCost * dat.CostMult)
end