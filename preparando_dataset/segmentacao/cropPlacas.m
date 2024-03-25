% ELTON S. S.
%% RECORTA IMAGENS DAS PLACAS

close all, clear, clc

% constantes:
caminho_rd_lbl = '[PATH_LEITURA_LABELS_ORIGINAIS]';
caminho_lbl_wr = '[PATH_ESCRITA_LABELS]';

caminho_img_rd = '[PATH_LEITURA_IMAGENS_ORIGINAIS]';
caminho_img_wr = '[PATH_ESCRITA_PLACAS]';

caminho_img_wr_debug = '[PATH_ESCRITA_IMAGENS_DEBUG]';

files = dir([caminho_rd_lbl, '*.txt']);
N = length(files);
ext = '.png';

for i = 1 : N
    %% abre arquivo e pega a linha com a posicao da placa
    filename = files(i).name;
    fid = fopen([caminho_rd_lbl, filename]);
    
    tline = fgetl(fid); tline = fgetl(fid); tipo_veic = fgetl(fid);
    linha_dividida = split(tipo_veic);
    tipo_veic = linha_dividida{3};
    tipo_veic = convertCharsToStrings(tipo_veic);
    % pula p/ proxima iteracao se nao for carro
    if(tipo_veic ~= 'car')
        fclose(fid);
        continue
    end
    
    fgetl(fid); fgetl(fid); fgetl(fid); fgetl(fid);
    tline = fgetl(fid);
    
    %% coleta x, y, w, h da linha de texto contendo a posicao da placa
    
    linha_dividida = split(tline);
    x = linha_dividida{2}; y = linha_dividida{3}; w = linha_dividida{4}; h = linha_dividida{5};
    x = str2num(x); y = str2num(y); w = str2num(w); h = str2num(h);
    
    %% salva imagem apos cropar a placa
    filename_img = [filename(1:13), ext];
    I = imread( [caminho_img_rd , filename_img] );
    I2 = imcrop( I, [x, y, w, h] );
    imgSize = size(I2); Ydim = imgSize(1); Xdim = imgSize(2);
    I2 = imresize(I2, [80, 240]);
    I3 = I2;
    I3(81:256, 241:256, :) = 0;
    auxsaveimg = [caminho_img_wr, filename_img];
    auxsaveimg = convertCharsToStrings(auxsaveimg);
    imwrite(I3, auxsaveimg);
    
    I4 = I3;
    
    %% prepara e salva o label da placa
    for k = 1 : 7
        linha_dividida = split(fgetl(fid));
        xi = str2num( linha_dividida{4,1} );
        yi = str2num( linha_dividida{5,1} );
        w = str2num( linha_dividida{6,1} );
        h = str2num( linha_dividida{7,1} );
    
        c(k,1) = xi - x;
        c(k,2) = yi - y;
        c(k,3) = c(k,1) + w;
        c(k,4) = c(k,2) + h;
        
        c(k,1) = ceil(c(k,1) * 240/Xdim) + 2;       % xi
        c(k,2) = ceil(c(k,2) * 80/Ydim) + 2;        % yi
        c(k,3) = ceil(c(k,3) * 240/Xdim) + 2;       % xf
        c(k,4) = ceil(c(k,4) * 80/Ydim) + 2;        % yf
        
        % DEBUG    
        I4( c(k,2) : c(k,4), c(k,1) : c(k,3) , 1) = 0;
        
        % CONVERTE P/ FORMATO DO YOLO
        cYolo(k,1) = ( c(k,1) + c(k,3) ) / 2 / 256; % xcenter
        cYolo(k,2) = ( c(k,2) + c(k,4) ) / 2 / 256; % ycenter
        cYolo(k,3) = ( c(k,3) - c(k,1) ) / 256;     % w
        cYolo(k,4) = ( c(k,4) - c(k,2) ) / 256;     % h
        
        %% terminar de converter p/ formato yolo
    
        format long
        label = '0';
        s = ' ';
        xn = num2str(cYolo(k,1), 5);
        yn = num2str(cYolo(k,2), 5);
        wn = num2str(cYolo(k,3), 5);
        hn = num2str(cYolo(k,4), 5);
        result{k} = [label, s, xn, s, yn, s, wn, s, hn];
    end
    % Salva imagem com os caracteres pintados de verde p/ analise
    auxsaveimg = [caminho_img_wr_debug, filename_img];
    auxsaveimg = convertCharsToStrings(auxsaveimg);
    imwrite(I4, auxsaveimg);
    fclose(fid);
    
    %%
    ext2 = '.txt';
    filen = filename(1:13);
    filename2 = [caminho_lbl_wr, filen, ext2];
    fid2 = fopen(filename2, 'wt');
    
    for k = 1 : 7    
        if (k == 7)
           fprintf(fid2,'%s', result{k});
        else
           fprintf(fid2,'%s\n', result{k}); 
        end
    end
    fclose(fid2);
end