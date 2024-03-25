% ELTON S. S.
%% AVALIA PERFORMANCE MODELO DE RECONHECIMENTO DE SEGMENTACAO
close all, clear, clc

%% CONSTANTES
% CAMINHO CONTENDO CARACTERES SEGMENTADOS NO FORMATO [NUMERO_DA_IMAGEM, NUMERO_DO_CARACTERE, NOME_IMAGEM, YI, YF, XI, XF, CF]
deteccoes = '[PATH_ARQUIVO_TXT_DETECCOES]';
% CAMINHO PARA A PASTA CONTENDO OS LABELS ORIGINAIS DE CADA IMAGEM
PATH_BBOXES_ORIG = '[PATH_LABELS_ORIGINAIS]';
% CAMINHO PARA A PASTA CONTENDO AS IMAGENS ORIGINAIS
PATH_IMAGES_ORIG = '[PATH_IMAGENS_ORIGINAIS]';
% CAMINHO PARA SALVAR AS IMAGENS CUJA A DETECÇÃO DO CARACTERE OBTEVE CONFIANÇA MENOR DO QUE O IOU THRESHOLD
PATH_IMAGES_SAVE_DEBUG = '[PATH_DEBUG]';
debug = 0;

%% REALIZA A EXTRACAO DAS DETECCOES
fidDetec = fopen( deteccoes );
numAcertos = 0;
iouThreshold = 0.80;
numberDetections = 1;
charcounter = 0;
% LE ARQUIVO DE TEXTO E COLETA RESULTADOS
for k = 1  : 21700
    
    tline = fgetl(fidDetec);
    line_split = split(tline);
    nameFile = line_split{3,1}(2 : length(line_split{3,1})-2 );
    actualNumberFile = str2double(erase(erase(line_split{1,1}, "["), ","));
    
    % PEGA COORDENADAS
    yi = str2double(line_split{4,1});
    yf = str2double(line_split{5,1});
    xi = str2double(line_split{6,1});
    xf = str2double(line_split{7,1});
    cf = str2double( erase( line_split{8,1}, "]" ) );
    if(xi>240)
        continue
    elseif(xf>240)
        continue
    elseif(yi>80)
        continue
    elseif(yf>80)
        continue
    end
    if(yi <= 0), yi=1; end, if(xi<=0), xi=1; end
    
    if(cf < 0.75 && charcounter >= 7)
        charcounter = 0;
        continue
    end
    
    if(k == 1)
        previosNumberFile = 1;
    end
    
    if(actualNumberFile == previosNumberFile)
        charcounter = charcounter + 1;
    else
        charcounter = 1;
        previosNumberFile = actualNumberFile;
    end
    
    
    coord(numberDetections,1) = actualNumberFile;
    coord(numberDetections,2) = yi;coord(numberDetections,3) = yf;coord(numberDetections,4) = xi;coord(numberDetections,5) = xf;
    coord(numberDetections,6) = cf;
    nameFileDetections(numberDetections,1) = convertCharsToStrings(nameFile);
    numberDetections = numberDetections+1;
end

fclose(fidDetec);

%% REORGANIZA RESULTADOS, PLOTA E VERIFICA A QUANTIDADE DE ACERTOS DO MODELO DE SEGMENTACAO

files_img = dir([PATH_IMAGES_ORIG, '*.png']);

for k = 1 : 1440
    imFilename = files_img(k).name;
    imgOr = imread( [PATH_IMAGES_ORIG , imFilename] );
    imgDetec = imgOr;
    
    [rows, ~] = find( coord(:,1) == k );
    charsActualPlate = coord(rows,:);
    xi_chars = charsActualPlate(:, 4);
    [xi_chars_sorted, xi_index] = sort(xi_chars);
    
    [r,c] = size(charsActualPlate);
    
    nameFileTxt = [ imFilename(1 : length(imFilename) - 4), '.txt' ];
    fid_lbl_orig = fopen( [PATH_BBOXES_ORIG nameFileTxt] );
    sumAcertosChar = 0;
    if(r >= 7)
        for j = 1 : 7
            charsActualPlateSorted(j,:) = charsActualPlate( xi_index(j), :);
            yi = charsActualPlateSorted(j,2);
            yf = charsActualPlateSorted(j,3);
            xi = charsActualPlateSorted(j,4);
            xf = charsActualPlateSorted(j,5);
            wd = xf-xi; hd = yf-yi;
            
            %% CALCULA O IOU
            
            if(fid_lbl_orig ~= -1)
                tline = fgetl(fid_lbl_orig);
                line_split = split(tline);
                o_x_center = round(str2double(line_split{2,1}) * 256);
                o_y_center = round(str2double(line_split{3,1}) * 256);
                o_w = round(str2double(line_split{4,1}) * 256);
                o_h = round(str2double(line_split{5,1}) * 256);
                
                o_xi = round(o_x_center - o_w/2);
                o_xf = round(o_x_center + o_w/2);
                o_yi = round(o_y_center - o_h/2);
                o_yf = round(o_y_center + o_h/2);
                o_w = o_xf - o_xi; o_h = o_yf - o_yi;
                if(o_yi <= 0), o_yi=1; end, if(o_yf > 256), o_yf=256; end, if(o_xi<=0), o_xi=1; end, if(o_xf>256), o_xf=256; end
                
                iou = calcIou(yi,yf,xi,xf,o_yi,o_yf,o_xi,o_xf)
                
                if(iou >= iouThreshold)
                    sumAcertosChar = sumAcertosChar + 1;
                end
                
                % PLOTANDO A BOUNDING BOX OBTIDA VIA DETECCAO
                imgDetec(yi:yi+1, xi:xf, 1) = 255;
                imgDetec(yi:yi+1, xi:xf, 2) = 0;
                imgDetec(yi:yi+1, xi:xf, 3) = 0;
                imgDetec(yf-1:yf, xi:xf, 1) = 255;
                imgDetec(yf-1:yf, xi:xf, 2) = 0;
                imgDetec(yf-1:yf, xi:xf, 3) = 0;
                
                imgDetec(yi:yf, xi:xi+1, 1) = 255;
                imgDetec(yi:yf, xi:xi+1, 2) = 0;
                imgDetec(yi:yf, xi:xi+1, 3) = 0;
                imgDetec(yi:yf, xf-1:xf, 1) = 255;
                imgDetec(yi:yf, xf-1:xf, 2) = 0;
                imgDetec(yi:yf, xf-1:xf, 3) = 0;
                imshow(imgDetec)
            end
        end
    end
    if(sumAcertosChar == 7)
        numAcertos = numAcertos + 1;
    elseif(debug == 1)
        imwrite(imgDetec, [PATH_IMAGES_SAVE_DEBUG, 'detec_',imFilename])
    end
    fclose(fid_lbl_orig);
end

numAcertos = numAcertos/1440 * 100