--fname:getprog2
--version:1.01
--type:program
--name:getprogram
--description: Main getprogram code, autoupdates


--[[
get https://raw.github.com/admalledd/computercraft_programs/master/getprog.version

just a plain text file that can be tonumber()'d


]]
if not http then
  print("Herp derp, forget to enable http?")
  return exit
end

version = 2.5

print("checking for update...")
cur_ver= http.get("https://raw.github.com/admalledd/computercraft_programs/master/getprog.version")
if cur_ver ~= nil then
    --get was good
    cur_ver = tonumber(cur_ver.readAll())
    if cur_ver > version then
        print("update available...")
        local data = http.get("https://raw.github.com/admalledd/computercraft_programs/master/getprog.lua").readAll()
        local f = fs.open("getprog","w")
        f.write(data)
        f.close()
        shell.run("getprog")
        return exit
    end
else
    print("error checking for update, ignored.")
