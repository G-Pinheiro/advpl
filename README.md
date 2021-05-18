# advpl
Customizações em ADVPL
Neste repositório, disponibilizarei algumas customizações de solicitações reais

1 GFGLCSV - Importa CSV. User function usada internamente para efetuar a leitura de um relatório das dimensões dos produtos (unitario e caixa master) em csv e importar para as tabelas SB1 e SB5. O relatório a importar deve possuir as colunas com o mesmo nome das colunas da tabela.
Sugestão: Criar um verificador para checar a existencia da pasta temp para cria-la e interface para usuários.

2 GAIMPEX - Gera Relatorio através de uma query usando filtros de datas, salva em xml e abre para o usuario. Usei Parambox com FWPreparedStatement para
tratar os parametros na tcquery. Com pequenas adaptações, pode ser automátizado, enviar por email, gerar em uma pasta, etc.
É possível deixa-lo genérico e transforma-lo em uma pequena e específica função genérica.
