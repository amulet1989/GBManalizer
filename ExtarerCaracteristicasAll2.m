function[bwClases,bwActivo,bwNecro,bwEdema,t]=ExtarerCaracteristicasAll2(bwGlioma3D,bwActivo3D,bwnecroEd3D,T1C,T2,T1,Flair,MdlRF,PS1)
% load NNnew100_iter1000_lmbda0_tanh_DataTend_60C_85S_500iter_NormCerebro_AreaGlioma_PixlesEyN
% load NNnewV2_N115_iter500_lmbda0_tanh_DataTend_60C_85S_NormCerebro_AreaGlioma_PixlesEyN

tic
%Hiperparametros
%Tamano de ventana (5X5 7X7 9X9 1X1)
m=3;%2,3,4,5
n=3;%2,3,4,5
%Bins y niveles de cuantizacion (16 32 64)
L=32;
% ROI analizado--> bwGlioma3D_r / bwnecroEd3D_r

%cargar datos

bwGlioma3D=double(bwGlioma3D);
bwActivo3D=double(bwActivo3D);
bwnecroEd3D=double(bwnecroEd3D);
% target=double(Target);



%% normalización (glioma G o cerebro T)
g1cN=Z_scoreN(T1C);%G1c T1c
g2N=Z_scoreN(T2);
g1N=Z_scoreN(T1);
gflairN=Z_scoreN(Flair);

%% Imagen base a analizar (Área-> Cerebro, Glioma, EyN)
min=g1cN(2,2,2);
% EyN
% g1cN(bwnecroEd3D~=1)=min;
% g2N(bwnecroEd3D~=1)=min;
% g1N(bwnecroEd3D~=1)=min;
% gflairN(bwnecroEd3D~=1)=min;

% Glioma
g1cN(bwGlioma3D~=1)=min;
g2N(bwGlioma3D~=1)=min;
g1N(bwGlioma3D~=1)=min;
gflairN(bwGlioma3D~=1)=min;

 %% Procesing without resampling 
%     bwGlioma3D_r=bwGlioma3D;
bwnecroEd3D_r=bwnecroEd3D;
g1c_r=g1cN;
g1_r=g1N;
g2_r=g2N;
gflair_r=gflairN;
    
%%     Target_r=target;
    
[ROIg1c_r,levels_g1c] = equalQuantization(g1cN,L);
[ROIg1_r,levels_g1] = equalQuantization(g1N,L);
[ROIg2_r,levels_g2] = equalQuantization(g2N,L);
[ROIgflair_r,levels_gflair] = equalQuantization(gflairN,L);

[X,Y,Z]=size(g1c_r);
contador=0;

BWclase_r=zeros(X,Y,Z);
% Target=double(Target);
% Flag=0;
for z=1:Z% 1:Z
    if ~isempty(find(bwnecroEd3D_r(:,:,z),1))%Pixeles a analizar
        TempBW=bwnecroEd3D_r(:,:,z);%bwGlioma3D_r / bwnecroEd3D_r
        TempG1c=g1c_r(:,:,z);
        TempG1=g1_r(:,:,z);
        TempG2=g2_r(:,:,z);
        TempFlair=gflair_r(:,:,z);
        
        TempR1c=ROIg1c_r(:,:,z);
        TempR1=ROIg1_r(:,:,z);
        TempR2=ROIg2_r(:,:,z);
        TempRflair=ROIgflair_r(:,:,z);
        
        %         TempTarget=Target_r(:,:,z);
        
        for x=1:X
            for y=1:Y
                if TempBW(x,y)==1
                    [Vg1c, Rg1c]=ventana(x,y,m,n,TempG1c, TempR1c);% cambiar caract. pixeles o estadísticas
                    [Vg1, Rg1]=ventana(x,y,m,n,TempG1, TempR1);
                    [Vg2, Rg2]=ventana(x,y,m,n,TempG2, TempR2);
                    [Vflair, Rflair]=ventana(x,y,m,n,TempFlair, TempRflair);
                    %extraer los rasgos a cada serie%,
                    %ExtraerRasgosPuros,ExtraerRasgos2, ExtraerRasgos
                    rasgosG1c=ExtraerRasgosAll(Vg1c, Rg1c,levels_g1c);
                    rasgosG1=ExtraerRasgosAll(Vg1, Rg1, levels_g1);
                    rasgosG2=ExtraerRasgosAll(Vg2, Rg2,levels_g2);
                    rasgosFlair=ExtraerRasgosAll(Vflair, Rflair,levels_gflair);
%                    tg=();
                    rasgos=[rasgosG1c rasgosG1 rasgosG2 rasgosFlair];
                    rasgos = rasgos';
                    rasgos = mapstd('apply',rasgos,PS1);%mapminmax
                    
                    coordenadas=[x; y; z];
                    %% Random Forest
                    if contador==0
                        Matriz_rasgos=rasgos;
                        Matriz_coordenadas=coordenadas;
                        contador=contador+1;
                    else
                        Matriz_rasgos=[Matriz_rasgos rasgos];
                        Matriz_coordenadas=[Matriz_coordenadas coordenadas];
                        contador=contador+1;
                    end
