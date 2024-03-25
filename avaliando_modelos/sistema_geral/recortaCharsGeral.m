% ELTON S. S.
%% RECORTA CARACTERES OBTIDO APÓS SEGMENTAR AS PLACAS OBTIDAS PELO MODELO DE RECONHECIMENTO DE PLACAS
close all, clear, clc

%% CONSTANTES
deteccoes = '[PATH_CHARS_OBTIDOS]'; % FORMATO: [NUMERO_IMAGEM, NUMERO_CHAR, NOME_IMAGEM, YI, YF, XI, XF, CF]
PATH_IMAGES_SAVE = '[PATH_CHARS_SALVOS]';
PATH_IMAGES_READ = '[PATH_PLACAS_SEGMENTADAS]';

%% REALIZA A EXTRACAO DAS DETECCOES

fidDetec = fopen( deteccoes );
numberDetections = 1;
charcounter = 0;
% LE ARQUIVO DE TEXTO E COLETA RESULTADOS
for k = 1  : 19541
    
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
    
    
    coord{numberDetections,1} = actualNumberFile;
    coord{numberDetections,2} = yi;coord{numberDetections,3} = yf;coord{numberDetections,4} = xi;coord{numberDetections,5} = xf;
    coord{numberDetections,6} = cf; coord{numberDetections,7} = nameFile;
    
    coordaux(numberDetections,1) = actualNumberFile;
    coordaux(numberDetections,2) = yi;coordaux(numberDetections,3) = yf;coordaux(numberDetections,4) = xi;
    coordaux(numberDetections,5) = xf;
    coordaux(numberDetections,6) = cf;
    
    nameFileDetections(numberDetections,1) = convertCharsToStrings(nameFile);
    numberDetections = numberDetections+1;
end

fclose(fidDetec);

%% RECORTA CARACTERES

for k = 1 : 1287
    
    [rows, ~] = find( coordaux(:,1) == k );
    charsActualPlate = coordaux(rows,:);
    xi_chars = charsActualPlate(:, 4);
    [xi_chars_sorted, xi_index] = sort(xi_chars);
    
    [r,c] = size(charsActualPlate);
    
    if(r >= 7)
        plateFileName = coord{rows(1,1),7};
        I = imread([PATH_IMAGES_READ, 'detec_', plateFileName]);
        for j = 1 : 7
            charsActualPlateSorted(j,:) = charsActualPlate( xi_index(j), :);
            yi = charsActualPlateSorted(j,2);
            yf = charsActualPlateSorted(j,3);
            xi = charsActualPlateSorted(j,4);
            xf = charsActualPlateSorted(j,5);
            char = I( yi:yf, xi:xf, 1:3 );
            nameChar = [num2str(j), '_', plateFileName];
            imwrite(char, [PATH_IMAGES_SAVE, nameChar]);
        end
    end
end