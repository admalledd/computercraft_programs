--fname:getprog2
--version:1.01
--type:program
--name:getprogram
--description: Main getprogram code, autoupdates


if not http then
  print("Herp derp, forget to enable http?")
  return exit
end

--CONSTANTS: (change here if you want to make your own getprog tool chain...)

--S_LOC: root URI for where to find getprog compatible files
S_LOC="https://raw.github.com/admalledd/computercraft_programs/master/"
--V_LOC: name of the version file (concat'd to S_LOC)
V_LOC="getprog.version"
--P_LOC: name of the program file itself (concat'd to S_LOC)
P_LOC="getprog2.lua"
--P_DISK: computer-craft name of the program (should be simple and easy to type!)
P_DISK="getprog" 



function should_update()
    --[[
    return true if "update" required
    checks for what the current version on disk is (if not found, return "true")
    calls to the github version file
    compares dirtily via == that they match, if not return "true" (any non-match means update required)
    ]]
    print("checking for update...")
    local v_remote = get_url_file(S_LOC..V_LOC)
    local v_local  = os.open(V_LOC,"r")
    if v_local == nil then
        return true --no local version file, time to check for an update!
    end
    v_local = v_local.readAll()
    if v_local == v_remote then
        return false
    else
        return true
    end
end

function get_url_file(url)
    local mrHttpFile = http.get(url)
    mrHttpFile = mrHttpFile.readAll()
    return mrHttpFile
end

function write_file(fname,data)
    -- simply write out a file.
    local f = os.open(fname,"w")
    f.write(data)
    f.close()
end


if should_update() then
    print("out of date getprog, downloading the new one now...")
    write_file(P_DISK,get_url_file(S_LOC..P_LOC))
end