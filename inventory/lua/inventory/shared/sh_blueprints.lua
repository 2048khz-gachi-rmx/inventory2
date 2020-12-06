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

	["Pistol"] = {CostMult = 1, Chance = 0.3, Order = 1},
	["Assault Rifle"] = {CostMult = 1.75, Chance = 0.2},

	["Shotgun"] = {CostMult = 1.25, Chance = 0.3, Icon = {
			IconURL = "https://i.imgur.com/hTA3WB7.png",
			IconName = "trash.png",
		}
	},

	["Sniper Rifle"] = {CostMult = 1.75, Chance = 0.2, Icon = {
			IconURL = "https://i.imgur.com/85zETmx.png",
			IconName = "pepebugh.png",
			IconW = 64,
			IconH = 48
		},
	},

	["Random"] = {CostMult = 1, Default = true, Order = 2,

		Icon = {

			Render = function(w, h)
				draw.SimpleText("?", "MRB72", w/2, h/2, color_white, 1, 1)
			end,

			RenderW = 48,
			RenderH = 48,
			RenderName = "bp_random",

			IconW = 24,
			IconPad = 4
		},

	}
}

Inventory.Blueprints.WeaponPool = {}

local pool = Inventory.Blueprints.WeaponPool

pool["Assault Rifle"] = {
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

pool["SMG"] = {
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

pool["Sniper Rifle"] = {
	"arccw_go_awp",
	"arccw_go_ssg08",

	"arccw_fml_fas_m82",
	"arccw_fml_fas_m24",

	"arccw_m107",
	"arccw_m14",
}

pool["DMR"] = {
	"arccw_g3a3",

	"arccw_fml_fas_m14",
	"arccw_fml_fas_g3a3",
	"arccw_fml_fas_sr25",

	"arccw_go_g3",
	"arccw_go_scar",
	"arccw_fml_fas_sg550",
}

pool["Pistol"] = {

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