%                     
%                     clase=predict(mynet,rasgos');%mynet(rasgos')
% %                     [M,I] = max(clase);
%                     %I=predict(ctree,rasgos);
%                     
%                     if clase==2
%                         BWclase_r(x,y,z)=1;
%                     elseif clase==3
%                         BWclase_r(x,y,z)=2;
%                     elseif clase==4
%                         BWclase_r(x,y,z)=3;
%                     end
%                     rasgos=rasgos(:,[1   2   3   4    5    9  12   13   14   15   17    19    27    30   32    33     35     39     42     45     47    48    49    50    57     60]);
%                     rasgos = rasgos';
%                     rasgos = mapstd('apply',rasgos,PS1);%mapminmax
                   
                end
            end
        end
    end
    
end

%% Random Forest
 Matriz_clases=predict(MdlRF,Matriz_rasgos');%mynet->NN  MdlRF -> Random Forest
%  Matriz_clases=cell2mat(Matriz_clases);
%  Matriz_clases=str2num(Matriz_clases);
 Matriz_coordenadas=Matriz_coordenadas';
 
 for i=1:contador
     clase=Matriz_clases(i);
     x= Matriz_coordenadas(i,1);
     y= Matriz_coordenadas(i,2);
     z= Matriz_coordenadas(i,3);
     
     
     if clase==2
         BWclase_r(x,y,z)=1;
     elseif clase==3
         BWclase_r(x,y,z)=2;
     elseif clase==4
         BWclase_r(x,y,z)=3;
     end
     
 end         
%% pos-procesamiento
BWclase=BWclase_r;
% bwClases=BWclase_r;
% w=size(bwGlioma3D);
% bwNecro=zeros(w);
% bwEdema=zeros(w);
% bwActivo=zeros(w);
% 
% bwActivo(BWclase==3)=1;
% bwEdema(BWclase==2)=1;
% bwNecro(BWclase==1)=1;

bwClases=BWclase;
% figure('Name','ClasesRecuperado'), imshow3D(BWclase); % Clases
%% optimizar regiones

BWclase(bwGlioma3D==0) = 0;%bwnecroEd3D
% figure('Name','ClasesRefinadoNE'), imshow3D(BWclase); % Clases
% BWclase=BWclase + (bwnecroEd3D);
% BWclase(BWclase==1)=3;

bwNecro=zeros(X,Y,Z);
bwEdema=zeros(X,Y,Z);
bwActivo=bwActivo3D; %EyN->bwActivo3D / Glioma->zeros(X,Y,Z);%;

bwActivo(BWclase==3)=1;
bwEdema(BWclase==2)=1;
bwNecro(BWclase==1)=1;
% bwNecro=logical(bwNecro);
% InvT1C=im2double(imcomplement(T1C));
% InvT1C=imadjustn(InvT1C);

% figure('Name','bwNecro1'), imshow3D(bwNecro); 
% figure('Name','bwEdema1'), imshow3D(bwEdema);
% figure('Name','bwActivoOriginal'), imshow3D(bwActivo3D); 
% figure('Name','bwActivo1'), imshow3D(bwActivo); 
% bwNecro=activecontour(InvT1C, bwNecro, 1, 'Chan-Vese');
% se = strel('disk',1);
bwNecroActiv=bwNecro+bwActivo;
bwEdemaActiv=bwEdema+bwNecroActiv;
for i =1:Z
    if  ~isempty(find(bwGlioma3D(:,:,i),2))
%         bwNecro(:,:,i)=activecontour(InvT1C(:,:,i), bwNecro(:,:,i), 1, 'Chan-Vese');
%         bwNecro(:,:,i)=imdilate(bwNecro(:,:,i),se);
        bwNecroActiv(:,:,i)=imfill(bwNecroActiv(:,:,i),'holes');
%         bwActivo(:,:,i)=imfill(bwActivo(:,:,i),'holes');
        bwEdemaActiv(:,:,i)=imfill(bwEdemaActiv(:,:,i),'holes');
    end
end
bwNecro=logical(bwNecroActiv.*~bwActivo);
bwEdema=bwEdemaActiv.*~bwNecroActiv;
% figure('Name','bwNecro2'), imshow3D(bwNecro); 
% figure('Name','bwEdema2'), imshow3D(bwEdema); 
% figure('Name','bwActivo2'), imshow3D(bwActivo); 

% bwActivo=imfill(bwActivo,'holes');
bwActivo=logical(bwActivo.*~bwNecro);
bwEdema=logical(bwEdema.*~bwActivo);
bwEdema=logical(bwEdema.*~ bwNecro);
t=toc;
% similarityE = dice(logical(bwActivo),logical(bwNecro))
% similarityAE = dice(logical(bwActivo),logical(bwEdema))
% similarityEN = dice(logical(bwEdema),logical(bwNecro))
% end