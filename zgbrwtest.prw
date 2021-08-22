#include 'TOTVS.CH'

/*/{Protheus.doc} zgbrwtest
Browser de teste baseado no exemplo do mestre Daniel Atilio https://terminaldeinformacao.com/
@type function
@author Giulliano
@since 21/08/2021
/*/

user function zgbrwtest()

Local oBrowse
Local aArea := GetArea()
Private cAlias := GetNextAlias()
Private oTempTable := FWTemporaryTable():New(cAlias)
//Itens para formação da janela
Private aFields := {}
Private aCampos := {}
Private oDlgGrp
Private oPanGrid
Private aColunas := {}
//Tamanho Janela
Private    aTamanho := MsAdvSize()
Private    nJanLarg := aTamanho[5]
Private    nJanAltu := aTamanho[6]

//Tabela
//Estrutura dos campos da tabela temporaria
aAdd(aFields, {"BW_CODIGO", "C", TamSX3('BM_GRUPO')[01],   0})
aAdd(aFields, {"BW_DESC", "C", TamSX3('BM_DESC')[01],   0})
aAdd(aFields, {"BW_QTDPRO", "N", 18,   0})

//Cria tabela no banco de dados
oTempTable:SetFields(aFields)
oTempTable:AddIndex('1',{'BW_CODIGO'})
oTempTable:Create()

//Função para montar o cabeçalho do browse
MontHead()

//Monta os dados executando uma query para popular a tabela temporaria
FWMsgRun(, {|oSay| MontDados(oSay) }, "Processando", "Buscando Dados")

//Janela
DEFINE MSDIALOG oDlgGrp TITLE "Grupos de Produtos" FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL

	//botao
	@ 006, (nJanLarg/2-001)-(0052*01) BUTTON oBtnFech  PROMPT "Fechar"        SIZE 050, 018 OF oDlgGrp ACTION (oDlgGrp:End()) PIXEL
	@ 006, (nJanLarg/2-001)-(0052*02) BUTTON oBtnLege  PROMPT "Ver Grupo"     SIZE 050, 018 OF oDlgGrp ACTION (oDlgGrp:End()) PIXEL

	//Dados
	@ 024, 003 GROUP oGrpDad TO (nJanAltu/2-003), (nJanLarg/2-003) PROMPT "Teste de Browser" OF oDlgGrp COLOR 0, 16777215 PIXEL
	oPanGrid := tPanel():New(033, 006, "", oDlgGrp, , , , RGB(000,000,000), RGB(254,254,254), (nJanLarg/2 - 130),     (nJanAltu/2 - 45))
	oBrowse := FWBROWSE():New()
	oBrowse:DisableFilter()
	oBrowse:DisableConfig()
	oBrowse:DisableReport()
	oBrowse:DisableSeek()
	oBrowse:DisableSaveConfig()
	//oBrowse:SetFontBrowse(oFontBtn)
	oBrowse:SetAlias(cAlias)
	oBrowse:SetDataTable()
	oBrowse:SetInsert(.F.)
	oBrowse:SetDelete(.F., { || .F. })
	oBrowse:lHeaderClick := .F.
	oBrowse:SetColumns(aColunas)
	oBrowse:SetOwner(oPanGrid)
	oBrowse:Activate()
ACTIVATE MsDialog oDlgGrp CENTERED

oTempTable:Delete()
RestArea(aArea)

return

/*/{Protheus.doc} MontHead
Monta cabecalho
@type function
@author Giulliano
@since 21/08/2021
/*/
Static Function MontHead()

	Local aCab := {}
	Local nX
    //Adicionando colunas
    //[1] - Campo da Temporaria
    //[2] - Titulo
    //[3] - Tipo
    //[4] - Tamanho
    //[5] - Decimais
    //[6] - Máscara
	aAdd(aCab, {"BW_CODIGO",    "Codigo",			"C", TamSX3('BM_GRUPO')[01],0, ""})
	aAdd(aCab, {"BW_DESC",      "Descricao",		"C", TamSX3('BM_DESC')[01], 0, ""})
	aAdd(aCab, {"BW_QTDPRO",	"Total Produtos", 	"N", 18,   					0, "@E 999,999,999,999,999,999"})

	//Criando Colunas com base na estrutura criada a cima
	For nX := 1 to Len(aCab) 
		oColumn := FWBrwColumn():New()
        oColumn:SetData(&("{|| " + cAlias + "->" + aCab[nX][1] +"}"))
        oColumn:SetTitle(aCab[nX][2])
        oColumn:SetType(aCab[nX][3])
        oColumn:SetSize(aCab[nX][4])
        oColumn:SetDecimal(aCab[nX][5])
        oColumn:SetPicture(aCab[nX][6])
        aAdd(aColunas, oColumn)
	Next nX

return

/*/{Protheus.doc} MontDados
Monta os dados executando uma query para popular a tabela temporaria
@type function
@author Giulliano
@since 21/08/2021
/*/

Static Function MontDados(oSay)

	Local aArea := GetArea()
	Local cTabela := GetNextAlias()
	Local nLoop
	
	oSay:SetText('Executando Consulta')
	BeginSql Alias cTabela
		SELECT BM_GRUPO, BM_DESC, COUNT(B1_COD) AS QTD_PROD
		FROM %Table:SBM% SBM
		INNER JOIN %Table:SB1% SB1 ON B1_GRUPO = BM_GRUPO
		AND SB1.%NotDel% AND B1_COD >= '10000'
		AND B1_MSBLQL != 1 AND B1_LOCPAD = '0106'
		WHERE BM_FILIAL = %xFilial:SBM% AND SBM.%NotDel%
		GROUP BY BM_GRUPO, BM_DESC
	EndSql

	DbSelectArea(cTabela)

	If ! (cTabela)->(Eof())
		Count To nTotal
		(cTabela)->(DbGoTop())

		While (cTabela)->(! Eof())
			nLoop++
            oSay:SetText("Adicionando registro " + cValToChar(nLoop) + " de " + cValToChar(nTotal) + "...")

			if RecLock(cAlias, .T.)
				(cAlias)->BW_CODIGO	:= (cTabela)->BM_GRUPO
				(cAlias)->BW_DESC	:= (cTabela)->BM_DESC
				(cAlias)->BW_QTDPRO	:= (cTabela)->QTD_PROD
				(cAlias)->(MsUnlock())
			endif
		
			(cTabela)->(DbSkip())
		EndDo

	Else
		MsgAlert('Nao foram encontrados registros', 'Sem Registros')
		if RecLock(cAlias, .T.)
			(cAlias)->BW_CODIGO	:= ''
			(cAlias)->BW_DESC	:= ''
			(cAlias)->BW_QTDPRO	:= 0
			(cAlias)->(MsUnlock())
		endif
		
	EndIf
	(cTabela)->(DbCloseArea())
	(cAlias)->(DbGoTop())

RestArea(aArea)
return
