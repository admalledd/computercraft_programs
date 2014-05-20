import fs.osfs
import sys

template='''
  ["{fname}"]={{
    ["GitURL"]="{url}",
    ["Version"]={version},
    ["Type"]="{type}",
    ["Name"]="{name}",
    ["Description"]="{description}",
  }},'''

if len(sys.argv) > 1:
    debug = False
else:
    debug = True
if debug:
    urlbase = "http://home.admalledd.com:8082/loader.py?"
else:
    urlbase = "https://raw.github.com/admalledd/computercraft_programs/master"
print "urlbase:::%s"%urlbase
format_vars=('fname','version','type','name','description')

progs = []
project_base = fs.osfs.OSFS('../')
for path in project_base.walkfiles(wildcard="*.getprog.lua"):
    if path == '/getprog.lua': continue
    print "parsing '%s' ..."%path
    with project_base.open(path,'r') as f:
        prog_meta={}
        line = f.readline().strip()
        while line.startswith('--'):
            tag=line[2:].split(':')
            if tag[0] in format_vars and tag[1]!='' and len(tag)==2:
                prog_meta[tag[0]]=tag[1]
            line=f.readline().strip()
        if len(prog_meta)==5:
            prog_meta['url']=urlbase+path
            progs.append(prog_meta)
        else:
            print "invalid .lua script for automatic inclusion: %s"%path

prog_list = []
for p in progs:
    prog_list.append(template.format(**p))

with project_base.open("programlist.ltable",'w') as f:
    f.write('''{\n%s\n}'''%''.join(prog_list))
