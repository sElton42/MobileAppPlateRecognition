%% AVALIA PERFORMANCE MODELO DE REC. DE CARACTERES
close all, clear, clc

%% CONSTANTES E VARIÁVEIS AUXILIARES
deteccoes_letters = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\avaModelos\caracteres\resultados_121123_letters.txt';
deteccoes_numbers = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\avaModelos\caracteres\resultados_121123_numbers.txt';

PATH_LABELS_ORIGINAIS = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\dataset\Original\testing\labels_original\';
files = dir([PATH_LABELS_ORIGINAIS, '*.txt']);
N = length(files);

debug = 0;
numAcertos = 0;
numAcertosLetters = 0;
numAcertosNumbers = 0;
%% REALIZA A EXTRAÇÃO DAS IDENTIFICAÇÕES

fidDetec = fopen( deteccoes_letters );

% LÊ ARQUIVO DE TEXTO E COLETA RESULTADOS
for k = 1  : 4320
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

for k = 1 : 1440
    placa{k,1} = [resultados_letters{k, 1}, resultados_letters{k+1440, 1}, resultados_letters{k+2880, 1}];
end

%% LEITURA DOS NÚMEROS IDENTIFICADOS

fidDetec = fopen( deteccoes_numbers );

% LÊ ARQUIVO DE TEXTO E COLETA RESULTADOS
for k = 1  : 5760
    tline = fgetl(fidDetec);
    tline = erase(erase(tline, "["), "]");
    
    resultados_numbers{k, 1} = tline;
end

fclose(fidDetec);

for k = 1 : 1440
    placa{k,2} = [resultados_numbers{k, 1}, resultados_numbers{k+1440, 1}, resultados_numbers{k+2880, 1}, resultados_numbers{k+4320, 1}];
end

for k = 1 : 1440
    placa{k,3} = [placa{k,1}, '-', placa{k,2}];
end

%% LEITURA DOS LABELS ORIGINAIS

varaux = 1;
for k = 1 : 1800
    filename = files(k).name;
    fid = fopen([PATH_LABELS_ORIGINAIS, filename]);
    
    tline = fgetl(fid); tline = fgetl(fid); tipo_veic = fgetl(fid);
    linha_dividida = split(tipo_veic);
    tipo_veic = linha_dividida{3};
    tipo_veic = convertCharsToStrings(tipo_veic);
    % pula p/ próxima iteração se não for carro
    if(tipo_veic ~= 'car')
        fclose(fid);
        continue
    end
    
    fgetl(fid); fgetl(fid); fgetl(fid);
    tline = fgetl(fid);
    linha_dividida = split(tline);
    placa_original{varaux, 1} = linha_dividida{2,1};
    varaux = varaux + 1;
    fclose(fid);
end

for k = 1 : 1440
   if( sum(placa_original{k, 1} == placa{k,3} ) == 8 ) 
       numAcertos = numAcertos + 1;
   end
   if( sum(placa_original{k, 1}(1:3) == placa{k,3}(1:3) ) == 3 ) 
       numAcertosLetters = numAcertosLetters + 1;
   end
   if( sum(placa_original{k, 1}(5:8) == placa{k,3}(5:8) ) == 4 )
       numAcertosNumbers = numAcertosNumbers + 1;
   end
end

numAcertos / 1440 * 100
numAcertosLetters / 1440 * 100
numAcertosNumbers / 1440 * 100

%%

linha = 1;
placa_deteccoes = [];
aux = 1;
for k = 1 : (1440*4)
    placa_deteccoes = [placa_deteccoes, placa{linha,2}(aux)];
    aux = aux + 1;
    if(aux > 4)
        aux = 1;
        linha = linha + 1;
    end
end
%%
linha = 1;
placa_chars_orig = [];
aux = 5;
for k = 1 : (1440*4)
    placa_chars_orig = [placa_chars_orig, placa_original{linha,1}(aux)];
    aux = aux + 1;
    if(aux > 8)
        aux = 5;
        linha = linha + 1;
    end
end

%%

placa_deteccoes = placa_deteccoes';
placa_chars_orig = placa_chars_orig';

% [C, Order] = confusionmat(placa_chars_orig, placa_deteccoes, 'Order', {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'} );
[C, Order] = confusionmat(placa_chars_orig, placa_deteccoes, 'Order', {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'} );
confusionchart(C, Order)

% title('Confusion Matrix', 'FontSize', 16);
% xlabel('Predicted Class', 'FontSize', 14);
% ylabel('True Class', 'FontSize', 14);