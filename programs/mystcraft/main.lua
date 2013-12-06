

--[[
main controller for the DHD turtle part of the mystcraft gate control network

]]


ME=peripheral.wrap("bottom") --a ME access terminal (openperipheral)
monitor=peripheral.wrap("top") --an advanced monitor, size 6x5
receptical=peripheral.wrap("left") --the place we put the mystcraft linking books!


print(receptical.listMethods())