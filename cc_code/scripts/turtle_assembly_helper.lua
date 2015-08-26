--fname:tfeed
--version:1.01
--type:script
--name:turtle craft helper
--description:helps in the use of advanced crafting tables

print("how many stacks to move?")
a=read()

turtle.select(1)
for i=1,tonumber(a) do
    turtle.suckUp()
    if turtle.getItemSpace(1) == 0 then
        turtle.dropDown()
    else
        print("not full stack detected! abort!")
        return
    end
end
