% CONVERSOR DE LABELS UFPR-ALPR -> FORMATO UTILIZADO PELO YOLO
close all, clear, clc

%% Defini��o de constantes com os caminhos dos arquivos
% diret�rio contendo labels originais
caminho_rd = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\dataset\Original\validation\labels_original\';
% diret�rios para salvar os labels convertidos
caminho_wr = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\dataset\validation\labels\';
% diret�rio para ler as imagens pertinentes a cada label
caminho_imgOr_rd = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\dataset\validation\images\';
% diret�rio para salvar as imagens pertinentes a cada label ap�s marca��o
% da bboxes
caminho_imgOr_wr = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\dataset_bboxes_labels\validation\images\';

%% Lendo os arquivos nos diret�rios
files_img = dir([caminho_imgOr_rd, '*.png']); % Imagens
N_img = length(files_img); 
files = dir([caminho_rd, '*.txt']); % Labels
N = length(files);

%% Vari�veis auxiliares
aux(1:N) = 1;
aux2 = 1;
aux3 = 1; 

for i = 1 : N
    
    % abre o arquivo
    filename = files(i).name;
    fid = fopen( [caminho_rd, filename] );
    tline = fgetl(fid); tline = fgetl(fid); % descarta linhas de texto
    % pega o tipo do ve�culo
    tipo_veic = fgetl(fid);
    linha_dividida = split(tipo_veic);
    tipo_veic = linha_dividida{3};
    tipo_veic = convertCharsToStrings(tipo_veic);
    % pula p/ pr�xima itera��o se n�o for um ve�culo com placa com apenas
    % uma linha de caracteres
    if(tipo_veic ~= 'car')
        fclose(fid);
        continue
    end
    % Descarta mais algumas linhas de texto
    for k = 1:5
        tline = fgetl(fid);
    end
    % coleta x, y, w, h da linha de texto contendo a posi��o da placa
    linha_dividida = split(tline);
    x = linha_dividida{2}; y = linha_dividida{3}; w = linha_dividida{4}; h = linha_dividida{5};
    x = str2num(x); y = str2num(y); w = str2num(w); h = str2num(h);
    % Pega linha de texto contendo posi��o do primeiro e do �ltimo 
    % caractere
    tlinec = fgetl(fid);
    for k = 1:6
        tlinecf = fgetl(fid);
    end
    fclose(fid);
    % coleta x, y, w, h da linha de texto contendo a posi��o do primeiro
    % caractere
    linha_dividida = split(tlinec);
    xc = linha_dividida{4}; yc = linha_dividida{5}; wc = linha_dividida{6}; hc = linha_dividida{7};
    xc = str2num(xc); yc = str2num(yc); wc = str2num(wc); hc = str2num(hc);    
    % coleta x, y, w, h da linha de texto contendo a posi��o do �ltimo
    % caractere
    linha_dividida = split(tlinecf);
    xf = linha_dividida{4}; yf = linha_dividida{5}; wf = linha_dividida{6}; hf = linha_dividida{7};
    xf = str2num(xf); yf = str2num(yf); wf = str2num(wf); hf = str2num(hf);
    % Se o primeiro caractere estiver entre os primeiros 432 pixels ou os
    % �ltimos 432 pixels da imagens, descarta r�tulo da imagem e pula 
    % para a pr�xima
    if(xc < 432)
       aux(i) = 0;
       continue
    elseif( (xf+wf) > 1487)
       aux(i) = 0;
       continue
    end
    % Corrige coordenadas da placa, caso caracteres estejam todos vis�veis
    % na imagem, mas um peda�o da placa n�o esteja
    if(x < 432)
        x = xc;
    elseif( (x+w) > 1487)
        x = xf;
        w = wf;
    end
    % Armazena as coordenadas da placa
    plate{i,1} = [y-12, y+h-12, x-432, x+w-432];
    if( (x-432) <= 0 ), plate{i,1} = [y-12, y+h-12, 1, x+w-432]; end
    if( (x+w-432) >= 1056 ), plate{i,1} = [y-12, y+h-12, x-432, 1056]; end
    
    %% converte as coordenadas p/ formato yolo    
    format long
    xn = (x-432+x-432+w) / 2 / 1056; yn = (y-12+y-12+h) / 2 / 1056;
    wn = w / 1056; hn = h / 1056;
    label = '0';
    if(xn < 0), xn = 0; end
    xn = num2str(xn,6); yn = num2str(yn,6); wn = num2str(wn,5); hn = num2str(hn,5);
    s = ' ';
    result = [label, s, xn, s, yn, s, wn, s, hn];
    
    %% salva o resultado em um arquivo de texto
    
    % define caminho para salvar o label
    ext = '.txt';
    filen = filename(1:13);
    filename2 = [caminho_wr, filen, ext];    
    aux2 = aux2 + 1;
    % l� a imagem pertinente �quele label e plota ela juntamente com um
    % ret�ngulo vermelho obtido com as coordenadas da placa
%     filename_img = files_img(i).name;
%     plate{i,2} = filename_img;
%     imgOr = imread( [caminho_imgOr_rd, filename_img] ); 
%     figure, hold on
%     imshow(imgOr);
%     rectangle('Position',[plate{i,1}(1,3), plate{i,1}(1,1), ...
%         plate{i,1}(1,4)-plate{i,1}(1,3), plate{i,1}(1,2)-plate{i,1}(1,1)],'EdgeColor','r', 'LineWidth', 2);
%     saveas(gcf, [ caminho_imgOr_wr filename_img ])
%     close all
    % salva o label no formato txt
    fid = fopen(filename2, 'wt');
    result = convertCharsToStrings(result);
    fprintf(fid, result);
    fclose(fid); 
end