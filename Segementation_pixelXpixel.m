function[bwClases,bwActivo,bwNecro,bwEdema,t]=Segementation_pixelXpixel(bwGlioma3D,bwActivo3D,bwnecroEd3D,T1C,T2,T1,Flair,MdlRF,PS1)

% load NNnew80_iter1000_lmbda0_tanh_DataTend_30C_85S_500iter_NormCerebro_AreaGlioma_PixlesEyN
% load NeuralNetworkFile_80N_1000iter_tanh_30features
tic

% Hyperparameters
m=3;%window size m=n=3 -> 7X7 
n=3;%
%Bins and quantization levels 
L=32;%Quantization levels

%cargar datos
bwGlioma3D=double(bwGlioma3D);
bwActivo3D=double(bwActivo3D);
bwnecroEd3D=double(bwnecroEd3D);
% target=double(Target);


%% Zscore normalization
g1cN=Z_scoreN(T1C);%G1c T1c
g2N=Z_scoreN(T2);
g1N=Z_scoreN(T1);
gflairN=Z_scoreN(Flair);

%% 
min=g1cN(2,2,2);

% Glioma
g1cN(bwGlioma3D~=1)=min;
g2N(bwGlioma3D~=1)=min;
g1N(bwGlioma3D~=1)=min;
gflairN(bwGlioma3D~=1)=min;


%% Procesing without resampling 
    bwGlioma3D_r=bwGlioma3D;
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
BWclase_r=zeros(X,Y,Z);
contador=0;

for z=1:Z
    if ~isempty(find(bwnecroEd3D_r(:,:,z),1))%Pixeles a analizar %bwGlioma3D_r / bwnecroEd3D_r
        TempBW=bwnecroEd3D_r(:,:,z);
        TempG1c=g1c_r(:,:,z);
        TempG1=g1_r(:,:,z);
        TempG2=g2_r(:,:,z);
        TempFlair=gflair_r(:,:,z);
        
        TempR1c=ROIg1c_r(:,:,z);
        TempR1=ROIg1_r(:,:,z);
        TempR2=ROIg2_r(:,:,z);
        TempRflair=ROIgflair_r(:,:,z);
        
        
        for x=1:X
            for y=1:Y
                if TempBW(x,y)==1
                    [Vg1c, Rg1c]=windowMxN(x,y,m,n,TempG1c, TempR1c);% cambiar caract. pixeles o estadísticas
                    [Vg1, Rg1]=windowMxN(x,y,m,n,TempG1, TempR1);
                    [Vg2, Rg2]=windowMxN(x,y,m,n,TempG2, TempR2);
                    [Vflair, Rflair]=windowMxN(x,y,m,n,TempFlair, TempRflair);
                    %extraer los rasgos a cada serie%,
                    %ExtraerRasgosPuros,ExtraerRasgos2, ExtraerRasgos
                    rasgosG1c=ExtraerRasgosT1C(Vg1c, Rg1c,levels_g1c);
                    rasgosG1=ExtraerRasgosT1(Vg1, Rg1, levels_g1);
                    rasgosG2=ExtraerRasgosT2(Vg2, Rg2,levels_g2);
                    rasgosFlair=ExtraerRasgosFlair(Vflair, Rflair,levels_gflair);
                    rasgos=[rasgosG1c rasgosG1 rasgosG2 rasgosFlair];
%                   
                    rasgos = rasgos';
                    rasgos = mapstd('apply',rasgos,PS1);% standard normalization
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
                    
%                     clase=predict(compactNNmodel,rasgos');%mynet(rasgos')
%                     
%                     if clase==2
%                         BWclase_r(x,y,z)=1;
%                     elseif clase==3
%                         BWclase_r(x,y,z)=2;
%                     elseif clase==4
%                         BWclase_r(x,y,z)=3;
%                     end
                    
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
 
BWclase=BWclase_r;
bwClases=BWclase;

%% Post procesing

BWclase(bwGlioma3D==0) = 0;%bwnecroEd3D


bwNecro=zeros(X,Y,Z);
bwEdema=zeros(X,Y,Z);
bwActivo=bwActivo3D; %EyN->bwActivo3D / Glioma->zeros(X,Y,Z);%;

bwActivo(BWclase==3)=1;
bwEdema(BWclase==2)=1;
bwNecro(BWclase==1)=1;

bwNecroActiv=bwNecro+bwActivo;
bwEdemaActiv=bwEdema+bwNecroActiv;
%%
% Necro=bwNecro*1;
% Edema=bwEdema*2;
% Activo=bwActivo*3;
% Todo=Necro+Edema+Activo;
% figure, imshow3D(Todo)
%%
for i =1:Z
    if  ~isempty(find(bwGlioma3D(:,:,i),2))
        bwNecroActiv(:,:,i)=imfill(bwNecroActiv(:,:,i),'holes');
        bwEdemaActiv(:,:,i)=imfill(bwEdemaActiv(:,:,i),'holes');
    end
end
bwNecro=logical(bwNecroActiv.*~bwActivo);
bwEdema=bwEdemaActiv.*~bwNecroActiv;
bwActivo=logical(bwActivo.*~bwNecro);
bwEdema=logical(bwEdema.*~bwActivo);
bwEdema=logical(bwEdema.*~ bwNecro);
t=toc;
