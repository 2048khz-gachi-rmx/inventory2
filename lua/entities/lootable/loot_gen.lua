--
Inventory.LootGen.Pools = Inventory.LootGen.Pools or {}

local function make(n, mdls)
	local pool = Inventory.LootGen.Pool:new(n)
	Inventory.LootGen.Pools[n] = pool
	pool.Models = mdls

	return pool
end

local pool = make("scrap_low_small")
pool:Add("blank_bp", 2, {Amount = {3, 9}})
pool:Add("wire", 1, {Amount = {2, 5}})
pool:Add("capacitor", 1, {Amount = {1, 2}})
pool:Add("circuit_board", 0.8, {Amount = {1, 2}})
pool:Add("stem_cells", 0.75, {Amount = {1, 2}})
pool:Add("laserdiode", 0.5, {Amount = {1, 3}})
pool:Add("radiator", 0.4, {Amount = 1})
pool:Add("weaponparts", 0.3, {Amount = 1})
pool:Add("card1", 0.2)

local pool = make("wepcrate_low_small", {

})


local lootInfo = {
	weapon = {
		small = {
			amt = {1, 2},
			appearChance = 0.5,
			loot = {
				weaponparts = {1, 2, 0.7},
				laserdiode = {2, 4, 0.6},
				lube = {1, 2, 0.4},
				_weapon = {{
					[1] = 7, -- t1: 7/8
					[2] = 1, -- t2: 1/8
				}, 0, 0.6},
			},
		},

		medium = {
			amt = {2, 3},
			appearChance = 0.25,
			loot = {
				weaponparts = {2, 4, 0.8},
				wepkit = {1, 1, 0.2},
				laserdiode = {3, 6, 0.7},
				lube = {2, 4, 0.6},
				_weapon = {{
					[1] = 3, -- t1: 3/4
					[2] = 1, -- t2: 1/4
				}, 0, 0.9}
			},
		}
	},

	scraps = {
		small = {
			appearChance = 0.8,
			amt = {1, 3},
			loot = {
				blank_bp = {3, 9},
				stem_cells = {1, 2, 0.3},
				weaponparts = {1, 1, 0.1},
				laserdiode = {1, 2, 0.2},
				-- circuit_board = {1, 2, 0.3},
				-- capacitor = {1, 4},
				-- adhesive = {1, 1, 0.35},
			}
		},

		medium = {
			appearChance = 0.4,
			amt = {3, 5},
			loot = {
				blank_bp = {10, 16},
				blood_nanobots = {1, 3, 0.2},
				tgt_finder = {1, 1, 0.3},
				laserdiode = {2, 3, 0.2},
				lube = {1, 1, 0.5},
				-- circuit_board = {2, 4, 0.6},
				-- emitter = {1, 1, 0.3},
				-- cpu = {1, 1, 0.2},
				-- capacitor = {3, 7},
				--adhesive = {1, 3, 0.5},
				weaponparts = {1, 1, 0.2}
			}
		}
	},
}