#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"   
#include "totvs.ch"   
#INCLUDE "MSOBJECT.CH"

#DEFINE ENTER CHR(13)+CHR(10)

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  JOBMPED1   � Autor � Lucas Pereira	     � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � Integra��o For�a de vendas Meus Pedidos - Cadastros        ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
User Function JOBMPED1(cEmp,cFil)
Local nVolta := 0 
PRIVATE cCodEmp := iif(empty(cEmp),'02',cEmp)
PRIVATE cFilPar:= iif(empty(cFil),'0101',cFil)
PRIVATE aContas := {}

Private	cNomeArq	:= "JOBMPED1-"+DTOS( DATE() )+"-"+STRTRAN(TIME(),':','-')

//PREPARE ENVIRONMENT EMPRESA cCodEmp FILIAL cFilPar 
RpcClearEnv()
RpcSetType(3)
RpcSetEnv (cCodEmp,cFilPar)

While !KillApp()
    nVolta++  
    If nVolta > 60
        volta:=0  
        
        
 		U_ParLog1(cNomeArq, "#####################################################################################################" )   
 		U_ParLog1(cNomeArq, "#                        INTEGRACAO MEUS PEDIDOS - PARTNERS RL SOLUCOES  	                    #" )              
		U_ParLog1(cNomeArq, "#####################################################################################################" ) 
		
		//MONTA ARRAY COM CONFIGURA��O DE CONTAS
		U_MtaVetCta()
		//SE NAO EXISTE CONTA CONFIGURADA RETORNA
		IF EMPTY(aContas)             
			U_ParLog1(cNomeArq, "#####################################################################################################" )            
		    U_ParLog1(cNomeArq, "####################        NENHUMA CONTA CONFIGURADA TABELA - MP0	              ###############" )  
		    U_ParLog1(cNomeArq, "#####################################################################################################" )  
		    U_ParLog1(cNomeArq, "" ) 
			RETURN()
		ENDIF
			
		
		U_ParLog1(cNomeArq, "" )      
		U_ParLog1(cNomeArq, "#####################################################################################################" )          
	    U_ParLog1(cNomeArq, "#                           SINCRONIACAO DE ENTIDADES INICIADA - MP0	                            #" )  
	    U_ParLog1(cNomeArq, "#####################################################################################################" )  
	    U_ParLog1(cNomeArq, "" ) 
	    SincEntidades()
	    
 		U_ParLog1(cNomeArq, "#####################################################################################################" )          
	    U_ParLog1(cNomeArq, "#                           SINCRONIACAO JSON MEUS PEDIDOS     - MP1	                            #" )  
	    U_ParLog1(cNomeArq, "#####################################################################################################" )  
	    U_ParLog1(cNomeArq, "" ) 
	    MpJsonEnv()

 		U_ParLog1(cNomeArq, "#####################################################################################################" )          
	    U_ParLog1(cNomeArq, "#                                        FIM DO PROCESSAMENTO                                    #" )  
	    U_ParLog1(cNomeArq, "#####################################################################################################" )  
	    U_ParLog1(cNomeArq, "" ) 	     	
		Exit		
	endif
Enddo

return()    



