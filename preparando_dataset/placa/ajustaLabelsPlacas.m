% ELTON S. S.
% CONVERTE OS LABELS ORIGINAIS NO FORMATO UTILIZADO PELO YOLO
close all, clear, clc

%% Definicao de constantes com os caminhos dos arquivos
% diretorio contendo labels originais
caminho_rd = '[PATH_LABELS_ORIGINAIS]';
% diretorio para salvar os labels convertidos
caminho_wr = '[PATH_LABELS_PROCESSADOS]';
% diretorio para ler as imagens pertinentes a cada label
caminho_imgOr_rd = '[PATH_IMAGENS_ORIGINAIS]';
% diretorio para salvar as imagens pertinentes a cada label apos marcacao da bounding boxes
caminho_imgOr_wr = '[PATH_IMAGENS_PROCESSADAS]';

%% Lendo os arquivos nos diretorios
files_img = dir([caminho_imgOr_rd, '*.png']); % Imagens
N_img = length(files_img); 
files = dir([caminho_rd, '*.txt']); % Labels
N = length(files);

%% Variaveis auxiliares
aux(1:N) = 1;
aux2 = 1;
aux3 = 1; 

for i = 1 : N
    
    % abre o arquivo
    filename = files(i).name;
    fid = fopen( [caminho_rd, filename] );
    tline = fgetl(fid); tline = fgetl(fid); % descarta linhas de texto
    % pega o tipo do veiculo
    tipo_veic = fgetl(fid);
    linha_dividida = split(tipo_veic);
    tipo_veic = linha_dividida{3};
    tipo_veic = convertCharsToStrings(tipo_veic);
    % pula p/ proxima iteracao se nao for um veiculo com placa com apenas uma linha de caracteres
    if(tipo_veic ~= 'car')
        fclose(fid);
        continue
    end
    % Descarta mais algumas linhas de texto
    for k = 1:5
        tline = fgetl(fid);
    end
    % coleta x, y, w, h da linha de texto contendo a posicao da placa
    linha_dividida = split(tline);
    x = linha_dividida{2}; y = linha_dividida{3}; w = linha_dividida{4}; h = linha_dividida{5};
    x = str2num(x); y = str2num(y); w = str2num(w); h = str2num(h);
    % Pega linha de texto contendo posicao do primeiro e do ultimo caractere
    tlinec = fgetl(fid);
    for k = 1:6
        tlinecf = fgetl(fid);
    end
    fclose(fid);
    % coleta x, y, w, h da linha de texto contendo a posicao do primeiro caractere
    linha_dividida = split(tlinec);
    xc = linha_dividida{4}; yc = linha_dividida{5}; wc = linha_dividida{6}; hc = linha_dividida{7};
    xc = str2num(xc); yc = str2num(yc); wc = str2num(wc); hc = str2num(hc);    
    % coleta x, y, w, h da linha de texto contendo a posicao do ultimo caractere
    linha_dividida = split(tlinecf);
    xf = linha_dividida{4}; yf = linha_dividida{5}; wf = linha_dividida{6}; hf = linha_dividida{7};
    xf = str2num(xf); yf = str2num(yf); wf = str2num(wf); hf = str2num(hf);
    % Se o primeiro caractere estiver entre os primeiros 432 pixels ou os
    % ultimos 432 pixels da imagens, descarta rotulo da imagem e pula 
    % para a proxima, pois a placa estara parcialmente ou totalmente recortada
    if(xc < 432)
       aux(i) = 0;
       continue
    elseif( (xf+wf) > 1487)
       aux(i) = 0;
       continue
    end
    % Corrige coordenadas da placa, caso caracteres estejam todos visiveis na imagem, mas um pedaco da placa nao esteja
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
    
    % salva o label no formato txt
    fid = fopen(filename2, 'wt');
    result = convertCharsToStrings(result);
    fprintf(fid, result);
    fclose(fid); 
end