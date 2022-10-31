function [BW, centroide]=preliminary_seed_Flair(Flair)
% centroide=0;
% thresh=multithresh(Flair,1); %N umbrales , N+1 niveles
% [Brain,index]=imquantize(Flair,thresh);
% Vol_r = regionprops3(Brain,'Volume');
% Vol_brain=sum(Vol_r.Volume);

thresh=multithresh(Flair,8); %N umbrales , N+1 niveles
[F,index]=imquantize(Flair,thresh);
MBin = [0,0,0,0,1,1,1,1,1]; %máscara binaria
BW = mat2gray(MBin(index));
props2=regionprops3(BW);            
vol= round(table2array(props2(1,'Volume'))); %volumen de la imagen binaria
k=5;
volmax=200000; %120000 150000 200000
volmin=8000;
if vol>volmax  % si vol es muy grande agrego 0 a la mascara Mbin en posicion k
    while vol>volmax %120000 200000
    MBin(k) = 0; 
    BW = mat2gray(MBin(index)); 
    props2=regionprops3(BW);
    vol= round(table2array(props2(1,'Volume'))); % volumen de la imagen binaria y si es muy grande agrego 0 a Mbin
    k=k+1;
    end
end
if vol<volmin
    k=5;
    while vol<volmin
        MBin(k) = 1;
        BW = mat2gray(MBin(index));
        props2=regionprops3(BW);
        vol= round(table2array(props2(1,'Volume'))); % volumen de la imagen binaria y si es muy grande agrego 0 a Mbin
        k=k-1;
    end
end
% BW = mat2gray(MBin(index));
% figure, imshow3D(BW);

% BW=Erosionar(BW);

% figure, imshow3D(BW);
CC = bwconncomp(BW,6); %connected components 
numPixels = cellfun(@numel,CC.PixelIdxList); %vector fila con la cantidad de pixeles de cada connected component 
[~,idx] = max(numPixels); % idx es el componente conectado (nro de columna del vector) donde está la mayor cantidad (biggest) de pixeles
%creo una imagen nueva solo con el objeto más grande
[x,y,z]=size(BW); 
BW=false(x,y,z); 
BW(CC.PixelIdxList{idx}) = 1; %en blanco solo el mayor componente conectado idx -  Edema
% BW=E;

% figure, imshow3D(BW);
%% Centroide del slice de mayor área
area=zeros(1,z);
for i=1 : z
    a=BW(:,:,i);
    area(i)= bwarea(a); %vector area con el area de cada slice
end
k=max(area); %mayor area del vector area
slice = find(area==k); %busco indice/slice donde está la mayor área

props= regionprops3(BW); %devuelve propiedades del volumen de Edema
centroide = round(table2array(props(1,'Centroid')));  %tomo el centroide y lo redondeo
centroide(3)=slice(1); %defino coordenada z del centroide como el slice de mayor área

end

