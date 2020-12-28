local module = {}

--TODO: some helper "get file, upload file, etc"

local settings = require("settings")

module.get_text = function(file)
    local h_req = http.get(settings.url_base.."GetFile/GetFile?fname=swarm/"..file)
    local h_txt = h_req.readAll()
    return h_txt
end
module.save_file = function(webPath, fileName)
    if fileName == nil then fileName = webPath end
    local f_text = get_text(webPath)
    local f_file = fs.open(fileName, 'w')
    f_file.write(f_text)
    f_file.close()
    return f_text --in case we want text in-place too, can be handy
end