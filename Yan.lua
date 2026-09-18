local gpu = require("component").gpu
local event = require("event")
local computer = require("computer")

local W, H = gpu.getResolution()
if W < 40 then W = 40 end
if H < 20 then H = 20 end
gpu.setResolution(W, H)

local CHARS = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF"

local streams = {}
local STREAM_COUNT = math.floor(W * 0.8)

local function randomChar()
  return CHARS:sub(math.random(1, #CHARS), math.random(1, #CHARS))
end

local function init()
  gpu.setBackground(0x000000)
  gpu.fill(1, 1, W, H, " ")
  
  for i = 1, STREAM_COUNT do
    table.insert(streams, {
      x = math.random(1, W),
      y = math.random(-30, -5),
      length = math.random(8, 20),
      speed = math.random(1, 3) / 10,
      timer = 0,
      chars = {}
    })
  end
end

local function update()
  for _, s in ipairs(streams) do
    s.timer = s.timer + 1
    if s.timer >= s.speed then
      s.timer = 0
      s.y = s.y + 1
      
      -- Добавляем новый символ в голову
      table.insert(s.chars, 1, randomChar())
      
      -- Ограничиваем длину
      if #s.chars > s.length then
        table.remove(s.chars)
      end
      
      -- Если поток ушёл за экран — перезапуск
      if s.y - s.length > H then
        s.y = math.random(-20, -5)
        s.x = math.random(1, W)
        s.length = math.random(8, 20)
        s.speed = math.random(1, 3) / 10
        s.chars = {}
      end
    end
  end
end

local function draw()
  -- Очищаем экран
  gpu.setBackground(0x000000)
  gpu.fill(1, 1, W, H, " ")
  
  -- Рисуем каждый поток
  for _, s in ipairs(streams) do
    for i = 1, #s.chars do
      local y = s.y - i + 1
      if y >= 1 and y <= H and s.x >= 1 and s.x <= W then
        local char = s.chars[i]
        
        if i == 1 then
          -- Голова — белый/ярко-зелёный
          gpu.setBackground(0x000000)
          gpu.setForeground(0xFFFFFF)
        elseif i <= 3 then
          -- Яркий зелёный
          gpu.setBackground(0x000000)
          gpu.setForeground(0x00FF00)
        elseif i <= 6 then
          -- Средний зелёный
          gpu.setBackground(0x000000)
          gpu.setForeground(0x00CC00)
        elseif i <= 10 then
          -- Тёмный зелёный
          gpu.setBackground(0x000000)
          gpu.setForeground(0x008800)
        else
          -- Очень тёмный
          gpu.setBackground(0x000000)
          gpu.setForeground(0x004400)
        end
        
        gpu.set(s.x, y, char)
      end
    end
  end
end

init()

local running = true
while running do
  update()
  draw()
  
  local ev = {event.pull(0)}
  if ev[1] == "key_down" then
    local ch = ev[4]
    if ch == "q" or ch == "Q" then running = false end
  elseif ev[1] == "touch" then
    running = false
  end
  
  os.sleep(0.05)
end

gpu.setBackground(0x000000)
gpu.fill(1, 1, W, H, " ")
gpu.setForeground(0x00FF00)
gpu.set(1, 1, "Matrix terminated. Press any key...")
event.pull("key_down")
