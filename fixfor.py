import re
import os

inputDir = os.getcwd()+'/input'

if 'output' not in os.listdir('.'):
    os.mkdir('output')

for r, d, f in os.walk(inputDir):
    for file in f:
        if ".prw" in file.lower():
            fileName = os.path.join(r, file)
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
            groups.append(newGroup)
            
            for group in groups:
                textGroup = ''.join(group)
                for line in group:
                    match = re.search(r'(?<=for\s)\w*(?=\s*:=)', line.lower())
                    if match:
                        if not re.search(fr'(?<=local\s){match[0]}', textGroup.lower()):
                            group[0] += 'local '+match[0]+'\n'
    
            finalText = ''.join(''.join(group) for group in groups)
            
            #Cria a estrutura de pastas na pasta output, similar à input
            outputSimilar = r.replace('/input/', '/output/')
            if not os.path.exists(outputSimilar):
                os.makedirs(outputSimilar)

            #Abre o arquivo de output
            final = open(fileName.replace('/input/', '/output/'), 'w+', encoding='windows-1252')
            
            #Escreve o fonte
            final.write(finalText)
