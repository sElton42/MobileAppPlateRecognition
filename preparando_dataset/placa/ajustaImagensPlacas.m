% ELTON S. S.
%% Codigo para recortar as imagens dos carros horizontalmente e verticalmente, obtendo imagens 1056 x 1056 pixels

close all, clear, clc
%%
% Define o diretorio com as imagens a serem lidas e processadas
caminho_img_rd = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\dataset\Original\validation\images_original\';
% Define o diretorio onde ira salvar as imagens processadas 
caminho_img_wr = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\matlab\codigos\dataset\validation\images\';
% Define o diretorio com os labels originais
caminho_lbl_rd = 'C:\Users\elton\Downloads\Estudos\Faculdade\TCC\TCC2\Desenvolvimento\DetecPlaca\dataset\Original\validation\labels_original\';

% le arquivos do diretorio de imagens
files_img = dir([caminho_img_rd, '*.png']);
N_img = length(files_img);

% le arquivos do diretorios de labels
files_lbl = dir([caminho_lbl_rd, '*.txt']);

for k = 1 : N_img
    filename_lbl = files_lbl(k).name;
    fid = fopen( [caminho_lbl_rd, filename_lbl ] );
    tline = fgetl(fid); tline = fgetl(fid); tipo_veic = fgetl(fid);
    linha_dividida = split(tipo_veic);
    tipo_veic = linha_dividida{3};
    tipo_veic = convertCharsToStrings(tipo_veic);
    % pula p/ proxima iteracao se nao for carro
    if(tipo_veic ~= 'car')
        fclose(fid);
        continue
    end
    fclose(fid);
    
    filename_img = files_img(k).name;    
    I = imread( [caminho_img_rd , filename_img] ); % le a imagem
    I2 = I(13:1068,432:1487,:);   % recorta a imagem
    auxsaveimg = [caminho_img_wr, filename_img];
    auxsaveimg = convertCharsToStrings(auxsaveimg);
    imwrite(I2, auxsaveimg); % salva a imagem recortada
end