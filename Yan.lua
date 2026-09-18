local gpu = require("component").gpu
local event = require("event")
local computer = require("computer")

-- Разрешение экрана
local W, H = gpu.getResolution()
if W < 40 then W = 40 end
if H < 20 then H = 20 end
gpu.setResolution(W, H)

-- Символы как в фильме (катакана + цифры + буквы)
local CHARS = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF"

-- === НАСТРОЙКИ ===
local STREAM_COUNT = math.floor(W * 0.7)  -- количество потоков
local MIN_LENGTH = 5                       -- минимальная длина следа
local MAX_LENGTH = 15                      -- максимальная длина следа
local SPEED_MIN = 1                        -- минимальная скорость
local SPEED_MAX = 3                        -- максимальная скорость
local GLOW_CHANCE = 0.05                   -- шанс случайного свечения

-- === СОСТОЯНИЕ ===
local streams = {}
local grid = {}  -- grid[x][y] = {char, brightness}

local function init()
  gpu.setBackground(0x000000)
  gpu.fill(1, 1, W, H, " ")
  
  -- Инициализация сетки
  for x = 1, W do
    grid[x] = {}
    for y = 1, H do
      grid[x][y] = {char = " ", brightness = 0}
    end
  end
  
  -- Создаём потоки
  for i = 1, STREAM_COUNT do
    table.insert(streams, {
      x = math.random(1, W),
      y = math.random(-20, -1),  -- начинаются выше экрана
      length = math.random(MIN_LENGTH, MAX_LENGTH),
      speed = math.random(SPEED_MIN, SPEED_MAX) / 10,
      timer = 0,
      active = true
    })
  end
end

local function randomChar()
  return CHARS:sub(math.random(1, #CHARS), math.random(1, #CHARS))
end

local function update()
  -- Обновляем каждый поток
  for _, stream in ipairs(streams) do
    if not stream.active then
      -- Перезапуск потока
      stream.y = math.random(-10, -1)
      stream.x = math.random(1, W)
      stream.length = math.random(MIN_LENGTH, MAX_LENGTH)
      stream.speed = math.random(SPEED_MIN, SPEED_MAX) / 10
      stream.active = true
      stream.timer = 0
    end
    
    stream.timer = stream.timer + 1
    
    if stream.timer >= stream.speed then
      stream.timer = 0
      
      -- Двигаем голову вниз
      stream.y = stream.y + 1
      
      -- Если голова ушла за экран — деактивируем
      if stream.y - stream.length > H then
        stream.active = false
      end
    end
  end
  
  -- Обновляем сетку
  for x = 1, W do
    for y = 1, H do
      -- Уменьшаем яркость (затухание)
      if grid[x][y].brightness > 0 then
        grid[x][y].brightness = grid[x][y].brightness - 0.15
        if grid[x][y].brightness < 0 then
          grid[x][y].brightness = 0
        end
        -- Случайное мерцание символов
        if math.random() < 0.3 then
          grid[x][y].char = randomChar()
        end
      end
    end
  end
  
  -- Рисуем потоки на сетке
  for _, stream in ipairs(streams) do
    if stream.active then
      for i = 0, stream.length - 1 do
        local y = stream.y - i
        if y >= 1 and y <= H and stream.x >= 1 and stream.x <= W then
          local brightness = 1.0 - (i / stream.length)
          if brightness < 0 then brightness = 0 end
          
          grid[stream.x][y].brightness = brightness
          grid[stream.x][y].char = randomChar()
        end
      end
    end
  end
  
  -- Случайные вспышки (glitch эффект)
  for _ = 1, 2 do
    local gx = math.random(1, W)
    local gy = math.random(1, H)
    if math.random() < GLOW_CHANCE then
      grid[gx][gy].brightness = 1.0
      grid[gx][gy].char = randomChar()
    end
  end
end

local function draw()
  for x = 1, W do
    for y = 1, H do
      local cell = grid[x][y]
      local b = cell.brightness
      
      if b > 0 then
        local bg, fg, char
        
        if b >= 0.9 then
          -- Голова — белый/ярко-зелёный
          bg = 0x000000
          fg = 0xFFFFFF
          char = cell.char
        elseif b >= 0.7 then
          -- Яркий зелёный
          bg = 0x000000
          fg = 0x00FF00
          char = cell.char
        elseif b >= 0.5 then
          -- Средний зелёный
          bg = 0x000000
          fg = 0x00CC00
          char = cell.char
        elseif b >= 0.3 then
          -- Тёмный зелёный
          bg = 0x000000
          fg = 0x008800
          char = cell.char
        elseif b >= 0.1 then
          -- Очень тёмный
          bg = 0x000000
          fg = 0x004400
          char = cell.char
        else
          -- Почти невидимый
          bg = 0x000000
          fg = 0x001100
          char = cell.char
        end
        
        gpu.setBackground(bg)
        gpu.setForeground(fg)
        gpu.set(x, y, char)
      else
        gpu.setBackground(0x000000)
        gpu.setForeground(0x000000)
        gpu.set(x, y, " ")
      end
    end
  end
end

-- === ГЛАВНЫЙ ЦИКЛ ===
init()

local running = true
local frameCount = 0

while running do
  update()
  draw()
  frameCount = frameCount + 1
  
  -- Проверяем ввод каждые 10 кадров (оптимизация)
  if frameCount % 10 == 0 then
    local ev = {event.pull(0)}
    if ev[1] == "key_down" then
      local ch = ev[4]
      if ch == "q" or ch == "Q" then
        running = false
      end
    elseif ev[1] == "touch" then
      running = false
    end
  end
  
  os.sleep(0.05)  -- 20 FPS
end

-- Очистка экрана
gpu.setBackground(0x000000)
gpu.fill(1, 1, W, H, " ")
gpu.setForeground(0x00FF00)
gpu.set(1, 1, "Matrix terminated. Press any key to exit...")
event.pull("key_down")
