import re
import os

thisdir = os.getcwd()+'/input'

for r, d, f in os.walk(thisdir):
    for file in f:
        if ".prw" in file.lower():
            fileName = os.path.join(r, file)
            print(fileName)
            file = open(fileName, 'r', encoding='windows-1252')

            fl = file.readlines()

            groups = []
            newGroup = []
            for line in fl:
                if 'function' in line.lower():
                    groups.append(newGroup)
                    newGroup = []
                    newGroup.append(line)
                else:
                    newGroup.append(line)

            for group in groups:
                textGroup = ''.join(group)
                for line in group:
                    match = re.search(r'(?<=for\s)\w*(?=\s*:=)', line.lower())
                    if match:
                        if not re.search(fr'(?<=local\s){match[0]}', textGroup.lower()):
                            group[0] += 'local '+match[0]+'\n'
            
            finalFile = ''.join(''.join(group) for group in groups)

            final = open(fileName.replace('/input/', '/output/'), 'w+', encoding='windows-1252')
            final.write(finalFile)
    