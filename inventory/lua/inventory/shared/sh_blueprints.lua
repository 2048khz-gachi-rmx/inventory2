Inventory.Blueprints = {}

Inventory.Blueprints.Costs = {
	[1] = 5,
	[2] = 20,
	[3] = 50,
	[4] = 125,
	--[5] = -200
}

Inventory.Blueprints.Types = {

	["Pistol"] = {CostMult = 1, Order = 1},
	["Assault Rifle"] = {CostMult = 1.75},

	["Shotgun"] = {CostMult = 1.25, Icon = {
			IconURL = "https://i.imgur.com/hTA3WB7.png",
			IconName = "trash.png",
		}
	},

	["Sniper Rifle"] = {CostMult = 1.75, Icon = {
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