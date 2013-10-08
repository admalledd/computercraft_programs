--fname:meter
--version:1.03
--type:program
--name:EUmeter
--description:display EU usage

meter = peripheral.wrap("right")

meter.stop()
os.sleep(0.1)
meter.start()
meter.startTime=os.clock()
meter.lastTotal=0

modem = peripheral.wrap("bottom")
modem.open(513)

function timedGet()
    meter.stop()
    os.sleep(0.25)
    
    local starttime=os.clock()
    meter.start()
    e,msg = os.pullEvent("energy_measure")
    local dtime = os.clock() - starttime
    local eut = msg.total/(dtime*40)
    if msg.pass <1 then
        eut = 0--fix underflow?
    end
    return eut
end

while true do
    eut=timedGet()
    print(eut)
    modem.transmit(512,513,"EUT:1:"..tostring(eut))
end

