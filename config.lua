return {
  -- The name of your shop. This will appear at the top of your shop's screen.
  shopName = "Someone's Shop",

  -- Preferbally your name. This will appear at the bottom of your shop's screen, providing info on who to contact is any problems arise.
  owner = "someone",

  -- Your shop's color. This should be a hex value for pallete colours.
  colour = 0xeb5e34,

  -- The name you would like to use for this shop.
  name = "",

  -- The Krist adress this shop uses.
  address = "",

  -- The private key for the address above. This MUST be in raw-key format.
  privatekey = "",

  -- The network name of the turtle
  networkName = "",

  -- The network name of the monitor to display the shop information on
  monitorSide = "",

  -- Chests to search for items
  chests = {""},

  -- Enables attribution at the bottom of the shop pane.
  attribution = true,

  -- Set to true if you'd like items out of stock to be visible.
  showOutOfStockItems = true,

  -- Items you're selling
  items = {
    dia = {
      title = "Diamond",
      name = "minecraft:diamond",
      price = 1
    },
    oak = {
      title = "Oak Log",
      name = "minecraft:oak_log",
      price = 0.1
    },
    pc = {
      title = "Advanced Computer",
      name = "computercraft:computer_advanced",
      price = 5
    },
    stone = {
      title = "Stone",
      name = "minecraft:stone",
      price = 1
    }
  },

  -- Advanced: Krist node URL
  node = "https://krist.dev",

  -- Advanced: Sound effects to be played when purchases commence
  soundeffects = {
    enabled = false,
    speaker = "",
    purchaseFailed = "minecraft:entity.villager.no",
    purchaseSuccess = "minecraft:entity.villager.yes",
    dispensedItems = "minecraft:entity.item.pickup",
    allItemsDispensed = "minecraft:entity.player.levelup",
  }
}