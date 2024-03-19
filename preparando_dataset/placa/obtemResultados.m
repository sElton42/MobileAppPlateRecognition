%% Código para calcular a IoU entre caixas delimitadoras preditas e reais,
% calculando quantas placas o modelo acertou.
% ELTON S. S.
%
%%
% limpa workspace, editor e figuras
close all, clear, clc

% lê bounding boxes originais de cada placa
load resultado_labels_originais.mat
bboxes_org = resultado; clear resultado;

%% 
% Lê resultados das inferências feitas pelo modelo treinado
filepath = ['C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\',...
    'Desenvolvimento\DetecPlaca\matlab\codigos\placa\resultados_inferencia.txt'];
num_linhas = 1948; % no teste realizado

fid = fopen(filepath);
fgetl(fid); %% descarta primeira linha (header)

%% 
% Lê linha por linha, concatenando informações de cada uma e inserindo 
% em uma matriz

aux = 1; append = '';

for i = 1 : num_linhas
    line = fgetl(fid);
    if( line(1:7) == 'tensor(' )
        line_tensor = split(line, '[');
        
        if( numel( line_tensor ) >= 3 )
            line_tensor = split(line_tensor{3,1}, ',');
        else
            aux = aux + 1;
            continue
        end
        
        for k = 1 : numel(line_tensor)
            for kk = 1 : numel(line_tensor{k,1})
                if( line_tensor{k,1}(1,kk) ~= ' ' && line_tensor{k,1}(1,kk) ~= ']' )
                    append = [append, line_tensor{k,1}(1,kk)];
                end
            end
            resultado_img{1,k} = append;
            resultado_saida_modelo{aux, 1} = resultado_img;
            append = '';
        end
        aux = aux + 1;
    end
end

%% 
% Calcula a IoU

for k = 1 : 1800
    
end