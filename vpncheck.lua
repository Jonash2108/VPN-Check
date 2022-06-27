if not menu.is_trusted_mode_enabled(8) then
    menu.notify("Trusted mode for http not enabled", "VPN/Proxy Check", 10)
    return
end
menu.create_thread(function()

    local api = menu.add_feature("VPN/Proxy Check API:", "autoaction_value_str", 0)
    api:set_str_data({"proxycheck.io", "ip-api.com"})

    menu.add_player_feature("VPN/Proxy Check", "action", 0, function(f, pid)
        if player.is_player_valid(pid) then
            if not network.is_session_started() then
                menu.notify("Please join online", "VPN/Proxy Check", 10)
                return
            end
            pIp = dec_to_ipv4(player.get_player_ip(pid))
            if api.value == 0 then
                statusCode, response = web.get("https://proxycheck.io/v2/"..pIp.."?vpn=1")
                if response:find("ok") then
                    if response:find('"proxy": "no"') then
                        notify(2)
                    elseif response:find('"proxy": "yes"') then
                        if response:find("name") then
                            notify(1, response:match("\"name\":%s+\"([^\"]+)\","))
                        else
                            notify(1)
                        end
                    end
                elseif response:find("error") then
                    notify(3)
                elseif response:find("denied") then
                    notify(4,nil,1)
                end
            else
                statusCode, response = web.get("http://ip-api.com/json/"..pIp.."?fields=147456")
                if response:find("success") then
                    if response:find("true") then
                        notify(1)
                    elseif response:find("false") then
                        notify(2)
                    end
                elseif response:find("fail") then
                    notify(3)
                elseif statusCode == "429" then
                    notify(4,nil,2)
                end
            end
        end
    end)

end,nil)

function dec_to_ipv4(ip)
    return string.format("%i.%i.%i.%i", ip >> 24 & 255, ip >> 16 & 255, ip >> 8 & 255, ip & 255)
end

function notify(num,str,var)
    if num == 1 then
        menu.notify('Player is using a VPN/Proxy\nVPN: '..(str or "Unknown"), "VPN/Proxy Check")
    elseif num == 2 then
        menu.notify("Player is not using VPN/Proxy", "VPN/Proxy Check")
    elseif num == 3 then
        menu.notify("Invalid IP Address", "VPN/Proxy Check", 4)
    elseif num == 4 then
        if var == 1 then
            menu.notify("Reached maximum limit for today", "VPN/Proxy Check", 4)
        else
            menu.notify("Reached maximum limit of requests in a minute", "VPN/Proxy Check", 4)
        end
    end
end