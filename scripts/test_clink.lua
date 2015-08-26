--fname:test_clink
--version:1.01
--type:program
--name:CLink Test app
--description: Some basic testing of CLink


url = "http://localhost:8082/clinker.py?user=admalledd"

file_url = url .. "&req=get_file&file="

puts_url = url .. "&req=puts"


data = {}
data.foo = "123"
data["sub"] = {["key"]="value"}

http.post(puts_url,textutils.serialize(data))
