function [BW]=Segmentation_WholeTumor(G,BWflair, centroide)
% centroide=0;
% thresh=multithresh(Flair,1); %N umbrales , N+1 niveles
% [Brain,index]=imquantize(Flair,thresh);
% Vol_r = regionprops3(Brain,'Volume');
% Vol_brain=sum(Vol_r.Volume);

thresh=multithresh(G,8); %N umbrales , N+1 niveles
[~,index]=imquantize(G,thresh);
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
L = labelmatrix(CC);
L2=L(:,:,centroide(3));

Area=BWflair(:,:,centroide(3));
Lc=BW(:,:,centroide(3));
Lc(Area==0)=0;
CC_2D=bwconncomp(Lc); %connected components 
L_2D = labelmatrix(CC_2D);

prop= regionprops(L_2D,'Area','PixelList');
AreaObj = find([prop.Area]==max([prop.Area]));
Lc(L_2D~=AreaObj)=0;
CoordObj=find(Lc~=0);
Obj=L2(CoordObj(1));


% Obj=L(centroide(1),centroide(2),centroide(3));
% 
% 
% if Obj==0
%     while Obj==0
%         centroide(1)=centroide(1)+1;
%         Obj=L(centroide(2),centroide(1),centroide(3));
%     end
% end
[x,y,z]=size(BW);
BW=logical(zeros(x,y,z));
BW(CC.PixelIdxList{Obj}) = 1;

% numPixels = cellfun(@numel,CC.PixelIdxList); %vector fila con la cantidad de pixeles de cada connected component 
% [biggest,idx] = max(numPixels); % idx es el componente conectado (nro de columna del vector) donde está la mayor cantidad (biggest) de pixeles
% %creo una imagen nueva solo con el objeto más grande
% [x,y,z]=size(BW); 
% E=logical(zeros(x,y,z)); 
% E(CC.PixelIdxList{idx}) = 1; %en blanco solo el mayor componente conectado idx -  Edema
% BW=E;

% figure, imshow3D(BW);
%% Centroide del slice de mayor área
% area=0;
% for i=1 : z
%     a=E(:,:,i);
%     area(i)= bwarea(a); %vector area con el area de cada slice
% end
% k=max(area); %mayor area del vector area
% slice = find(area==k); %busco indice/slice donde está la mayor área
% 
% props= regionprops3(E); %devuelve propiedades del volumen de Edema
% centroide = round(table2array(props(1,'Centroid')));  %tomo el centroide y lo redondeo
% centroide(3)=slice(1); %defino coordenada z del centroide como el slice de mayor área
end

%% Erosion 3D
% function [Iout_BW]=Erosionar(IBW)
%          Nh=zeros(7,7,4);
%          Nh(:,:,1)=[ 0   0   0   0   0   0   0; ...
%              0   0   0   1   0   0   0; ...
%              0   0   1   1   1   0   0;...
%              0   1   1   1   1   1   0; ...
%              0   0   1   1   1   0   0;...
%              0   0   0   1   0   0   0; ...
%              0   0   0   0   0   0   0;];
%          
%          Nh(:,:,2)=[ 0   0   0   0   0   0   0; ...
%              0   1   1   1   1   1   0; ...
%              0   1   1   1   1   1   0;...
%              0   1   1   1   1   1   0; ...
%              0   1   1   1   1   1   0;...
%              0   1   1   1   1   1   0; ...
%              0   0   0   0   0   0   0;];
%          
%          Nh(:,:,3)=[ 0   0   0   0   0   0   0; ...
%              0   1   1   1   1   1   0; ...
%              0   1   1   1   1   1   0;...
%              0   1   1   1   1   1   0; ...
%              0   1   1   1   1   1   0;...
%              0   1   1   1   1   1   0; ...
%              0   0   0   0   0   0   0;];
%          
%          Nh(:,:,4)=[ 0   0   0   0   0   0   0; ...
%              0   0   0   1   0   0   0; ...
%              0   0   1   1   1   0   0;...
%              0   1   1   1   1   1   0; ...
%              0   0   1   1   1   0   0;...
%              0   0   0   1   0   0   0; ...
%              0   0   0   0   0   0   0;];
%      
%      se=strel('arbitrary',Nh);
%      Iout_BW=imerode(IBW,se);
% end
