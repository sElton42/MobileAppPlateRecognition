%% CROP CARACTERES APENAS PARA CARROS

close all, clear, clc
%%
caminho_rd_lbl = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\dataset\Original\testing\labels_original\';
caminho_img_rd = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\dataset\Original\testing\images_original\';
caminho_img_wr = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\identificacao_caracteres\dataset\numbers\testing\images\';
caminho_lbl_wr = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\identificacao_caracteres\dataset\numbers\testing\labels\';

files = dir([caminho_rd_lbl, '*.txt']);
N = length(files);
ext = '.png';

for i = 1 : N
    %% abre arquivo e pega a linha com a posição da placa
    filename = files(i).name;
    fid = fopen([caminho_rd_lbl, filename]);
    
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
    placa_chars = fgetl(fid);
    fgetl(fid);
    
    placa_chars = split(placa_chars);
    placa_chars = placa_chars{2,1};
    
    fgetl(fid); fgetl(fid); fgetl(fid);
    for j = 1 : 4
        %% coleta x, y, w, h da linha de texto contendo a posição do caractere
        
        tline = fgetl(fid);
        linha_dividida = split(tline);
        x = linha_dividida{4}; y = linha_dividida{5}; w = linha_dividida{6}; h = linha_dividida{7};
        x = str2num(x); y = str2num(y); w = str2num(w); h = str2num(h);
        
        %% salva imagem após cropar o caractere
        
        filename_img = [filename(1:13), ext];
        I = imread( [caminho_img_rd , filename_img] );
        I2 = imcrop( I, [x, y, w, h] );
        %imshow(I2)
        
        auxsaveimg = [caminho_img_wr, 'L', num2str(j+3), '_', filename_img];
        auxsaveimg = convertCharsToStrings(auxsaveimg);
        imwrite(I2, auxsaveimg);
        
        %% prepara e salva o label do char
        
        c = placa_chars(1,j+4);
%         switch c
%             case 'A'
%                 c = 0;
%             case 'B'
%                 c = 1;
%             case 'C'
%                 c = 2;
%             case 'D'
%                 c = 3;
%             case 'E'
%                 c = 4;
%             case 'F'
%                 c = 5;
%             case 'G'
%                 c = 6;
%             case 'H'
%                 c = 7;
%             case 'I'
%                 c = 8;
%             case 'J'
%                 c = 9;
%             case 'K'
%                 c = 10;
%             case 'L'
%                 c = 11;
%             case 'M'
%                 c = 12;
%             case 'N'
%                 c = 13;
%             case 'O'
%                 c = 14;
%             case 'P'
%                 c = 15;
%             case 'Q'
%                 c = 16;
%             case 'R'
%                 c = 17;
%             case 'S'
%                 c = 18;
%             case 'T'
%                 c = 19;
%             case 'U'
%                 c = 20;
%             case 'V'
%                 c = 21;
%             case 'W'
%                 c = 22;
%             case 'X'
%                 c = 23;
%             case 'Y'
%                 c = 24;
%             case 'Z'
%                 c = 25;
%         end
        
        c = num2str(c);
        
        auxsavelbl = [caminho_lbl_wr, 'L', num2str(j+3), '_', filename];
        auxsavelbl = convertCharsToStrings(auxsavelbl);
        
        fidlbl = fopen(auxsavelbl, 'wt');
        fprintf(fidlbl,'%s', c);
        fclose(fidlbl);
    end
    fclose(fid);
end