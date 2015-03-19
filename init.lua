--init.lua

require('ds18b20')
port = 80
gpio0 = 3

key = 'livingroom'
temp = 0
ds18b20.setup(gpio0)

wifi.setmode(wifi.STATION)
wifi.sta.config("SSID","PASSWORD")

--Test to reduce power consumption
realtype = wifi.sleeptype(wifi.MODEM_SLEEP)

print("Sleepmode "..realtype)

function readTemp()
  local current_temp = ds18b20.read()
  current_temp = ds18b20.read()
  current_temp = string.format("%8.1f", current_temp)
  print("Read temp " ..current_temp)
  if current_temp ~= temp then
    sendData(current_temp)
    temp = current_temp
  end
end

function sendData(up_temp)
  wifi.sta.connect()
  tmr.alarm(1, 1000, 1, function() 
    if wifi.sta.getip()== nil then 
      --print("IP unavaiable, Waiting...") 
    else 
      tmr.stop(1)
      -- Send value to server.
      conn=net.createConnection(net.TCP, 0) 
      conn:on("receive", function(conn, payload) print(payload) end)
      conn:connect(80,'11.22.33.44') 
      conn:send("GET /temptest.php?key="..key.."&field1="..up_temp.." HTTP/1.1\r\n") 
      conn:send("Host: example.com\r\n") 
      conn:send("Accept: */*\r\n") 
      conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
      conn:send("\r\n")
      conn:on("sent",function(conn)
        conn:close()
      end)
      conn:on("disconnection", function(conn)
        -- Disconnect from network and save energy.
        wifi.sta.disconnect()
      end)
    end 
  end)
end

-- run at startup.
readTemp()
-- send data every X ms, 1800000 == 30 minutes
tmr.alarm(0, 1800000, 1, function() readTemp() end )
R