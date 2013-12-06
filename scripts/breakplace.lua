--fname:breakplace
--version:1.01
--type:script
--name:Breaker Placer
--description:For Quarry plus breakers/placer automation


while true do
    rs.setOutput("left",true)
    rs.setOutput("right",false)
    os.sleep(0.001)--sleep as little as possible?
    rs.setOutput("left",false)
    rs.setOutput("right",true)
    os.sleep(0.001)
end