local config = require("config")

local node = config.node
local wsURL
local ws
local stock = {}

local recheckStockTimer = os.startTimer(30)

local function postJSON(url, data)
  local file = http.post(node .. "/" .. url, textutils.serialiseJSON(data), {
    ["Content-Type"] = "application/json"
  })

  if file then
    local data = textutils.unserialiseJSON(file.readAll())
    file.close()
    return data
  else
    error("not ok")
  end
end

local function sfx(type)
  if config.soundeffects.enabled == true and config.soundeffects[type] then
    local speaker = peripheral.wrap(config.soundeffects.speaker)

    if speaker then
      speaker.playSound(config.soundeffects[type])
    else
      error("A speaker is required for sound effects to work.")
    end
  end
end

local function scan()
  stock = {}

  local function scanChest(side)
    local items = peripheral.call(side, "list")

    for i, v in pairs(items) do
      if stock[v.name] then
        stock[v.name] = stock[v.name] + v.count
      else
        stock[v.name] = v.count
      end
    end
  end

  for i, v in pairs(config.chests) do
    scanChest(v)
  end
end

local function draw(state)
  local m = peripheral.wrap(config.monitorSide)
  m.setTextScale(0.5)
  local w, h = m.getSize()
  m.setPaletteColour(colors.lightBlue, config.colour)

  if state and state.connecting == true then
    m.setBackgroundColor(colors.gray)
    m.clear()
    m.setTextColor(colors.lightGray)
    local text = "Starting..."
    m.setCursorPos(math.floor(w / 2 + 0.5) - math.floor(#text / 2 + 0.5), math.floor(h / 2 + 0.5))
    m.write(text)
  else
    m.setBackgroundColor(colors.white)
    m.clear()

    -- header

    for i = 1, 4 do
      m.setCursorPos(1, i)
      m.setBackgroundColor(colors.lightBlue)
      m.clearLine()
    end

    m.setCursorPos(1, 2)
    m.setTextColor(colors.white)
    local text = config.shopName
    m.setCursorPos(math.floor(w / 2 + 0.5) - math.floor(#text / 2 + 0.5), 2)
    m.write(text)

    -- main section
    m.setBackgroundColor(colors.lightGray)
    m.setTextColor(colors.gray)
    m.setCursorPos(2, 4)
    m.clearLine()
    m.write("Stock")

    m.setCursorPos(9, 4)
    m.write("Item")

    m.setCursorPos(w - 5, 4)
    m.write("Price")

    local maxw = 0
    for i, v in pairs(config.items) do
      maxw = math.max(maxw, #config.name + #i + 2)
    end

    m.setCursorPos(w - 5 - maxw, 4)
    m.write("Pay To")

    local y = 5
    for i, v in pairs(config.items) do
      m.setCursorPos(2, y)
      local stock = stock[v.name] or 0

      m.setBackgroundColor(colors.white)

      if stock == 0 then m.setTextColor(colors.red)
      elseif stock <= 10 then m.setTextColor(colors.orange)
      elseif stock <= 20 then m.setTextColor(colors.yellow)
      else m.setTextColor(colors.gray) end

      m.write(tostring(stock))

      m.setTextColor(colors.gray)
      m.setCursorPos(9, y)
      m.write(v.title)

      m.setCursorPos(w - 5, y)
      m.write("K" .. tostring(v.price))

      m.setCursorPos(w - 5 - maxw, y)
      m.write(i .. "@" .. config.name)

      y = y + 1
    end

    -- footer
    m.setTextColor(colors.white)

    for i = h, h - 2, -1 do
      m.setCursorPos(1, i)
      m.setBackgroundColor(colors.lightBlue)
      m.clearLine()
    end

    text = ("This shop is owned by %s."):format(config.owner, config.owner)
    m.setCursorPos(math.floor(w / 2 + 0.5) - math.floor(#text / 2 + 0.5), h - 1)
    m.write(text)

    if config.attribution then
      -- Yet Another Simple Shop, Lists Amazing Yeilds
      text = ("YASSLAY by znepb")
      m.setCursorPos(math.floor(w / 2 + 0.5) - math.floor(#text / 2 + 0.5), h)
      m.write(text)
    end
  end
end

local function connect()
  print("Attempting connection...")
  wsURL = postJSON("ws/start", { privatekey = config.privatekey }).url
  http.websocketAsync(wsURL)
end

scan()
draw{connecting = true}
connect()

while true do
  local e = {os.pullEventRaw()}

  if e[1]:match("^websocket") and e[2]:match("^" .. wsURL) then
    if e[1] == "websocket_success" then
      print("Connection successful!")
      ws = e[3]
      draw()
      sfx("allItemsDispensed")
    elseif e[1] == "websocket_failure" then
      print("Connection failed. " .. e[3])
    elseif e[1] == "websocket_message" then
      local data = textutils.unserialiseJSON(e[3])

      if data.type == "hello" then
        print("MOTD: " .. data.motd)
      elseif data.type == "event" then
        if data.event == "transaction" then
          local tx = data.transaction
          print("Purchase received!")

          if tx.to == config.address and tx.sent_name == config.name:gsub(".kst", "") then
            local slug = tx.sent_metaname:lower()
            local returnaddr = tx.from

            if tx.metadata:match("return=([[%a%d_]+@]?[%a%d]+.kst);") then
              returnaddr = tx.metadata:match("return=([[%a%d_]+@]?[%a%d]+.kst);")
            end

            if config.items[slug] then
              local item = config.items[slug]
              if stock[item.name] then
                sfx("purchaseSuccess")

                local amount = math.floor(tx.value / item.price) -- Amount of items that the player requested
                local available = stock[item.name] -- Amount of items the player requested
                local dispense = math.min(amount, available)
                local returnAmount = tx.value - amount * item.price

                local returnMessage = "You overpayed for your purchase. Here is a refund."

                local dispensed = 0
                local remainingToDispense = dispense

                for _, c in pairs(config.chests) do
                  for s, v in pairs(peripheral.call(c, "list")) do
                    if v.name == item.name then
                      peripheral.call(c, "pushItems", config.networkName, s, math.min(v.count, remainingToDispense), 1)
                      turtle.select(1)
                      turtle.drop(64)

                      sfx("dispensedItems")
                      remainingToDispense = remainingToDispense - v.count
                      if remainingToDispense <= 0 then break end
                    end
                  end

                  if remainingToDispense <= 0 then break end
                end

                sfx("allItemsDispensed")

                if remainingToDispense >= 1 then
                  returnAmount = returnAmount + math.floor(remainingToDispense * item.price)
                  returnMessage = "You ordered too many items, and not enough were in stock. Here is a refund."
                  print("Success, but ran out of stock.")
                elseif returnAmount >= 1 then
                  print("Success, but overpayed")
                end

                if returnAmount >= 1 then
                  postJSON("transactions", {
                    privatekey = config.privatekey,
                    to = returnaddr,
                    amount = returnAmount,
                    metadata = returnaddr .. ";message=" .. returnMessage
                  })
                  print("Refund issued")
                end

                print("Purchase success")
                scan()
                draw()
              else
                postJSON("transactions", {
                  privatekey = config.privatekey,
                  to = returnaddr,
                  amount = tx.value,
                  metadata = returnaddr .. ";message=Sorry, the item \"" .. item.title .. "\" is not in stock."
                })
                sfx("purchaseFailed")
                print("Failed: out of stock.")
              end
            else
              print(slug .. " requested, but does not exist. Refunding player.")
              postJSON("transactions", {
                privatekey = config.privatekey,
                to = returnaddr,
                amount = tx.value,
                metadata = returnaddr .. ";message=The requested item, " .. slug .. ", does not exist. Please try another item."
              })
              sfx("purchaseFailed")
            end
          end
        end
      end
    end
  elseif e[1] == "terminate" then
    printError("Terminated")
    ws.close()
    break
  elseif e[1] == "timer" and e[2] == recheckStockTimer then
    scan()
    draw()
    recheckStockTimer = os.startTimer(30)
  end
end