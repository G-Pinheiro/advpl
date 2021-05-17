#include "protheus.ch"
#include "totvs.ch"
#include "fileio.ch"
#include "topconn.ch"

/*
+------------------+------------------------------------------------------------------------------------+
!Autor             ! Giulliano Pinheiro 	                                                              !
+------------------+------------------------------------------------------------------------------------+
!Data de Criacao   ! 19/01/2021                                                                         !
+------------------+------------------------------------------------------------------------------------+
!Descricão         ! Gera Relatorio de analise importacao através de uma query usando filtros de datas, !
                   ! salva em xml e abre para o usuario. Usei Parambox com FWPreparedStatement para     !
                   ! tratar os parametros na tcquery. Com pequenas adaptações, pode ser automátizado    !
                   ! para enviar por email ou gerar em uma pasta, etc                                   !
+------------------+------------------------------------------------------------------------------------+
*/

user function GAIMPEX()
    local aArea := GetArea()
    local cArquivo := "C:\temp\Analise Importacao.xml"
    local cQuery := ""
    local dPerIni
    local dPerFim
    local oStatement := FWPreparedStatement():New()
    local aParamBox := {}
    local aResp := {}
    local nTam := 55
    local oFWMsExcel

    aadd(aParamBox, {1,"Da Data",cTod(""),"","MV_PAR01 <= date()","","",nTam,.t.})
    aadd(aParamBox, {1,"Ate a Data",date(),"","MV_PAR02 >= MV_PAR01","","",nTam,.t.})

    MsgInfo("Este programa vai gerar o relatorio de analise importacao")

    If ParamBox(aParamBox,"Relatorio de clientes",@aResp)
        dPerIni := aResp[1]
        dPerFim := aResp[2]
        cQuery := "SELECT B1_GRUPO, D1_COD, B1_DESC, D1_QUANT, CONVERT(DATE,D1_EMISSAO,102) AS DTEMISS, "
        cQuery += "SUBSTRING('JAN FEV MAR ABR MAI JUN JUL AGO SET OUT NOV DEZ ', (MONTH(D1_EMISSAO) * 4) - 3, 3) as MESEMISS "
        cQuery += "FROM "+RetSqlName("SD1")+" AS SD1 (NOLOCK) "
        cQuery +=  "LEFT JOIN SB1010 AS SB1 (NOLOCK) "
        cQuery += "ON B1_COD=D1_COD AND SB1.D_E_L_E_T_<>'*' "
        cQuery += "WHERE (D1_CF='3101' OR D1_CF='3102') "
        cQuery += "AND D1_EMISSAO >= ? AND D1_EMISSAO <= ? "
        cQuery += "AND SD1.D_E_L_E_T_<>'*' "
        cQuery += "GROUP BY B1_GRUPO, D1_COD, D1_QUANT,	B1_DESC, CONVERT(DATE,D1_EMISSAO,102), "
        cQuery += "SUBSTRING('JAN FEV MAR ABR MAI JUN JUL AGO SET OUT NOV DEZ ', (MONTH(D1_EMISSAO) * 4) - 3, 3) "
        cQuery += "ORDER BY	B1_GRUPO, D1_COD, D1_QUANT, B1_DESC, CONVERT(DATE,D1_EMISSAO,102), "
        cQuery += "SUBSTRING('JAN FEV MAR ABR MAI JUN JUL AGO SET OUT NOV DEZ ', (MONTH(D1_EMISSAO) * 4) - 3, 3)"
       
        oStatement:SetQuery(cQuery)
        oStatement:SetString(1,dTos(dPerIni))
        oStatement:SetString(2,dTos(dPerFim))
        cQuery := oStatement:GetFixQuery()

        TCQUERY cQuery ALIAS "TCQ" NEW

        oFWMsExcel := FWMSExcelEx():New() // Cria Objeto
        oFWMsExcel:AddworkSheet("Produtos") //Cria Aba
        oFWMsExcel:AddTable("Produtos", "Analise Importacao") //Cria tabela
        //Colunas
        oFWMsExcel:AddColumn("Produtos", "Analise Importacao","Grupo",1,1)
        oFWMsExcel:AddColumn("Produtos", "Analise Importacao","Codigo",1,1)
        oFWMsExcel:AddColumn("Produtos", "Analise Importacao","Descricao",1,1)
        oFWMsExcel:AddColumn("Produtos", "Analise Importacao","Emissao",1,1)
        oFWMsExcel:AddColumn("Produtos", "Analise Importacao","Mes",1,1)
        oFWMsExcel:AddColumn("Produtos", "Analise Importacao","Quantidade",1,2)
        //Linhas
        while ! (TCQ->(eof()))
            oFWMsExcel:AddRow("Produtos", "Analise Importacao",{;
                TCQ->B1_GRUPO,;
                TCQ->D1_COD,;
                TCQ->B1_DESC,;
                dToc(TCQ->DTEMISS),;
                TCQ->MESEMISS,;
                TCQ->D1_QUANT;
            })
            TCQ->(dbskip())
        enddo

        oFWMsExcel:Activate()
        oFWMsExcel:GetXMLFile(cArquivo)
        TCQ->(dbCloseArea())
        MsgInfo("Relatorio salvo em "+cArquivo ,"Relatorio Analise Importacao")
        ShellExecute("open", cArquivo, "", "", 1) //Abre o arquivo para o usuario
        
    endif
    RestArea(aArea)
return
