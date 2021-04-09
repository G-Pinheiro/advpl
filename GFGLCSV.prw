#include "protheus.ch"
#include "totvs.ch"
#include "fileio.ch"

/*
+------------------+---------------------------------------------------------+
!Autor             !    Giulliano Pinheiro 	                                 !
+------------------+---------------------------------------------------------+
!Data de Criacao   !    01/04/2021                                           !
+------------------+---------------------------------------------------------+
!Descrição         !    Programa para efetuar a leitura do relatório das     !
!                  !    dimensões dos produtos                               !
+------------------+---------------------------------------------------------+
!Observação        !                                                         !
+------------------+---------------------------------------------------------+
*/

user function GFGLCSV()

    local cArquivo              // Captura arquivo CSV selecionado
    local nHandle := 0          // Trabalha com o CSV Recebido
    local nHandle2 := 0         // Trabalha na geração de txt de codigos não encontrados
    local lPrimLinha := .T.     // Verificação de cabeçalho
    local aCampos := []         // Array cabeçalho
    local aDados := array(0)    // Array com os dados
    local cLinha                // Utilizado para leitura de linha por linha
    local nfor                  // Utilizado para Laço por linha
    local nforh                 // Utilizado para Laço por linha
    local aCodne := array(0)    // Array para codigos não encontrados
    local cLocal :=             'c:\temp\Codigos Nao Encontrados.csv'  // Local para salvar csv com codigos não encontrados
    local nQtCod := 0           // Conta quantos codigos foram importados
    local nQtCodne := 0         // Conta quantos codigos nao foram importados
    local nQtTotal := 0         // Conta total de codigos lidos
    local nDfor
    local nDfor2

    // Seleção do arquivo CSV e leitura
    cArquivo := cGetFile( 'Arquivo CSV|*.csv',;                   //[ cMascara], 
                         'Selecao de Arquivos',;                  //[ cTitulo], 
                         0,;                                      //[ nMascpadrao], 
                         'C:\Temp\',;                             //[ cDirinicial], 
                         .T.,;                                    //[ lSalvar], 
                         GETF_LOCALHARD  + GETF_NETWORKDRIVE,;    //[ nOpcoes], 
                         .F.)                                     //[ lArvore]


    nHandle := FT_FUSE(cArquivo)

    if nHandle = -1
        alert("Erro de leitura: "+cValToChar(ferror())+ ' Consulte a lista de erros no TDN.')
        return
    endif

    FT_FGOTOP()

    while ! FT_FEOF()
        cLinha := FT_FREADLN()
        if lPrimLinha   // Se for primeira linha, cria cabeçalho.
            aCampos := Separa(cLinha,';',.T.)
            lPrimLinha := .F.
        else
            AADD(aDados,Separa(cLinha,";",.T.)) // Foi necessario declarar a variavel Adados := Array(0), utilizando [] não funcionou
        endif
        FT_FSKIP()
    enddo
    fclose(nHandle)

    // Preenche com '' os campos zerados do aDados
    for nDfor := 1 to len(aDados) // for linha
        for nDfor2 := 3 to len(aDados[nDfor]) // for coluna
            if aDados[nDfor,nDfor2] = '0'
                aDados[nDfor,nDfor2] = ''
            endif
        next
    next

    // SB5010
    //Compara com arquivo do BD e atualiza os valores, cria txt com os codigos não encontrados.
    Begin Transaction
        AADD(aCodne, {'Codigo', 'Motivo'}) // Cria cabeçalho para codigos não encontrados ou inconsistentes
        for nfor := 1 to len(aDados) // Laço Linha
            dbSelectArea("SB5")
            SB5->(dbSetOrder(1)) //B5_FILIAL+B5_COD
            SB5->(dbGoTop())
            if SB5->(dbSeek(xFilial('SB5')+aDados[nfor,2])) // Inclui dados nas colunas
                Reclock("SB5",.F.) // F = Alteração     T = Inclusão
                // Checa se o valor do CSV está zerado ou vazio e caso sim, não preenche a tabela
                IIF(!aDados[nfor,6] = '', SB5->B5_COMPR   :=  val(aDados[nfor,6]),;
                AADD(aCodne, {aDados[nfor,2], 'Valor inconsistente B5_COMPR'}))
                IIF(!aDados[nfor,7] = '', SB5->B5_LARG    :=  Val(aDados[nfor,7]),;
                AADD(aCodne, {aDados[nfor,2], 'Valor inconsistente B5_LARG'}))
                IIF(!aDados[nfor,8] = '', SB5->B5_ESPESS  :=  Val(aDados[nfor,8]),;
                AADD(aCodne, {aDados[nfor,2], 'Valor inconsistente B5_ESPESS'}))
                nQtCod += 1
            else
                AADD(aCodne, {aDados[nfor,2], 'Codigo nao encontrado'})
                nQtCodne += 1
            endif
            SB5->(dbskip())

        next
        MsUnlock()
        SB5->(DBCloseArea())
    End Transaction

    //SB1010
    //Atualiza as colunas B5_FILIAL E B5_COD para atender a SB1
    aCampos[1] := 'B1_FILIAL'
    aCampos[2] := 'B1_COD'

    Begin Transaction

        for nfor := 1 to len(aDados) // Laço Linha
            dbSelectArea("SB1")
            SB1->(dbSetOrder(1)) //B1_FILIAL+B1_COD
            SB1->(dbGoTop())
            if SB1->(dbSeek(xFilial('SB1')+aDados[nfor,2])) // Inclui dados nas colunas
                Reclock("SB1",.F.) // F = Alteração     T = Inclusão
                // Checa se o valor do CSV está zerado ou vazio e caso sim, não preenche a tabela
                IIF(!aDados[nfor,3] = '', SB1->B1_COMP03  :=  val(aDados[nfor,3]),;
                AADD(aCodne, {aDados[nfor,2], 'Valor inconsistente B1_COMP03'}))
                IIF(!aDados[nfor,4] = '', SB1->B1_LARG03  :=  Val(aDados[nfor,4]),;
                AADD(aCodne, {aDados[nfor,2], 'Valor inconsistente B1_LARG03'}))
                IIF(!aDados[nfor,5] = '', SB1->B1_ALTU3   :=  Val(aDados[nfor,5]),;
                AADD(aCodne, {aDados[nfor,2], 'Valor inconsistente B1_ALTU3'}))
            endif
            SB1->(dbskip())
        next
        MsUnlock()
        SB1->(DBCloseArea())
    End Transaction

    // Se o array aCodne for preenchido Utiliza o array para gravar os codigos não encontrados em um arquivo txt
    if len(aCodne) > 1
        nHandle2 := fcreate(cLocal, FC_NORMAL)
        if nHandle2 < 0
            alert("Erro de leitura: "+cValToChar(ferror())+ 'Consulte a lista de erros no TDN.')
        else
            for nforh := 1 to len(aCodne) // Laço Linha
                fwrite(nHandle2, aCodne[nforh,1]+';'+aCodne[nforh,2])
                fwrite(nHandle2, CRLF)
            next
        endif
        fclose(nHandle2)
        nQtTotal := nQtCod + nQtCodne
        MsgInfo("Registros importados, alguns codigos não foram encontrados"+Chr(13)+Chr(10)+;
        " ou houve conflito entre valores e foram salvos em ";
        +Chr(13)+Chr(10)+upper(cLocal);
        +Chr(13)+Chr(10)+"Cods processados: "+cValToChar(nQtCod);
        +Chr(13)+Chr(10)+"Cods nao encontrados: "+cValToChar(nQtCodne);
        +Chr(13)+Chr(10)+"Total lidos: "+cValToChar(nQtTotal),"Concluido")
    else
        MsgInfo("Registros importados com sucesso","Concluido")
    endif

return
