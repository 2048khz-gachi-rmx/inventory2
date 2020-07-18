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
}

pool["Sniper Rifle"] = {
	"arccw_awm",
	"arccw_sg550",

	"arccw_m14", --DMRs are sniper rifles in my book, don't @ me
	"arccw_g3a3",
}
pool["Pistol"] = {
	"arccw_g18",
	"arccw_m9"
}