#include "protheus.ch"

user function test()
    // Variavel do For não declarada incialmente
    
    aNumbers = [1, 2, 3, 4]

    for nx := 1 to len(aNumbers)
        conout(aNumbers[nx])
    next nx
return()