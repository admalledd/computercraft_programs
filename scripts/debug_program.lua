--fname:debug
--version:1.01
--type:script
--name:debugger
--description:downloads latest and runs

fname="getprog"
prog="getprog_beta.lua"

url="http://127.0.0.1:8082/loader.py?/"..prog

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
shell.run(fname)