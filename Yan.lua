local gpu = require("component").gpu
local event = require("event")
local computer = require("computer")

-- Настройки
local WIDTH, HEIGHT = gpu.getResolution()
local CHARS = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local FALL_SPEED = 0.05  -- скорость падения (меньше = быстрее)
local FADE_SPEED = 0.1   -- скорость затухания следов

-- Цвета
local C_BG = 0x000000
local C_HEAD = 0x00FF00      -- яркий зелёный (голова)
local C_BODY = 0x00AA00      -- средний зелёный (тело)
local C_TAIL = 0x005500      -- тёмный зелёный (хвост)
local C_FADE = 0x002200      -- очень тёмный (затухание)

-- Состояние колонок
local columns = {}
local drops = {}
local trails = {}

local function init()
  gpu.setBackground(C_BG)
  gpu.fill(1, 1, WIDTH, HEIGHT, " ")
  
  for x = 1, WIDTH do
    columns[x] = {
      y = math.random(1, HEIGHT),
      speed = math.random(1, 3) * 0.5,
      counter = 0
    }
    drops[x] = 0
    trails[x] = {}
    for y = 1, HEIGHT do
      trails[x][y] = 0
    end
  end
end

local function getRandomChar()
  local idx = math.random(1, #CHARS)
  return CHARS:sub(idx, idx)
end

local function update()
  for x = 1, WIDTH do
    local col = columns[x]
    col.counter = col.counter + 1
    
    if col.counter >= col.speed then
      col.counter = 0
      
      -- Сдвигаем следы вниз
      for y = HEIGHT, 2, -1 do
        trails[x][y] = trails[x][y-1]
      end
      trails[x][1] = 0
      
      -- Новая голова
      drops[x] = col.y
      col.y = col.y + 1
      
      if col.y > HEIGHT + 5 then
        col.y = math.random(-5, 0)
        col.speed = math.random(1, 3) * 0.5
      end
    end
  end
end

local function draw()
  for x = 1, WIDTH do
    local col = columns[x]
    local headY = col.y - 1
    
    -- Рисуем голову (яркий символ)
    if headY >= 1 and headY <= HEIGHT then
      local char = getRandomChar()
      gpu.setBackground(C_HEAD)
      gpu.setForeground(C_HEAD)
      gpu.set(x, headY, char)
      trails[x][headY] = 3
    end
    
    -- Рисуем следы
    for y = 1, HEIGHT do
      local fade = trails[x][y]
      if fade > 0 then
        local char = getRandomChar()
        if fade == 3 then
          gpu.setBackground(C_BODY)
          gpu.setForeground(C_BODY)
        elseif fade == 2 then
          gpu.setBackground(C_TAIL)
          gpu.setForeground(C_TAIL)
        else
          gpu.setBackground(C_FADE)
          gpu.setForeground(C_FADE)
        end
        gpu.set(x, y, char)
        trails[x][y] = fade - 1
      end
    end
  end
end

local function clearScreen()
  gpu.setBackground(C_BG)
  gpu.setForeground(C_BG)
  gpu.fill(1, 1, WIDTH, HEIGHT, " ")
end

-- Главный цикл
init()

local running = true
while running do
  update()
  draw()
  
  -- Проверяем события
  local ev = {event.pull(0)}
  if ev[1] == "key_down" then
    local ch = ev[4]
    if ch == "q" or ch == "Q" then
      running = false
    end
  elseif ev[1] == "touch" then
    running = false
  end
  
  os.sleep(FALL_SPEED)
end

clearScreen()
gpu.setForeground(0x00FF00)
gpu.setBackground(0x000000)
gpu.set(1, 1, "Matrix terminated. Press any key...")
event.pull("key_down")
