% ELTON S. S.
% CONVERTE OS LABELS DO FORMATO ORIGINAL PARA O FORMATO UTILIZADO PELO YOLO E PINTA REGIÃO CONTENDO A PLACA VEICULAR EM CADA IMAGEM ORIGINAL
% SCRIPT PARA ANALISAR SE OS LABELS ESTÃO CORRETOS
close all, clear, clc

%% Definicao de constantes com os caminhos dos arquivos
% diretorio contendo labels originais
caminho_rd = '[PATH_LABELS_ORIGINAIS]';
% diretorio para ler as imagens pertinentes a cada label
caminho_imgOr_rd = '[PATH_IMAGENS_ORIGINAIS]';
% diretorio para salvar as imagens pertinentes a cada label apos marcacao da bboxes
caminho_imgOr_wr = '[PATH_IMAGENS_OR_WR]';

files_img = dir([caminho_imgOr_rd, '*.png']); % Imagens
N = length(files_img); 

for k = 1 : N
    filename_img = files_img(k).name;    
    I = imread( [caminho_imgOr_rd, filename_img] ); 
    filename_txt = filename_img(1:numel(filename_img)-3);
    filename_txt = [filename_txt, 'txt'];
    fid = fopen( [caminho_rd, filename_txt] );
    if(fid ~= -1)
        tline = fgetl(fid);
        % coleta x, y, w, h da linha de texto contendo a posicao da placa
        linha_dividida = split(tline);
        xcenter = linha_dividida{2}; ycenter = linha_dividida{3}; w = linha_dividida{4}; h = linha_dividida{5};
        xcenter = ceil(str2num(xcenter)*1056); ycenter = ceil(str2num(ycenter)*1056); w = floor(str2num(w)*1056);...
            h = floor(str2num(h)*1056);
        xi = ceil(xcenter - w/2); yi = ceil(ycenter - h/2); xf = floor(xcenter + w/2); yf = floor(ycenter + h/2);
        I2 = I;
        I2(yi:yf, xi:xf, 1) = 255;
        imwrite(I2, [caminho_imgOr_wr filename_img])
        fclose(fid); 
    else
        I2 = I;
        imwrite(I2, [caminho_imgOr_wr filename_img])
    end
end