/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  JOBMPED1   � Autor � Lucas Pereira	     � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � Integra��o For�a de vendas Meus Pedidos - Cadastros        ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
static Function SincEntidades()
local teste
local cTabela	:= GetNextAlias()
local nz

	for teste := 1 to len(aContas)

	next teste
	
	FOR nz:=1 TO LEN(aContas)
	
		//PREPARE ENVIRONMENT EMPRESA cCodEmp FILIAL aContas[nz,1]  
		RpcClearEnv()
		RpcSetType(3)
		RpcSetEnv (cCodEmp,cFilPar)

		U_ParLog1(cNomeArq, "#####################################################################################################" )            
		U_ParLog1(cNomeArq, "                                  PORCESSANDO CONTA "+alltrim(aContas[nz,3]) )
	    U_ParLog1(cNomeArq, "#####################################################################################################" )
	    U_ParLog1(cNomeArq, "" ) 
	
		//VERIFICA LICENCIAMENTO DA CONTA NO SERVIDOR PARTNERSRL
		//*****************************************************************************
	    IF U_LicenciaMP(aContas[nz,1],aContas[nz,2],nz)
	    	return()
	    ENDIF
		//*****************************************************************************	
	

		//VENDEDORES
		//*****************************************************************************
		  SincVendedor(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************
		
		//SEGMENTOS DE CLIENTES
		//*****************************************************************************
		  SincSegClient(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************
		
		//CLIENTES
		//*****************************************************************************
		  SincClientes(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************
		
		 
		 //GRUPOS DE PRODUTOS
		//*****************************************************************************
		if aContas[nz,24] = 'S'
			SincCatProd(aContas[nz,1],aContas[nz,2],nz)
		ENDIF
		//*****************************************************************************		

		//PRODUTOS ESPECIFICOS
		//*****************************************************************************
		  IF aContas[nz,22] = 'S'
		  	SincProdEsp(aContas[nz,1],aContas[nz,2],nz)
		  ENDIF
		//*****************************************************************************	

		//PRODUTOS
		//*****************************************************************************
		  SincProduto(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************		

		//ESTOQUE
		IF aContas[nz,25] = 'S'
		//*****************************************************************************
		  SincEstoque(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************		
		ENDIF
		
		//TRANSPORTADORAS
		IF aContas[nz,28] = 'S'
		//*****************************************************************************
		  SincTransp(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************
		ENDIF
		//CABECALHO DE TABELAS DE PRECO
		//*****************************************************************************
		  SincCabTab(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************		

		//ITENS DE TABELAS DE PRECO
		//*****************************************************************************
		  SincItemTab(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************		

		//CONDCAO DE PAGAMENTO
		IF aContas[nz,29] = 'S'
		//*****************************************************************************
		  SincCondPag(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************		
		ENDIF
		
		//CLIENTE X TABELA
		//*****************************************************************************
		  SincTabCli(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************	
			
		//FORMAS DE PAGAMENTO
		//*****************************************************************************
		  SincFormPg(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************			

		//CLIENTE X CONDPAG
		IF aContas[nz,29] = 'S'
		//*****************************************************************************
		  SincCondCli(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************	
		ENDIF
		
		//CONFIGURA��O ST
		//*****************************************************************************
		  SincConfSt(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************	
		
		
		//FATURAMENTO
		//*****************************************************************************
		  SincFaturados(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************	

		//TITULOS INADIMPLENTES
		//*****************************************************************************
		  if aContas[nz,21] = 'S'
		  	SincTitulos(aContas[nz,1],aContas[nz,2],nz)
		  endif
		//*****************************************************************************	
						
		//TIPOS DE PEDIDOS
		//*****************************************************************************
		  SincTipoPed(aContas[nz,1],aContas[nz,2],nz)
		//*****************************************************************************	
				
			
 		U_ParLog1(cNomeArq, "#####################################################################################################" )          
	    U_ParLog1(cNomeArq, "                      FIM DO PROCESSAMENTO  CONTA "+alltrim(aContas[nz,3]) )  
	    U_ParLog1(cNomeArq, "#####################################################################################################" )  
	    U_ParLog1(cNomeArq, "" ) 	
	next nz
return()



/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincVendedor(cFilMp,cCtaMp,nz)
local x
local oJson ,oRestMp , cUrl ,cPatch ,aHeader ,cAppTk, cCmpTk ,cVend, cIdVend ,cJson , x, nz
local aResult   := {} 
local cFilComp  := FWModeAccess("SA3",3)
local cFilEnt	:= iif(cFilComp=='E',cFilMp,XFILIAL("SA3")) 

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                     USUARIOS x VENDEDORES                                           "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )   


	cUrl	:= alltrim(aContas[nz,4])
	cAppTk	:= alltrim(aContas[nz,5])
	cCmpTk	:= alltrim(aContas[nz,6])

	oRestMp := FWRest():New(cUrl) 
	cPatch  := "/api/v1/usuarios/"
	aHeader	:= {"Accept: application/json","Content-Type: application/json","ApplicationToken: "+cAppTk,"CompanyToken: "+cCmpTk}	 

	
	oRestMp:setPath(cPatch) 
	 
	If !oRestMp:GET(aHeader) 
		if empty(oRestMp:CINTERNALERROR) 
			U_ParLog1(cNomeArq,"GET", oRestMp:GetLastError()) 
	    else
	      	U_ParLog1(cNomeArq,"GET", oRestMp:CINTERNALERROR) 
	    endif	   
	else	        
	   aResult := U_Deserialize(oRestMp:GetResult())  
	 
		//U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" "+cvaltochar(len(aResult))+" Usuarios Encontrados...")
		//U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Sincronizando ID...")
		
		for x:=1 to len(aResult)
			if !aResult[x]:ADMINISTRADOR       
				IF !aResult[x]:EXCLUIDO
			 		beginsql alias "TMP"
			 		 	SELECT A3_COD FROM %TABLE:SA3%
			 		 	WHERE %NOTDEL% 
			 		 	AND A3_MSBLQL <> '1'
			 		 	AND A3_EMAIL  = %EXP:ALLTRIM(aResult[x]:EMAIL)%
			 		 	AND A3_FILIAL = %EXP:xfilial("SA3")%	
				    endsql 
				    IF !EMPTY(TMP->A3_COD)
				    	cVend	:= TMP->A3_COD
				    	cIdVend	:= CVALTOCHAR(aResult[x]:ID)
				    
				    	if !MP1->(DBSEEK(cFilMp+cCtaMp+PADR("VEND",10)+cVend))
				    		RECLOCK('MP1',.T.)
								MP1_FILIAL	:= aContas[nz,1]
								MP1_CTAMP	:= aContas[nz,2]
								MP1_TPREG	:= "VEND"
								MP1_IDPROT	:= cVend
								MP1_IDMP	:= cIdVend
								MP1_DTINTE  := DATE()
								MP1_STATUS	:= 'I'
								MP1_JSON	:= cJson
							MSUNLOCK()
							
							
							BEGINSQL ALIAS 	"SQL"
								SELECT * 
								FROM %TABLE:MP1% MP1,
									 %TABLE:SA1% SA1
									 
								WHERE SA1.D_E_L_E_T_ <> '*'
								AND A1_VEND = %EXP:cVend%
								
								AND MP1.D_E_L_E_T_ <> '*'
								AND MP1_FILIAL = %EXP:cFilMp%
								AND MP1_CTAMP = %EXP:cCtaMp%
								AND MP1_TPREG = 'CLI_VEND'
								AND MP1_IDPROT = A1_COD+A1_LOJA
							ENDSQL
							WHILE SQL->(!EOF())
								cCliId 	:=  U_GetIdEnt(cFilMp,cCtaMp,"CLIENTE",SQL->(A1_COD+A1_LOJA))
							   
						    	cJson := '{'
								cJson += '    "cliente_id": '+cCliId+','
								cJson += '     "usuario_id": '+cIdVend+','
								cJson += '     "liberado": true'
								cJson += '}'  	            
						    	U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"CLI_VEND",SQL->(A1_COD+A1_LOJA),cJson) 
						    	U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Cliente "+SQL->(A1_COD+A1_LOJA)+ " atualizado." ) 
						    	SQL->(DBSKIP())
					    	ENDDO
					    	SQL->(DBCLOSEAREA())
				    	ENDIF
				  	ENDIF 
					TMP->(DBCLOSEAREA())
				ENDIF		
		    ENDIF
		next x    
	EndIf  

U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Sincronizando ID Finalizada")

return()
 
  /*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  SincCatProd   � Autor � Lucas Pereira   � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � novos Produtos incluidos no ERP                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincSegClient(cFilMp,cCtaMp,nz)
local x
local aItens 	:= {}
local cFilComp  := FWModeAccess("AOV",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("AOV")) 

local cWherePTE := '%'
	If ExistBlock("MP_SEGCFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_SEGCFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                        SEGMENTOS CLIENTES                                                "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	

	If !ExistBlock("MP_SEGCSQL")
		BEGINSQL alias "TMP"
			SELECT 
				AOV_CODSEG,
				AOV_DESSEG,
				D_E_L_E_T_  AS del,
				R_E_C_N_O_ AS REC
				
			FROM %table:AOV%
			WHERE D_E_L_E_T_ + AOV_XMPTRA <> '* 'AND
			 	AOV_FILIAL = %exp:cFilEnt% AND 
			 	(AOV_XMPTRA <> 'I' OR
					NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
								MP1.MP1_FILIAL = %EXP:cFilMp% AND
								MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
								MP1.MP1_IDPROT = AOV_CODSEG AND 
								MP1.MP1_TPREG = 'SEGMENTOS' AND 
								MP1.D_E_L_E_T_ <> '*'))		
			%EXP:cWherePTE%	
		ENDSQL                 
	
		while TMP->(!eof())
			aadd(aItens,{  	TMP->AOV_CODSEG ,;
							alltrim(TMP->AOV_DESSEG),;
							iif(!empty(TMP->del),"true","false") ,;
							TMP->REC })
		TMP->(DBSKIP())                                                    
		ENDDO 
		TMP->(DBCLOSEAREA())      

	ELSE
		aItens := ExecBlock("MP_SEGCSQL",.F.,.F.,{aContas,cFilMp,cCtaMp,nz})
	ENDIF 	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." ) 
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrado "+cvaltochar(len(aItens))+"  Segmentos de Clientes  ..." )    
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '  "nome": "'+aItens[x,2]+'",'
		cJson += '  "excluido": '+aItens[x,3]
		cJson += '}'
			     
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
	   	
	   		If !ExistBlock("MP_SEGCGRV")
				DBSELECTAREA("AOV")  
				SET DELETED OFF
				DBGOTO(aItens[x,4])
		   		reclock("AOV",.F.)
		   			AOV->AOV_XMPTRA := 'X'
		   		msunlock()
	   		ELSE
	   			ExecBlock("MP_SEGCGRV",.F.,.F.,{aContas,cFilMp,cCtaMp,nz,aItens[x,4]})
	   		ENDIF
		   	
	   	endif
	   	
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"SEGMENTOS",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Segmento "+aItens[x,1]+ " atualizado." )  
	NEXT X

return()          
 
  
  
 
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCliERP  � Autor � Lucas Pereira    � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � novos Clientes incluidos no ERP                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincClientes(cFilMp,cCtaMp,nz)
local x
local aItens 	:= {}
local cFilComp  := FWModeAccess("SA1",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("SA1")) 
local cCliId ,cIdVend ,cJson, cCndId, cInTpReg, cTabId, cIdSegm

local cWherePTE := '%'
	If ExistBlock("MP_CLIEFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_CLIEFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'		


cInTpReg := '%('
cInTpReg += " 'CLI_VEND','CLI_TAB','CLIENTE' "
if aContas[nz,29] = 'S'
	cInTpReg += " , 'CLI_COND' "
endif
cInTpReg += ')%'
	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                            CLIENTES                                                "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  

		BEGINSQL alias "TMP"
			SELECT	A1_NOME,
					A1_NREDUZ,
					A1_PESSOA,
					A1_CGC,
					A1_INSCR,
					A1_SUFRAMA,
					A1_END,
					A1_COMPLEM,
					A1_BAIRRO,
					A1_CEP,
					A1_MUN,
					A1_EST,
					A1_OBSERV,
					A1_EMAIL,
					A1_TEL,   
					A1_DDD,
					A1_TELEX, 
					A1_VEND,
					
					A1_LC,
					A1_SALDUP,
					A1_SALPEDL,
					A1_SATIV1,
					A1_REGIAO,
					A1_COND,
					A1_GRPTRIB,
					A1_MSBLQL,
					A1_TABELA,
					A1_COND,
					A1_CODSEG,
					
					D_E_L_E_T_ as del,
					A1_COD+A1_LOJA AS A1_COD,
					R_E_C_N_O_ AS REC
					 
			FROM %table:SA1% 
			WHERE D_E_L_E_T_ + A1_XMPTRAN <> '* ' and 
				A1_FILIAL = %EXP:cFilEnt% AND
				(A1_XMPTRAN <> 'I' OR
				NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
							MP1.MP1_FILIAL = %EXP:cFilMp% AND
							MP1.MP1_CTAMP = %EXP:cCtaMp%  AND 
							MP1.MP1_IDPROT = A1_COD+A1_LOJA AND 
							MP1.MP1_TPREG IN %EXP:cInTpReg% AND 
							MP1.D_E_L_E_T_ <> '*'))
							
			%EXP:cWherePTE%				
		ENDSQL                  
		
		
		while TMP->(!eof())  
			cCondPag := POSICIONE("SE4",1,XFILIAL("SE4")+TMP->A1_COND,"E4_DESCRI") 
			cRegiao	 := TMP->A1_REGIAO
			cRamo	 := POSICIONE("SX5",1,XFILIAL("SX5")+"T3"+TMP->A1_SATIV1,"X5_DESCRI")      
			nSldCred := TMP->A1_LC - (TMP->A1_SALDUP + TMP->A1_SALPEDL)     
			
			cObersv	 := "Regiao\t\t\t\t: "+alltrim(cRegiao)+"\n"
			cObersv	 += "Cond Pag\t\t\t: "+alltrim(cCondPag)+"\n" +"\n" 
			cObersv	 += "Ramo Atv\t\t\t: "+alltrim(cRamo)+"\n" +"\n"
			
			cObersv	 += "Lim Credi\t\t\t: "+"R$ "+alltrim(transform(TMP->A1_LC,"@E 999,999,999,999.99"))+"\n"	
			cObersv	 += "Sld Credi\t\t\t: "+"R$ "+alltrim(transform(nSldCred,"@E 999,999,999,999.99")) +"\n"	
			cObersv	 += "Observ\t\t\t\t: "+TMP->A1_OBSERV
			
			If ExistBlock("MP_CLIEFIL")
				cObersv := ExecBlock("MP_CLIOBSE",.F.,.F.,{cObersv,TMP->A1_COD})
			EndIf
				
			aadd(aItens,{   alltrim(TMP->A1_NOME),;     	  					// 1
							alltrim(TMP->A1_NREDUZ),;    						// 2
							alltrim(TMP->A1_PESSOA),;       					// 3
							alltrim(TMP->A1_CGC),;     							// 4
							alltrim(TMP->A1_INSCR),;   							// 5
							alltrim(TMP->A1_SUFRAMA),;    					 	// 6
							alltrim(TMP->A1_END),; 	  							// 7
							alltrim(TMP->A1_COMPLEM),;    						// 8
							alltrim(TMP->A1_BAIRRO),;   						// 9
							alltrim(TMP->A1_CEP),; 	   							// 10
							alltrim(TMP->A1_MUN),; 	  	 						// 11
							IIF(TMP->A1_EST=='EX','',TMP->A1_EST),;     	 	// 12
							alltrim(cObersv),;    	 							// 13
		  					strtran(strtran(alltrim(TMP->A1_EMAIL),"	","")," ",""),;		// 14
							alltrim(TMP->(A1_DDD+" "+A1_TEL)),;     	  		// 15
							alltrim(TMP->(A1_DDD+" "+A1_TELEX)),;     	   		// 16
							iif(!empty(TMP->del).or.TMP->A1_MSBLQL == '1',"true","false"),;     			// 17  
							TMP->A1_COD,;                              			// 18
							TMP->A1_VEND,;										// 19
							TMP->REC,;											// 20
							TMP->A1_GRPTRIB,;									// 21
							TMP->A1_MSBLQL,;									// 22
							TMP->A1_TABELA,;									// 23
							TMP->A1_COND,;										// 24
							TMP->A1_CODSEG})									// 25
		TMP->(DBSKIP())                                                    
		ENDDO 
		TMP->(DBCLOSEAREA())      
		
		if empty(aItens)   
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." ) 
			return()
		else
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrado "+cvaltochar(len(aItens))+" Clientes ..." )   
		endif
		
		FOR X:=1 TO LEN(aItens)  
		
		 	cIdSegm := U_GetIdEnt(cFilMp,cCtaMp,"SEGMENTOS",aItens[x,25])
				
			cJson := '{'
			cJson += '    "razao_social": "'+aItens[x,1]+'",'
			cJson += '    "nome_fantasia": "'+aItens[x,2]+'",'
			cJson += '    "tipo": "'+aItens[x,3]+'",'
			cJson += '    "cnpj": "'+aItens[x,4]+'",'
			cJson += '    "inscricao_estadual": "'+aItens[x,5]+'",'
			cJson += '    "suframa": "'+aItens[x,6]+'",'
			cJson += '    "rua": "'+aItens[x,7]+'",'
			cJson += '    "complemento": "'+aItens[x,8]+'",'
			cJson += '    "bairro": "'+aItens[x,9]+'",'
			cJson += '    "cep": "'+iif(len(aItens[x,10])<> 8 , "99999999",strtran(aItens[x,10],"-","0"))+'",'
			cJson += '    "cidade": "'+aItens[x,11]+'",'
			cJson += '    "estado": "'+aItens[x,12]+'",'
			if ! empty(cIdSegm)
				cJson += '    "segmento_id": '+cIdSegm +','
			endif
			cJson += '    "observacao": "'+aItens[x,13]+'",'
			cJson += '    "emails": [ '
			cJson += '        { '
			cJson += '            "email": "'+iif(aItens[x,14]=='@'  .or. at("@",aItens[x,14]) == 0,'email@email.com',iif(  at(";",aItens[x,14])>0 .or.at("/",aItens[x,14])>0  , substr(aItens[x,14],1,at(";",aItens[x,14])-1) ,aItens[x,14]    ) )+'" '
			cJson += '        }'
			cJson += '    ],'
			cJson += '    "telefones": ['
			cJson += '        { '
			cJson += '            "numero": "'+iif(empty(aItens[x,15]),"99999999",aItens[x,15])+'"'
			cJson += '        },'
		 	cJson += '       { '
		 	cJson += '           "numero": "'+iif(empty(aItens[x,16]),"99999999",aItens[x,15])+'"  '
			cJson += '        }'
			cJson += '    ],'
			cJson += '    "nome_excecao_fiscal": '+ iif(Empty(aItens[x,21]),"null,",'"'+aItens[x,21]+'",')     
			cJson += '    "excluido":  '+aItens[x,17]
			cJson += '}'
		   	
		   	If ExistBlock("MP_CLIJSON")
				cJson := ExecBlock("MP_CLIJSON",.F.,.F.,{aContas,cFilMp,cCtaMp,nz,aItens[x]})
			endif
		   	
		   	
		   	IF len(aContas) == nz .OR.;
		   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')
		   	
				DBSELECTAREA("SA1")  
				SET DELETED OFF
				DBGOTO(aItens[x,20])
		   		reclock("SA1",.F.)
		   			SA1->A1_XMPTRAN := 'X'
		   		msunlock()
			   	
		   	
		   	endif
			
			U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"CLIENTE",aItens[x,18],cJson, "","","","","",iif(aItens[x,13]=='1',.t.,.f.))
			
			cIdVend	:=  U_GetIdEnt(cFilMp,cCtaMp,"VEND",aItens[X,19])		
			cCliId 	:=  U_GetIdEnt(cFilMp,cCtaMp,"CLIENTE",aItens[X,18])
			cCndId 	:=  U_GetIdEnt(cFilMp,cCtaMp,"COND_PAG",aItens[X,24])
			cTabId 	:=  U_GetIdEnt(cFilMp,cCtaMp,"TABPR_CAB",aItens[X,23])   
			
			If ExistBlock("MP_MULTV")
				DBSELECTAREA('MPG')
				DBSETORDER(1)
				ExecBlock("MP_MULTV",.F.,.F.,{aContas,cFilEnt,aItens[X,18],aItens[X,19]})
				MPG->(DBCLOSEAREA())
			EndIf	
			
			/******************************************************/
			/*				GRAVA CARTEIRA DE VENDEDORES MP1       *
			/******************************************************/	

			IF !EMPTY(cCliId) .AND. !EMPTY(cIdVend)
		    	cJson := '{'
				cJson += '    "cliente_id": '+cCliId+','
				cJson += '     "usuario_id": '+cIdVend+','
				cJson += '     "liberado": true'
				cJson += '}'  	            
		    	U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"CLI_VEND",aItens[x,18],cJson) 
	    	ENDIF
	    	
			/******************************************************/
			/*				GRAVA TABELAS DE PRECOS MP1  MP4      *
			/******************************************************/	   	
	    	
	    	IF !EMPTY(cCliId) 
		    	if !MPA->(dbseek(cFilMp+aItens[x,18]))
				    cJson := '{'
					cJson += '   "cliente_id": '+cCliId+','
					cJson += '   "tabelas_liberadas": '+IIF(!EMPTY(cTabId), "["+cTabId +"]",'[0]')
					cJson += '}'
					
					U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"CLI_TAB",aItens[x,18],cJson) 
				endif
			ENDIF
			/******************************************************/
			/*				GRAVA CONDICAO PAGAMETNO MP1      *
			/******************************************************/	   	
  	
			IF aContas[nz,29] = 'S'
				IF !EMPTY(cCliId) .AND. !EMPTY(cCndId)
			    	if !MPB->(dbseek(cFilMp+aItens[x,18])) 
			    		
						cJson := '{'
						cJson += '   "cliente_id": '+cCliId+','
						cJson += '   "condicoes_pagamento_liberadas":  '+IIF(!EMPTY(cCndId), "["+cCndId +"]",'[0]') 
						cJson += '}'
				
						U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"CLI_COND",aItens[x,18],cJson) 
					endif
				ENDIF
			endif
			
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Cliente "+aItens[x,18]+ " atualizado." )  
		NEXT X   

return()   

 
 
 /*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  SincCatProd   � Autor � Lucas Pereira   � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � novos Produtos incluidos no ERP                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincCatProd(cFilMp,cCtaMp,nz)
local x
local aItens 	:= {}
local cFilComp  := FWModeAccess("SBM",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("SBM")) 

local cWherePTE := '%'
	If ExistBlock("MP_GRUPFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_GRUPFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                        GRUPOS DE PRODUTOS                                                "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	

	If !ExistBlock("MP_GRUPSQL")
		BEGINSQL alias "TMP"
			SELECT 
				BM_GRUPO,
				BM_DESC,
				D_E_L_E_T_  AS del,
				R_E_C_N_O_ AS REC
				
			FROM %table:SBM%
			WHERE D_E_L_E_T_ + BM_XMPTRAN <> '* 'AND
			 	BM_FILIAL = %exp:cFilEnt% AND 
			 	(BM_XMPTRAN <> 'I' OR
					NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
								MP1.MP1_FILIAL = %EXP:cFilMp% AND
								MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
								MP1.MP1_IDPROT = BM_GRUPO AND 
								MP1.MP1_TPREG = 'GRUPO' AND 
								MP1.D_E_L_E_T_ <> '*'))		
			%EXP:cWherePTE%	
		ENDSQL                 
	
		while TMP->(!eof())
			aadd(aItens,{  	TMP->BM_GRUPO ,;
							alltrim(TMP->BM_DESC),;
							iif(!empty(TMP->del),"true","false") ,;
							TMP->REC })
		TMP->(DBSKIP())                                                    
		ENDDO 
		TMP->(DBCLOSEAREA())      

	ELSE
		aItens := ExecBlock("MP_GRUPSQL",.F.,.F.,{aContas,cFilMp,cCtaMp,nz})
	ENDIF 	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." ) 
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrado "+cvaltochar(len(aItens))+"  Categoria de Produtos  ..." )    
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '  "nome": "'+aItens[x,2]+'",'
		cJson += '  "excluido": '+aItens[x,3]
		cJson += '}'
			     
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
	   	
	   		If !ExistBlock("MP_GRUPGRV")
				DBSELECTAREA("SBM")  
				SET DELETED OFF
				DBGOTO(aItens[x,4])
		   		reclock("SBM",.F.)
		   			SBM->BM_XMPTRAN := 'X'
		   		msunlock()
	   		ELSE
	   			ExecBlock("MP_GRUPGRV",.F.,.F.,{aContas,cFilMp,cCtaMp,nz,aItens[x,4]})
	   		ENDIF
		   	
	   	endif
	   	
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"GRUPO",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Grupo "+aItens[x,1]+ " atualizado." )  
	NEXT X

return()          
 
  
  
 /*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  SincProduto   � Autor � Lucas Pereira   � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � novos Produtos incluidos no ERP                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/  
  
static function SincProduto(cFilMp,cCtaMp,nz)
local x
	local aItens 	:= {}
	local cTabPad 	:= aContas[nz,14]
	local cTpProd 	:= "%('" + STRTRAN(alltrim(aContas[nz,11]),';',"','" ) + "')%"    
	local cLocPad 	:= aContas[nz,12]						
	local cFilComp  := FWModeAccess("SB1",3)
	local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("SB1")) 
	local cFilCSb2  := FWModeAccess("SB2",3)
	local cFilESB2	:= iif(cFilCSb2=='E',cFilMp,XFILIAL("SB2")) 
	local cFilCDAO  := FWModeAccess("DA0",3)
	local cFilEDA0 	:= iif(cFilCDAO=='E',cFilMp,XFILIAL("DA0")) 
	
	local cIdGrp , cCodPr , cDesPr
	
	local cWherePTE := '%'
	If ExistBlock("MP_PRODFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_PRODFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
	cWherePTE += '%'
	
	U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
	U_ParLog1(cNomeArq, "                                            PRODUTOS                                                "	)	
	U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	
		   
	BEGINSQL alias "TMP"
		select 
			B1_COD,
			B1_DESC,
			B1_GRUPO,
			B1_POSIPI,
			B1_XQTMULT, 
			B1_UM,
			B1_IPI,
			B1_MSBLQL,
			B1_PESBRU,
			SB1.D_E_L_E_T_ AS DEL,
			DA1.D_E_L_E_T_ AS DA1DEL,
			MAX(DA1_PRCVEN) AS DA1_PRCVEN,
			
			SB1.R_E_C_N_O_ AS SB1REC,
			DA1.R_E_C_N_O_ AS DA1REC
			
		from %table:SB1% SB1, %table:DA1% DA1
		
		where SB1.D_E_L_E_T_ + B1_XMPTRAN <> '* '
		AND B1_TIPO in %exp:cTpProd%	
		AND B1_FILIAL = %exp:cFilEnt%
		
		AND DA1_FILIAL = %exp:cFilEDA0%
		and DA1_CODPRO = B1_COD
		and DA1_CODTAB = %exp:cTabPad%
		
		
		and (    B1_XMPTRAN IN('A',' ')	or 
				 DA1_XMPTRA IN('A',' ') or 
				 NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
							MP1.MP1_FILIAL = %EXP:cFilMp% AND 
							MP1.MP1_CTAMP = %EXP:cCtaMp%  AND 
							MP1.MP1_IDPROT = B1_COD AND 
							MP1.MP1_TPREG = 'PRODUTO' AND 
							MP1.D_E_L_E_T_ <> '*'))

		%EXP:cWherePTE%	   	
		GROUP BY 	B1_COD, B1_DESC, B1_UM ,B1_GRUPO,B1_POSIPI,B1_XQTMULT,B1_IPI,SB1.D_E_L_E_T_ ,B1_MSBLQL,
					SB1.R_E_C_N_O_,DA1.R_E_C_N_O_ ,B1_PESBRU ,DA1.D_E_L_E_T_ 
	ENDSQL                  
	
	while TMP->(!eof())
		//TRATAMENTO CODIGO E DESCRICAO PARA ENVIO
		cCodPr := TMP->B1_COD
		cCodPr := strtran(cCodPr,'/','')
		cCodPr := strtran(cCodPr,'"','')
		
		cDesPr := alltrim(TMP->B1_DESC)
		cDesPr := strtran(cDesPr,'/','')
		cDesPr := strtran(cDesPr,'"','')	
		
		cIdGrp := U_GetIdEnt(cFilMp,cCtaMp,"GRUPO",alltrim(TMP->B1_GRUPO))
	
		aadd(aItens,{   cCodPr,;											//1
						cDesPr,;											//2 
						TMP->DA1_PRCVEN,;									//3
						alltrim(TMP->B1_UM),;								//4
						IIF(EMPTY(cIdGrp),'null',cIdGrp),;  				//5
						alltrim(TMP->B1_POSIPI),;							//6
						iif(empty(TMP->B1_XQTMULT),1,TMP->B1_XQTMULT),;		//7
								TMP->B1_IPI,;								//8
								TMP->B1_COD,;								//9
						iif((empty(TMP->DEL) .And. empty(TMP->DA1DEL)),"false","true"),; 				//10
						SB1REC,;											//11	
						DA1REC,;											//12
						iif(TMP->B1_MSBLQL == '1',"false","true"),;			//13
						round(TMP->B1_PESBRU,3)})									//14
						
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
		
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )  
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrado "+cvaltochar(len(aItens))+" Produto Novos ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '    "codigo": "'+aItens[x,1]+'",'
		cJson += '    "nome": "'+aItens[x,2]+'",'
		cJson += '    "comissao": 0,'
		cJson += '    "preco_tabela": '+cvaltochar(aItens[x,3])+','
		cJson += '    "preco_minimo": '+cvaltochar(aItens[x,3])+','
		cJson += '    "ipi": '+IIF(!EMPTY(aItens[x,8]),cvaltochar(aItens[x,8]),"null")+','
		cJson += '    "tipo_ipi": "P",'
		cJson += '    "st": null,'
		cJson += '    "grade_tamanhos": null,'
		cJson += '    "moeda": "0",'
		cJson += '    "unidade": "'+aItens[x,4]+'",'
		cJson += '    "observacoes": "", '
		cJson += '    "codigo_ncm": "' +aItens[x,6]+'",'
		cJson += '    "excluido": '+aItens[x,10]+','
		cJson += '    "ativo": '+aItens[x,13]+',' 
		cJson += '    "peso_bruto": '+cvaltochar(aItens[x,14])+',' 
		
		if aContas[nz,24] = 'S'
			cJson += '    "categoria_id":'+aItens[x,5]+','
		ENDIF
		
		cJson += '    "multiplo":'+ cvaltochar(aItens[x,7])
		cJson += '}'      
	
		If ExistBlock("MP_PRDJSON")
			cJson := ExecBlock("MP_PRDJSON",.F.,.F.,{aContas,cFilMp,cCtaMp,nz,aItens[x]})
		endif
	
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("SB1")  
			SET DELETED OFF
			DBGOTO(aItens[x,11])
	   		reclock("SB1",.F.)
	   			SB1->B1_XMPTRAN := 'X'
	   		msunlock()

			DBSELECTAREA("DA1")  
			SET DELETED OFF
			DBGOTO(aItens[x,12])
	   		reclock("DA1",.F.)
	   			DA1->DA1_XMPTRA := 'X'
	   		msunlock()
		   	
	   	endif
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"PRODUTO",aItens[x,9],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Produto "+aItens[x,9]+ " atualizado." )  
	 	
	NEXT X	
return()  

 
  
 /*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  SincProduto   � Autor � Lucas Pereira   � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � novos Produtos incluidos no ERP                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/  
  
static function SincEstoque(cFilMp,cCtaMp,nz)
local x
	local aItens 	:= {}
	local cTabPad 	:= aContas[nz,14]
	local cTpProd 	:= "%('" + STRTRAN(alltrim(aContas[nz,11]),';',"','" ) + "')%"    
	local cLocPad 	:= aContas[nz,12]	
	local cFilCSb1  := FWModeAccess("SB1",3)
	local cFilESB1	:= iif(cFilCSb1=='E',cFilMp,XFILIAL("SB1")) 					
	local cFilCSb2  := FWModeAccess("SB2",3)
	local cFilESB2	:= iif(cFilCSb2=='E',cFilMp,XFILIAL("SB2")) 
	local cFilCDA1  := FWModeAccess("DA1",3)
	local cFilEDA1 	:= iif(cFilCDA1=='E',cFilMp,XFILIAL("DA1")) 
	
	local cIdProd , cCodPr , cDesPr
	
	local cWherePTE := '%'
		If ExistBlock("MP_PRODEST")
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
			cWherePTE += ExecBlock("MP_PRODEST",.F.,.F.,{aContas,cFilEnt,nz})
		EndIf				
	cWherePTE += '%'
	
	U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
	U_ParLog1(cNomeArq, "                                            ESTOQUE                                                "	)	
	U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	
		   
	BEGINSQL alias "TMP"
		select 
			B1_COD,
			(B2_QATU - B2_QEMP - B2_RESERVA - B2_QPEDVEN ) AS SDL_EST,
			SB1.R_E_C_N_O_ AS SB1REC,
			DA1.R_E_C_N_O_ AS DA1REC,
			SB2.R_E_C_N_O_ AS SB2REC
			
		from %table:SB1% SB1, %table:DA1% DA1 , %table:SB2% SB2
	 
		where SB2.D_E_L_E_T_ + B2_XMPTRAN <> '* '
		AND B1_TIPO in %exp:cTpProd%	
		AND B1_FILIAL = %exp:cFilESB1%
		
		AND DA1.%notdel%
		AND DA1_FILIAL = %exp:cFilEDA1%
		and DA1_CODPRO = B1_COD
		and DA1_CODTAB = %exp:cTabPad%
		
		AND SB2.%notdel%
	    AND B2_COD = B1_COD
	    AND B2_FILIAL = %exp:cFilMp%
	    AND B2_LOCAL = %exp:cLocPad%
		
		and (    B2_XMPTRAN IN('A',' ') or 
				 NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
							MP1.MP1_FILIAL = %EXP:cFilMp% AND 
							MP1.MP1_CTAMP = %EXP:cCtaMp%  AND 
							MP1.MP1_IDPROT = B1_COD AND 
							MP1.MP1_TPREG = 'ESTOQUE' AND 
							MP1.D_E_L_E_T_ <> '*'))

		%EXP:cWherePTE%	   	
		GROUP BY 	B1_COD, SB1.D_E_L_E_T_ ,
					B2_QATU ,B2_QEMP,B2_RESERVA,B2_QPEDVEN,SB1.R_E_C_N_O_,DA1.R_E_C_N_O_ ,SB2.R_E_C_N_O_  
	ENDSQL                  
	
	while TMP->(!eof())

		cIdProd := U_GetIdEnt(cFilMp,cCtaMp,"PRODUTO",alltrim(TMP->B1_COD))
		if !empty(cIdProd)
			aadd(aItens,{   TMP->B1_COD,;			//1
							TMP->SDL_EST ,;			//2
							cIdProd,;				//3
							TMP->B1_COD,;			//4
							TMP->SB2REC})			//5
		endif				
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
		
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )  
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrado "+cvaltochar(len(aItens))+" Altera��es de estoque Novos ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson +=    '"produto_id": '+cvaltochar(aItens[X,3])+','
		cJson +=    '"novo_saldo": '+cvaltochar(aItens[X,2])
		cJson += '}'
		
	
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilCSb2 == 'E')	

			DBSELECTAREA("SB2")  
			SET DELETED OFF
			DBGOTO(aItens[x,5]) 
	   		reclock("SB2",.F.)
	   			SB2->B2_XMPTRAN := 'X'
	   		msunlock()

	   	endif
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"ESTOQUE",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Estoque "+aItens[x,1]+ " atualizado." )  
	 	
	NEXT X	
return()  
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCliERP  � Autor � Lucas Pereira    � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � novos Clientes incluidos no ERP                            ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincTransp(cFilMp,cCtaMp,nz)
local x
local aItens 	:= {}
local cFilComp  := FWModeAccess("SA4",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("SA4")) 

local cWherePTE := '%'
	If ExistBlock("MP_TRNSFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_TRNSFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'
				
U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                         TRANSPORTADORAS                                            "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  

		BEGINSQL alias "TMP"
			SELECT	A4_COD,
					A4_NOME,
					A4_MUN,
					A4_EST,
					A4_DDD,
					A4_TEL,
					D_E_L_E_T_ as del,
					R_E_C_N_O_ AS REC
					 
			FROM %table:SA4% 
			WHERE D_E_L_E_T_ + A4_XMPTRAN <> '* ' and 
				A4_FILIAL = %EXP:cFilEnt% AND
				(A4_XMPTRAN <> 'I' OR
				NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
							MP1.MP1_FILIAL = %EXP:cFilMp% AND
							MP1.MP1_CTAMP = %EXP:cCtaMp%  AND 
							MP1.MP1_IDPROT = A4_COD AND 
							MP1.MP1_TPREG = 'TRANSPOR' AND 
							MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%	
		ENDSQL                  
		
		
		while TMP->(!eof())  
		
				
			aadd(aItens,{   TMP->A4_COD,;     	  					// 1
							alltrim(TMP->A4_NOME),;    						// 2
							alltrim(TMP->A4_MUN),;       					// 3
							alltrim(TMP->A4_EST),;     						// 4
							alltrim(TMP->(A4_DDD+" "+A4_TEL)),;     		// 5
							iif(!empty(TMP->del),"true","false"),;     		// 6  
							TMP->REC,;										// 7
							})
		TMP->(DBSKIP())                                                    
		ENDDO 
		TMP->(DBCLOSEAREA())      
		
		if empty(aItens)   
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." ) 
			return()
		else
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrado "+cvaltochar(len(aItens))+" Transportadoras ..." )   
		endif
		
		FOR X:=1 TO LEN(aItens) 
		
			cJson := '{'
			cJson += '  "nome":  "'+aItens[x,2]+'",'
			cJson += '  "cidade": "'+aItens[x,3]+'",'
			cJson += '  "estado":  "'+aItens[x,4]+'",'
			cJson += '  "telefones": ['
			cJson += '        { '
			cJson += '            "numero": "'+iif(empty(aItens[x,5]),"99999999",aItens[x,5])+'"'
			cJson += '        }'
			cJson += '  ],'
			cJson += '  "excluido":  '+aItens[x,6]
			cJson += '}'	
			

		   	
		   	IF len(aContas) == nz .OR.;
		   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')
		   	
				DBSELECTAREA("SA4")  
				SET DELETED OFF
				DBGOTO(aItens[x,7])
		   		reclock("SA4",.F.)
		   			SA4->A4_XMPTRAN := 'X'
		   		msunlock()
			   	
		   	endif
		   	
			U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"TRANSPOR",aItens[x,1],cJson)
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Transportadora "+aItens[x,1]+ " atualizado." )  
		NEXT X   

return()   

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincCabTab(cFilMp,cCtaMp,nz)
local x
local aItens    := {} 
local cTabPad 	:=  aContas[nz,14]
local cFilComp  := FWModeAccess("DA0",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("DA0")) 

local cWherePTE := '%'
	If ExistBlock("MP_TABCFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_TABCFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                  CABECALHO DE TABELAS DE PRECO                                                "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	

	BEGINSQL alias "TMP"  
	
		SELECT DA0_CODTAB,
				DA0_DESCRI,
				DA0_XMPTRA,
				DA0_XMPINT,
				D_E_L_E_T_ as del,
				R_E_C_N_O_ AS REC
		FROM %table:DA0%  DA0
		WHERE //DA0_CODTAB <> %exp:cTabPad% AND 
			  DA0_FILIAL = %exp:cFilEnt% AND
			   ( DA0_XMPTRA + DA0_XMPINT = 'AS' OR	//NOVAS TABELAS
		  		 DA0_XMPTRA + DA0_XMPINT = 'EN')  	//EXCLUSAO DE TABELAS JA INTEGRADAS E ATIVAS NO PROTHEUS
					OR (DA0_XMPTRA + DA0_XMPINT = 'IS' AND
					 NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
							MP1.MP1_FILIAL = %EXP:cFilMp% AND
							MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
							MP1.MP1_IDPROT = DA0_CODTAB AND 
							MP1.MP1_TPREG = 'TABPR_CAB' AND 
							MP1.D_E_L_E_T_ <> '*'))
	
		%EXP:cWherePTE%	
	ENDSQL                  
	
	while TMP->(!eof())
		aadd(aItens,{   TMP->DA0_CODTAB,;
						alltrim(TMP->DA0_DESCRI),; 
						iif(!empty(TMP->del) .or. TMP->DA0_XMPINT <> 'S',"true","false"),;
						TMP->DA0_XMPINT  ,;
						TMP->REC})
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )  
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrada "+cvaltochar(len(aItens))+" Tabela de Pre�o Alteradas ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '    "nome": "'+aItens[x,2]+'", '
		cJson += '    "tipo": "P",'
		cJson += '    "acrescimo": null,'
		cJson += '    "desconto": null,'
		cJson += '    "excluido": '+aItens[x,3]
		cJson += '}'
	
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("DA0")  
			SET DELETED OFF
			DBGOTO(aItens[x,5])
	   		reclock("DA0",.F.)
	   			DA0->DA0_XMPTRA := 'X'
	   		msunlock()
		   	
	   	endif
	   	IF aItens[x,1] <> cTabPad //ADICIONADO PARA GRAVAR FLAG DE INTEGRADO PARA TABELAS PADROES
	   		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"TABPR_CAB",aItens[x,1],cJson)
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Cabecalho de Tabela de Pre�o "+aItens[x,1]+ " atualizado." ) 
		ENDIF
	NEXT X   
return()  




/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincItemTab(cFilMp,cCtaMp,nz)
local x
local aItens    := {} 
local cTabPad 	:=  aContas[nz,14]
local cFilComp  := FWModeAccess("DA1",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("DA1")) 
local cTabId, cPrdId


local cWherePTE := '%'
	If ExistBlock("MP_TABIFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_TABIFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                    ITENS DE TABELA DE PRECO                                                "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	
	
	BEGINSQL alias "TMP"  
	
		SELECT  DA1_CODPRO,
				DA0_CODTAB,
				DA1_ITEM,
				MAX(DA1_PRCVEN) AS DA1_PRCVEN, 
			    DA1.D_E_L_E_T_ as del,
				DA1.R_E_C_N_O_ AS REC
				
		FROM %table:DA1% DA1, %table:DA0% DA0
		
		WHERE DA0_CODTAB = DA1_CODTAB
			  AND DA0_FILIAL = DA1_FILIAL
			  AND DA0_XMPINT = 'S'
			  AND DA0.%NOTDEL%
			  AND DA0_CODTAB <> %exp:cTabPad% 
			  AND DA0_FILIAL = %exp:cFilEnt% 
			  AND ( DA1_XMPTRA <> 'I' OR 
			  	   NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
							MP1.MP1_FILIAL = %EXP:cFilMp% AND
							MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
							MP1.MP1_IDPROT = DA0_CODTAB +DA1_ITEM+ DA1_CODPRO AND 
							MP1.MP1_TPREG = 'TABPR_ITEM' AND 
							MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%	
		GROUP BY DA1_CODPRO,
				DA0_CODTAB,
				DA1_ITEM,
			    DA1.D_E_L_E_T_,
				DA1.R_E_C_N_O_
	ENDSQL                  
	
	while TMP->(!eof())
		aadd(aItens,{   TMP->DA0_CODTAB,; 
						TMP->DA1_CODPRO,;
						DA1_ITEM,;
						TMP->DA1_PRCVEN,;
						TMP->REC,;
						iif(!empty(TMP->del) ,"true","false")})
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." ) 
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrado "+cvaltochar(len(aItens))+" Item - Tabela de Pre�o Alterados ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)    
		cTabId	:= U_GetIdEnt(cFilMp,cCtaMp,"TABPR_CAB",aItens[x,1]) 
		cPrdId	:= U_GetIdEnt(cFilMp,cCtaMp,"PRODUTO",aItens[x,2])
		
		IF !EMPTY(cTabId) .AND. !EMPTY(cPrdId)
		 
			cJson := '{'
			cJson += '    "tabela_id": '+cTabId+', '
			cJson += '    "produto_id": '+cPrdId+', '
			cJson += '    "preco": '+cvaltochar(iif(aItens[x,6] == 'true',0,aItens[x,4]))+','
			cJson += '    "excluido": '+aItens[x,6]
			cJson += '}'
			
			IF len(aContas) == nz .OR.;
			(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')		
				DBSELECTAREA("DA1")  
				SET DELETED OFF
				DBGOTO(aItens[x,5])
		   		reclock("DA1",.F.)
		   			DA1->DA1_XMPTRA := 'X'
		   		msunlock()
			   	
		   	endif
			U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"TABPR_ITEM",aItens[x,1]+aItens[x,3]+aItens[x,2],cJson)
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Itens de Tabela de Pre�o "+aItens[x,1]+aItens[x,3]+aItens[x,2]+ " atualizado." ) 
		ELSE
			U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Itens de Tabela de Pre�o "+aItens[x,1]+aItens[x,3]+aItens[x,2]+ " Dados Nao Basicos nao Encontrados." ) 
		ENDIF
			
	NEXT X   
return()  



/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincCondPag(cFilMp,cCtaMp,nz)
local x
local aItens    := {} 
local cFilComp  := FWModeAccess("SE4",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("SE4")) 

local cWherePTE := '%'
	If ExistBlock("MP_CONDFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_CONDFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                       CONDICAO DE PAGAMENTO                                              "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	

	BEGINSQL alias "TMP"
		SELECT 	E4_DESCRI,
				E4_CODIGO,
				E4_XMPVLM,
				E4_XMPINTE,
				D_E_L_E_T_ as del,
				R_E_C_N_O_ AS REC
	 	FROM %table:SE4% 
		where 	E4_FILIAL = %EXP:cFilEnt% AND
				( E4_XMPTRAN + E4_XMPINTE = 'AS' OR	//NOVAS TABELAS
		  		E4_XMPTRAN + E4_XMPINTE = 'EN')  	//EXCLUSAO DE TABELAS JA INTEGRADAS E ATIVAS NO PROTHEUS

		  		OR (E4_XMPTRAN + E4_XMPINTE = 'IS' AND
					 NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
							MP1.MP1_FILIAL = %EXP:cFilMp% AND
							MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
							MP1.MP1_IDPROT = E4_CODIGO AND 
							MP1.MP1_TPREG = 'COND_PAG' AND 
							MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%	
	ENDSQL                  
	
	while TMP->(!eof())
		aadd(aItens,{   alltrim(TMP->E4_DESCRI),;
						TMP->E4_CODIGO,;
						iif(!empty(TMP->del) .or. TMP->E4_XMPINTE <> 'S',"true","false"),;
				   		cvaltochar(TMP->E4_XMPVLM) ,;
				   		TMP->REC })
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )  
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrada "+cvaltochar(len(aItens))+" Condicao de pagamento Alteradas ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '    "nome": "'+aItens[x,1]+'", '
		cJson += '    "valor_minimo": ' + IIF(EMPTY(aItens[x,4]),'null',aItens[x,4])+','
		cJson += '    "excluido": '+aItens[x,3]
		cJson += '} '
		
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("SE4")  
			SET DELETED OFF
			DBGOTO(aItens[x,5])
	   		reclock("SE4",.F.)
	   			SE4->E4_XMPTRAN := 'X'
	   		msunlock()
		   	
	   	endif
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"COND_PAG",aItens[x,2],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Condicao de Pagamento "+aItens[x,2]+ " atualizado." ) 
	NEXT X   
return()  




/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincTabCli(cFilMp,cCtaMp,nz)
local d
local x
local aItens    := {} 
local cClient	:= ""
local cCliId	:= ""
local cTabsId	:= ""
local cTabPad 	:=  aContas[nz,14]
local cFilComp  := FWModeAccess("MPA",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("MPA")) 
local cIdTrb, aTabs

local cWherePTE := '%'
	If ExistBlock("MP_TBCLFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_TBCLFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'



U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                   CLIENTES X TABELAS DE PRECO                                     "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	


	BEGINSQL alias "TMP"
		SELECT DISTINCT MPA_CLIENT+MPA_LOJA CLIENTE , 
		MPA_TABELA, D_E_L_E_T_ as del , R_E_C_N_O_ AS REC
		
		FROM %table:MPA% 
		WHERE MPA_FILIAL = %exp:cFilEnt% 
		AND ( MPA_XMPTRA <> 'I' or
	  	   NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
				MP1.MP1_FILIAL = %EXP:cFilMp% AND
				MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
				MP1.MP1_IDPROT = MPA_CLIENT+MPA_LOJA  AND 
				MP1.MP1_TPREG = 'CLI_TAB' AND 
				MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%			
		ORDER BY R_E_C_N_O_
	ENDSQL 
	
	while TMP->(!eof())
		cClient := TMP->CLIENTE
		cCliId  := U_GetIdEnt(cFilMp,cCtaMp,"CLIENTE",cClient)
		aTabs   := Separa(alltrim(TMP->MPA_TABELA),';',.f.)
		cTabsId := ''
		
		for d:=1 to len(aTabs)
			if cTabPad <> aTabs[d]
				cIdTrb	:= U_GetIdEnt(cFilMp,cCtaMp,"TABPR_CAB",aTabs[d])
				if !empty(cIdTrb)
					cTabsId += cIdTrb+','
				endif
			endif
		next d
		
		if empty(cTabsId) .OR. TMP->del == '*'
			cTabsId := '0,'
		endif
		
		IF !empty(cCliId)	
			aadd(aItens,{  cClient , cCliId ,substr(cTabsId,1,len(cTabsId)-1) , TMP->REC})	
		endif
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )    
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrada "+cvaltochar(len(aItens))+" vincluo de Tabelas de Preco Alterados ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '   "cliente_id": '+aItens[X,2]+','
		cJson += '   "tabelas_liberadas": ['+aItens[X,3]+']'
		cJson += '}'
		
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("MPA")  
			SET DELETED OFF
			DBGOTO(aItens[X,4])		
	   		reclock("MPA",.F.)
	   			MPA->MPA_XMPTRA := 'X'
	   		msunlock()
		   	
	   	endif
	   	
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"CLI_TAB",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" vinculo de Tabelas de Preco "+aItens[x,1]+ " atualizado." ) 		   	
	NEXT X
    		
return()


/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincFormPg(cFilMp,cCtaMp,nz)
local x
local aItens    := {} 
local cFilComp  := FWModeAccess("MPC",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("MPC")) 

local cWherePTE := '%'
	If ExistBlock("MP_FORMFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_FORMFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                        FORMAS DE PAGAMENTO                                         "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	


	BEGINSQL alias "TMP"
		SELECT MPC_FORMA , 
		MPC_DESCRI, D_E_L_E_T_ as del , R_E_C_N_O_ AS REC
		
		FROM %table:MPC% 
		WHERE MPC_FILIAL = %exp:cFilEnt% 
		AND ( MPC_XMPTRA <> 'I' or
	  	   NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
				MP1.MP1_FILIAL = %EXP:cFilMp% AND
				MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
				MP1.MP1_IDPROT = MPC_FORMA  AND 
				MP1.MP1_TPREG = 'FORMA_PG' AND 
				MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%			
		ORDER BY R_E_C_N_O_
	ENDSQL 
	
	while TMP->(!eof())	
			aadd(aItens,{  TMP->MPC_FORMA ,;
			 			   ALLTRIM(TMP->MPC_DESCRI) ,;
			 			   IIF(TMP->del=='*','true','false') ,; 
			 			   TMP->REC})	
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )    
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrada "+cvaltochar(len(aItens))+" formas de pagamento Alterados ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '   "nome": "'+aItens[X,2]+'",'
		cJson += '   "excluido": '+aItens[X,3]
		cJson += '}'
		
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("MPC")  
			SET DELETED OFF
			DBGOTO(aItens[X,4])		
	   		reclock("MPC",.F.)
	   			MPC->MPC_XMPTRA := 'X'
	   		msunlock()
		   	
	   	endif
	   	
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"FORMA_PG",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Forma de Pagamento "+aItens[x,1]+ " atualizado." ) 		   	
	NEXT X
    		
return()





/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincTipoPed(cFilMp,cCtaMp,nz)
local x
local aItens    := {} 
local cFilComp  := FWModeAccess("MPE",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("MPE")) 

local cWherePTE := '%'
	If ExistBlock("MP_TPEDFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_TPEDFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                          TIPOS DE PEDIDOS                                          "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	


	BEGINSQL alias "TMP"
		SELECT MPE_TIPO , 
		MPE_DESCRI, D_E_L_E_T_ as del , R_E_C_N_O_ AS REC
		
		FROM %table:MPE% 
		WHERE MPE_FILIAL = %exp:cFilEnt% 
		AND ( MPE_XMPTRA <> 'I' or
	  	   NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
				MP1.MP1_FILIAL = %EXP:cFilMp% AND
				MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
				MP1.MP1_IDPROT = MPE_TIPO  AND 
				MP1.MP1_TPREG = 'TIPO_PED' AND 
				MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%			
		ORDER BY R_E_C_N_O_
	ENDSQL 
	
	while TMP->(!eof())	
			aadd(aItens,{  TMP->MPE_TIPO ,;
			 			   ALLTRIM(TMP->MPE_DESCRI) ,;
			 			   IIF(TMP->del=='*','true','false') ,; 
			 			   TMP->REC})	
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )    
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrada "+cvaltochar(len(aItens))+" Tipos de Pedidos Alterados ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '   "nome": "'+aItens[X,2]+'",'
		cJson += '   "excluido": '+aItens[X,3]
		cJson += '}'
		
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("MPE")  
			SET DELETED OFF
			DBGOTO(aItens[X,4])		
	   		reclock("MPE",.F.)
	   			MPE->MPE_XMPTRA := 'X'
	   		msunlock()
		   	
	   	endif
	   	
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"TIPO_PED",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Tipo de Pedido "+aItens[x,1]+ " atualizado." ) 		   	
	NEXT X
    		
return()


/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincStsPed(cFilMp,cCtaMp,nz)
local x
local aItens    := {} 
local cFilComp  := FWModeAccess("MPF",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("MPF")) 

local cWherePTE := '%'
	If ExistBlock("MP_STPEDFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_STPEDFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                         STATUS DE PEDIDOS                                          "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	


	BEGINSQL alias "TMP"
		SELECT MPF_STATUS , 
		MPF_DESCRI, D_E_L_E_T_ as del , R_E_C_N_O_ AS REC
		
		FROM %table:MPF% 
		WHERE MPF_FILIAL = %exp:cFilEnt% 
		AND ( MPF_XMPTRA <> 'I' or
	  	   NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
				MP1.MP1_FILIAL = %EXP:cFilMp% AND
				MP1.MP1_CTAMP = %EXP:cCtaMp%  AND
				MP1.MP1_IDPROT = MPF_STATUS  AND 
				MP1.MP1_TPREG = 'STS_PED' AND 
				MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%			
		ORDER BY R_E_C_N_O_
	ENDSQL 
	
	while TMP->(!eof())	
			aadd(aItens,{  TMP->MPF_STATUS ,;
			 			   ALLTRIM(TMP->MPF_DESCRI) ,;
			 			   IIF(TMP->del=='*','true','false') ,; 
			 			   TMP->REC})	
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )    
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrada "+cvaltochar(len(aItens))+" Status de Pedidos Alterados ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '   "nome": "'+aItens[X,2]+'",'
		cJson += '   "excluido": '+aItens[X,3]
		cJson += '}'
		
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("MPF")  
			SET DELETED OFF
			DBGOTO(aItens[X,4])		
	   		reclock("MPF",.F.)
	   			MPF->MPF_XMPTRA := 'X'
	   		msunlock()
		   	
	   	endif
	   	
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"STS_PED",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Status de Pedido "+aItens[x,1]+ " atualizado." ) 		   	
	NEXT X
    		
return()




/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  NovosCondPag � Autor � Lucas Pereira   � Data �  08/06/16    ���
�������������������������������������������������������������������������͹��
���Descricao � novas Condi��es de pagamento incluidas no ERP              ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

static function SincCondCli(cFilMp,cCtaMp,nz)
local d
local x
local aItens    := {} 
local cClient	:= ""
local cCliId	:= ""
local cCondsId	:= ""
local cFilComp  := FWModeAccess("MPB",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("MPB")) 
local cIdTrb , aConds

local cWherePTE := '%'
	If ExistBlock("MP_CNCLFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_CNCLFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                  CLIENTE X CONDCAO DE PAGAMENTO                                             "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	


	BEGINSQL alias "TMP"
		SELECT DISTINCT MPB_CLIENT+MPB_LOJA CLIENTE , MPB_COND, 
		D_E_L_E_T_ as del , R_E_C_N_O_ AS REC
		FROM %table:MPB% 
		WHERE MPB_FILIAL = %exp:cFilEnt% 
		AND ( MPB_XMPTRA <> 'I' or
	  	   NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
				MP1.MP1_FILIAL = %EXP:cFilMp% AND
				MP1.MP1_CTAMP = %EXP:cCtaMp% AND 
				MP1.MP1_IDPROT = MPB_CLIENT+MPB_LOJA  AND 
				MP1.MP1_TPREG = 'CLI_COND' AND 
				MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%	
	ENDSQL 
	
	while TMP->(!eof())
		cClient := TMP->CLIENTE
		cCliId  := U_GetIdEnt(cFilMp,cCtaMp,"CLIENTE",cClient)
		aConds   := Separa(alltrim(TMP->MPB_COND),';',.f.)
		cCondsId := ''
		
		for d:=1 to len(aConds)
			cIdTrb	:= U_GetIdEnt(cFilMp,cCtaMp,"COND_PAG",aConds[d])
			if !empty(cIdTrb)
				cCondsId += cIdTrb+','
			endif
		next d
		
		if empty(cCondsId) .OR. TMP->del == '*'
			cCondsId := '0,'
		endif
		
		IF !empty(cCliId)	
			aadd(aItens,{  cClient , cCliId ,substr(cCondsId,1,len(cCondsId)-1), TMP->REC })	
		endif
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      
	
	
	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )   
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrada "+cvaltochar(len(aItens))+" vincluo de Cond.Pagamento Alterados ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   

		cJson := '{'
		cJson += '   "cliente_id": '+aItens[X,2]+','
		cJson += '   "condicoes_pagamento_liberadas": ['+aItens[X,3]+']'
		cJson += '}'
		
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("MPB")  
			SET DELETED OFF
			DBGOTO(aItens[X,4])
	   		reclock("MPB",.F.)
	   			MPB->MPB_XMPTRA := 'X'
	   		msunlock()
		   	
	   	endif
	   	
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"CLI_COND",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" vincluo de Cond.Pagamento "+aItens[x,1]+ " atualizado." ) 		   	
	NEXT X
    		
return()
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  JOBMPED1   � Autor � Lucas Pereira	     � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � Integra��o For�a de vendas Meus Pedidos - Cadastros        ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
static function SincConfSt(cFilMp,cCtaMp,nz)
local x
local aItens    := {} 
local cClient	:= ""
local cCliId	:= ""
local cCondsId	:= ""
local cFilComp  := FWModeAccess("SZT",3)
local cFilEnt 	:= iif(cFilComp=='E',cFilMp,XFILIAL("SZT")) 
local cIdTrb , aConds

local cWherePTE := '%'
	If ExistBlock("MP_CFSTFIL")
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" PTE identificado." ) 
		cWherePTE += ExecBlock("MP_CFSTFIL",.F.,.F.,{aContas,cFilEnt,nz})
	EndIf				
cWherePTE += '%'

U_ParLog1(cNomeArq, " ****************************************************************************************************" )   
U_ParLog1(cNomeArq, "                                     CONFIGURACAO ICMS ST                                             "	)	
U_ParLog1(cNomeArq, " ****************************************************************************************************" )  	
	
	BEGINSQL alias "TMP"
		SELECT 		ZT_COD		,
					ZT_POSIPI   ,
					ZT_GRPCLI   ,
					ZT_ESTADO   ,
					ZT_TIPOST   ,
					ZT_MVA      ,
					ZT_PCM      ,
					ZT_ICMDEST  ,
					ZT_ICMORIG  ,
					D_E_L_E_T_ AS DEL,
					R_E_C_N_O_ AS REC
	 	FROM %table:SZT% 
		where ZT_FILIAL = %exp:cFilEnt% 		
		  AND ( ZT_XMPTRAN <> 'I' or
	  	   NOT EXISTS(SELECT * FROM %TABLE:MP1% MP1 WHERE 
				MP1.MP1_FILIAL = %EXP:cFilMp% AND
				MP1.MP1_CTAMP = %EXP:cCtaMp% AND 
				MP1.MP1_IDPROT = ZT_COD  AND 
				MP1.MP1_TPREG = 'CONF_ST' AND 
				MP1.D_E_L_E_T_ <> '*'))
		%EXP:cWherePTE%	
	ENDSQL                  
	
	while TMP->(!eof())
		aadd(aItens,{   TMP->ZT_COD		 ,;
						alltrim(TMP->ZT_POSIPI)		 ,;
						alltrim(TMP->ZT_GRPCLI)      ,;
						alltrim(TMP->ZT_ESTADO)      ,;
						alltrim(TMP->ZT_TIPOST)      ,;
						IF(EMPTY(TMP->ZT_MVA),'null',cvaltochar(TMP->ZT_MVA))  ,;
						IF(EMPTY(TMP->ZT_PCM),'null',cvaltochar(TMP->ZT_PCM))  ,;
						cvaltochar(TMP->ZT_ICMDEST)  ,;
						cvaltochar(TMP->ZT_ICMORIG)	,;
						TMP->del,;
						TMP->REC})				
	TMP->(DBSKIP())                                                    
	ENDDO 
	TMP->(DBCLOSEAREA())      

	if empty(aItens)   
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Nenhuma alteracao encontrada..." )  
		return()
	else
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Encontrada "+cvaltochar(len(aItens))+" Configuracao ST ..." )   
	endif
	
	FOR X:=1 TO LEN(aItens)   
	
		cJson := '{'
		cJson += '"codigo_ncm": "'+aItens[x,2]+'",'
		cJson += '"nome_excecao_fiscal": "'+aItens[x,3]+'",'
		cJson += '"estado_destino": "'+aItens[x,4]+'",'
		cJson += '"tipo_st": "'+aItens[x,5]+'",'
		cJson += '"valor_mva": '+aItens[x,6]+','
		cJson += '"valor_pmc": '+aItens[x,7]+','
		cJson += '"icms_destino": '+aItens[x,8]+','
		cJson += '"icms_credito": '+aItens[x,9]+''
		cJson += '}'
		
		IF aItens[X,10] == '*'
			cJson := '{ excluido: true }'
		ENDIF
		
		IF len(aContas) == nz .OR.;
	   	(cCtaMp == U_RetMxCtaFil(cFilMP) .AND. cFilComp == 'E')	
			DBSELECTAREA("SZT")  
			SET DELETED OFF
			DBGOTO(aItens[X,11])
	   		reclock("SZT",.F.)
	   			SZT->ZT_XMPTRAN := 'X'
	   		msunlock()
		   	
	   	endif
		U_MP1_GRVENT(.F.,cFilMp,cCtaMp,"CONF_ST",aItens[x,1],cJson)
		U_ParLog1(cNomeArq, dtoc( Date() )+" "+Time()+" Configuracao ST "+aItens[x,1]+ " atualizado." ) 		   	
 
	NEXT X   
 
return()          

      
/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  JOBMPED1   � Autor � Lucas Pereira	     � Data �  08/06/16   ���
�������������������������������������������������������������������������͹��
���Descricao � Integra��o For�a de vendas Meus Pedidos - Cadastros        ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP6 IDE                                                    ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
