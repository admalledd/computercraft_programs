--fname:debug
--version:1.01
--type:script
--name:debugger
--description:downloads latest and runs

fname="test_ae2"
prog="/scripts/test_ae2.lua"

url="http://localhost:8082/clinker.py?user=admalledd&req=get_file&file="..prog

function getUrlFile(url)
  local mrHttpFile = http.get(url)
  mrHttpFile = mrHttpFile.readAll()
  return mrHttpFile
end
function writeFile(filename, data)
  local file = fs.open(filename, "w")
  file.write(data)
  file.close()
end
print("getting latest of: "..prog)
writeFile(fname,getUrlFile(url))
print("saved as: "..fname)
--shell.run(fname.." install ".."http://home.admalledd.com:8082/loader.py?/programlist.ltable")
shell.run(fname)