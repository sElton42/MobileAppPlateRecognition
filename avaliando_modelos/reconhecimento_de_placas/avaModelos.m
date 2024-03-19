%% AVALIA PERFORMANCE MODELO DE REC. DE PLACAS
close all, clear, clc

%%
deteccoes = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\avaModelos\placas\deteccoes_placas_testing.txt';
PATH_BBOXES_ORIG = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\placa\dataset\testing\labels\';
PATH_IMAGES_ORIG = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\placa\dataset\testing\images\';
PATH_IMAGES_SAVE = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\avaModelos\placas\debug_iou_less_0_75\';
PATH_PLACAS_SEG = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\avaModelos\geral\placas_segmentadas_151123\testing\images\';
debug = 1;

%% LÊ ARQUIVO DE DETECÇÃO E CALCULA IOU

fidDetec = fopen( deteccoes );
numAcertos = 0;
numImgsComPlacas = 0;
numImgsSemPlacas = 0;
iouThreshold = 0.95;
for k = 1  : 1440
%     if(k~=1)
%         for j = 1 : k-1
%             tline = fgetl(fidDetec);
%         end
%     end
    tline = fgetl(fidDetec);
    line_split = split(tline);
    
    nameFile = line_split{2,1}(1 : length(line_split{2,1})-2 );
    if( convertCharsToStrings( line_split{3,1} ) ~= "'N/A'," )
        yi = str2double(line_split{3,1});
        yf = str2double(line_split{4,1});
        xi = str2double(line_split{5,1});
        xf = str2double(line_split{6,1});
        if(yi <= 0), yi=1; end, if(yf > 1056), yf=1056; end, if(xi<=0), xi=1; end, if(xf>1056), xf=1056; end
        
        nameFileTxt = [ nameFile(2 : length(nameFile) - 4), '.txt' ];
        fid_lbl_orig = fopen( [PATH_BBOXES_ORIG nameFileTxt] );
        if(fid_lbl_orig ~= -1)
            tline = fgetl(fid_lbl_orig);
            line_split = split(tline);
            o_x_center = round(str2double(line_split{2,1}) * 1056);
            o_y_center = round(str2double(line_split{3,1}) * 1056);
            o_w = round(str2double(line_split{4,1}) * 1056);
            o_h = round(str2double(line_split{5,1}) * 1056);
            
            o_xi = round(o_x_center - o_w/2);
            o_xf = round(o_x_center + o_w/2);
            o_yi = round(o_y_center - o_h/2);
            o_yf = round(o_y_center + o_h/2);
            fclose(fid_lbl_orig);
            
            if(o_yi <= 0), o_yi=1; end, if(o_yf > 1056), o_yf=1056; end, if(o_xi<=0), o_xi=1; end, if(o_xf>1056), o_xf=1056; end
            
            %% CÁLCULO DO IOU
            
            xA = max(xi, o_xi);
            yA = max(yi, o_yi);
            xB = min(xf, o_xf);
            yB = min(yf, o_yf);
            
            interArea = (xB - xA + 1) * (yB - yA + 1);
            
            boxAArea = (xf - xi + 1) * (yf - yi + 1);
            boxBArea = (o_xf - o_xi + 1) * (o_yf - o_yi + 1);
            
            iou = interArea / (boxAArea + boxBArea - interArea);
            if(iou >= iouThreshold)
                numAcertos = numAcertos + 1;
            end
            
            numImgsComPlacas = numImgsComPlacas + 1;
            
            nameFile = nameFile(2:length(nameFile));
%             if(debug == 1 && iou < iouThreshold)
            if(debug == 1)
                imgOr = imread([PATH_IMAGES_ORIG nameFile]);
                imgDetec = imgOr;
                imgPlate = imgOr(yi:yf, xi:xf, 1:3);
                imgPlate = imresize(imgPlate, [80, 240]);
                imgPlate(241:256, 81:256, 1:3) = 0;
%                 imshow(imgPlate)
                imwrite(imgPlate, [PATH_PLACAS_SEG, 'detec_',nameFile]);
                
                % PLOTANDO A BOUNDING BOX OBTIDA VIA DETECÇÃO
                imgDetec(yi:yi+2, xi:xf, 1) = 255;
                imgDetec(yi:yi+2, xi:xf, 2) = 0;
                imgDetec(yi:yi+2, xi:xf, 3) = 0;
                imgDetec(yf-2:yf, xi:xf, 1) = 255;
                imgDetec(yf-2:yf, xi:xf, 2) = 0;
                imgDetec(yf-2:yf, xi:xf, 3) = 0;
                
                imgDetec(yi:yf, xi:xi+2, 1) = 255;
                imgDetec(yi:yf, xi:xi+2, 2) = 0;
                imgDetec(yi:yf, xi:xi+2, 3) = 0;
                imgDetec(yi:yf, xf-2:xf, 1) = 255;
                imgDetec(yi:yf, xf-2:xf, 2) = 0;
                imgDetec(yi:yf, xf-2:xf, 3) = 0;
                
%                 imwrite(imgDetec, [PATH_IMAGES_SAVE, 'detec_',nameFile])
                
                % PLOTANDO A BOUNDING BOX ORIGINAL
                imgOrBB = imgOr;
                
                imgOrBB(o_yi:o_yi+2, o_xi:o_xf, 1) = 0;
                imgOrBB(o_yi:o_yi+2, o_xi:o_xf, 2) = 255;
                imgOrBB(o_yi:o_yi+2, o_xi:o_xf, 3) = 0;
                imgOrBB(o_yf-2:o_yf, o_xi:o_xf, 1) = 0;
                imgOrBB(o_yf-2:o_yf, o_xi:o_xf, 2) = 255;
                imgOrBB(o_yf-2:o_yf, o_xi:o_xf, 3) = 0;
                
                imgOrBB(o_yi:o_yf, o_xi:o_xi+2, 1) = 0;
                imgOrBB(o_yi:o_yf, o_xi:o_xi+2, 2) = 255;
                imgOrBB(o_yi:o_yf, o_xi:o_xi+2, 3) = 0;
                imgOrBB(o_yi:o_yf, o_xf-2:o_xf, 1) = 0;
                imgOrBB(o_yi:o_yf, o_xf-2:o_xf, 2) = 255;
                imgOrBB(o_yi:o_yf, o_xf-2:o_xf, 3) = 0;
                
%                 imwrite(imgOrBB, [PATH_IMAGES_SAVE, 'orig_',nameFile])
                
            end
            
        end
    else
        numImgsSemPlacas = numImgsSemPlacas + 1;
    end
end
fclose(fidDetec);

taxa_de_acerto = numAcertos / numImgsComPlacas * 100