% ELTON S. S.
%% AVALIA PERFORMANCE GERAL DO SISTEMA
close all, clear, clc

%% CONSTANTES E VARIAVEIS AUXILIARES
deteccoes_letters = '[PATH_ARQUIVO_TXT_DETECCOES_LETRAS]';
deteccoes_numbers = '[PATH_ARQUIVO_TXT_DETECCOES_LETRAS]';
filename_letters = '[PATH_ARQUIVO_TXT_COM_NOMES_DOS_ARQUIVOS_DAS_IMAGENS_DAS_LETRAS]';
filename_numbers = '[PATH_ARQUIVO_TXT_COM_NOMES_DOS_ARQUIVOS_DAS_IMAGENS_DOS_NUMEROS]';

PATH_LABELS_ORIGINAIS = '[PATH_PASTA_LABELS_ORIGINAIS]';
files = dir([PATH_LABELS_ORIGINAIS, '*.txt']);
N = length(files);

debug = 0;
numAcertos = 0;
numAcertosLetters = 0;
numAcertosNumbers = 0;
%% REALIZA A EXTRACAO DAS IDENTIFICACOES

fidDetec = fopen( deteccoes_letters );

% LE ARQUIVO DE TEXTO E COLETA RESULTADOS
for k = 1  : 3756
    tline = fgetl(fidDetec);
    tline = erase(erase(tline, "["), "]");
    
    switch tline
        case '0'
            tline = 'A';
        case '1'
            tline = 'B';
        case '2'
            tline = 'C';
        case '3'
            tline = 'D';
        case '4'
            tline = 'E';
        case '5'
            tline = 'F';
        case '6'
            tline = 'G';
        case '7'
            tline = 'H';
        case '8'
            tline = 'I';
        case '9'
            tline = 'J';
        case '10'
            tline = 'K';
        case '11'
            tline = 'L';
        case '12'
            tline = 'M';
        case '13'
            tline = 'N';
        case '14'
            tline = 'O';
        case '15'
            tline = 'P';
        case '16'
            tline = 'Q';
        case '17'
            tline = 'R';
        case '18'
            tline = 'S';
        case '19'
            tline = 'T';
        case '20'
            tline = 'U';
        case '21'
            tline = 'V';
        case '22'
            tline = 'W';
        case '23'
            tline = 'X';
        case '24'
            tline = 'Y';
        case '25'
            tline = 'Z';
    end
    
    resultados_letters{k, 1} = tline;
end

fclose(fidDetec);

%% LEITURA DOS NUMEROS IDENTIFICADOS

fidDetec = fopen( deteccoes_numbers );

% LE ARQUIVO DE TEXTO E COLETA RESULTADOS
for k = 1  :  5008
    tline = fgetl(fidDetec);
    tline = erase(erase(tline, "["), "]");
    
    resultados_numbers{k, 1} = tline;
end

fclose(fidDetec);

%% MARCACAO NOME DOS ARQUIVOS

fidLetters = fopen( filename_letters );

% LE ARQUIVO DE TEXTO E COLETA RESULTADOS
for k = 1  : 3756
    tline = fgetl(fidDetec);
    resultados_letters{k, 2} = tline;
end

fclose(fidLetters);

fidNumbers = fopen( filename_numbers );

% LE ARQUIVO DE TEXTO E COLETA RESULTADOS
for k = 1  : 5008
    tline = fgetl(fidDetec);
    resultados_numbers{k, 2} = tline;
end

fclose(fidNumbers);

%% JUNTA DETECCOES

for k = 1 : 1252
    placa{k,1} = [resultados_letters{k, 1}, resultados_letters{k+1252, 1}, resultados_letters{k+(1252*2), 1}];
    placa{k,4} = resultados_letters{k, 2}(3:19);
end

for k = 1 : 1252
    placa{k,2} = [resultados_numbers{k, 1}, resultados_numbers{k+1252, 1}, resultados_numbers{k+(1252*2), 1}, resultados_numbers{k+(1252*3), 1}];
end

for k = 1 : 1252
    placa{k,3} = [placa{k,1},'-', placa{k,2}];
end

%% AVALIACAO

for k = 1 : 1252
    filename = placa{k,4};
    filename = [filename(1:length(filename)-3), 'txt'];
    fid = fopen([PATH_LABELS_ORIGINAIS, filename]);
    tline = fgetl(fid); tline = fgetl(fid); tipo_veic = fgetl(fid);
    fgetl(fid); fgetl(fid); fgetl(fid);
    tline = fgetl(fid);
    linha_dividida = split(tline);
    placa_original = linha_dividida{2,1};
    fclose(fid);
    if(placa_original == placa{k,3})
        numAcertos = numAcertos + 1;
    end
end