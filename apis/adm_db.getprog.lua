--fname:database
--version:1.01
--type:api
--name:database API
--description: simple database API, WIP


function load(dbname)
  -- dbname is actually a filename under /db/$fname
  -- the file is just a simple serialized table and such
  if not fs.exists('/db/'..dbname) then
    local f=fs.open('/db/'..dbname,'w')
    f.write('{}')
    f.close()
  end
  local f=fs.open('/db/'..dbname,'r')
  local data = f.readAll()
  f.close()
  return textutils.unserialize(data)
end

function save(tbl,dbname)
  -- dbname is actually a filename under /db/$fname
  -- the file is just a simple serialized table and such

  local data = textutils.serialize(tbl)
  local f= fs.open('/db/'..dbname,'r')
  f.write(data)
  f.close()
end
