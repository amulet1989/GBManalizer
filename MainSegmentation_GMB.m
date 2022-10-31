% main script
close all
clear all
clc

%% Test
serieNum= "007";
% ["001" "007" "014" "025" "031" "039" "051" "062" "067" "075"...
%      "077" "080" "081" "083" "090" "091" "121" "144" "146"...
%     "152" "161" "166" "169" "170" "174" "178"...
%     "186" "189" "192" "196" "199" "210" "222" "248" "254"];

%% Load trained Neural Network
load NeuralNetworkFile_80N_1000iter_tanh_30features  % 80 neurons 30 features
% load NeuralNetworkFile_115N_500iter_tanh_60features % 115 neurons 60 features

%% Read Data
filename=serieNum
FlairPath=["BraTS20_Training_" + serieNum + "\BraTS20_Training_" + serieNum + "_flair.nii"];
T1Path=["BraTS20_Training_" + serieNum + "\BraTS20_Training_" + serieNum + "_t1.nii"];
T2Path=["BraTS20_Training_" + serieNum + "\BraTS20_Training_" + serieNum + "_t2.nii"];
T1cPath=["BraTS20_Training_" + serieNum + "\BraTS20_Training_" + serieNum + "_t1ce.nii"];
TargetPath=["BraTS20_Training_" + serieNum + "\BraTS20_Training_" + serieNum + "_seg.nii"];

Flair = niftiread(FlairPath);
T1 = niftiread(T1Path);
T2 = niftiread(T2Path);
T1C = niftiread(T1cPath);
Target = niftiread(TargetPath);

%% Data processing
G1=T1;
G1C=T1C;
G2=T2;
Gflair=Flair;

%Parameters
tic % initializing timer 1
%Parameters of Whole Tumor segmentation (WT)
Umb=3;%thresholds TC: 2, 3
iterations=20;% Itarations number of Chan-Vese algoritm to WT

%Parameters of Active Tumor segmentation (AT)
Umb2=2;
iterations2=3;

%Parameters of  Edema and Necrosis segmentation
iterations3=1;
iterations4=1;
PL=5;
PT=2;
%% Targets adequacy
%Intensity 1 image masks are created for each region
[x,y,z]=size(Target);
TargetNecro=logical(zeros(x,y,z));
TargetNecro(Target==1) = 1;
TargetEdema=logical(zeros(x,y,z));
TargetEdema(Target==2) = 1;
TargetActivo=logical(zeros(x,y,z));
TargetActivo(Target==4) = 1;
TargetInfiltrado=logical(zeros(x,y,z));
TargetInfiltrado(Target==3) = 1;

%% Whole tumor segmentation part I (Otsu multithreshold)

G=T2+Flair;

%    Search preliminary seed
[BWflair3D,centroide]=preliminary_seed_Flair(Flair);

%% Seed update using Flair+T2 and Whole Tumor segmentation
% Erosión 3D
BWGlioma3D = Segmentation_WholeTumor(G,BWflair3D,centroide);% Flair G
% Creating structural element for erosion
Nh=zeros(7,7,4);
Nh(:,:,1)=[ 0   0   0   0   0   0   0; ...
    0   0   0   1   0   0   0; ...
    0   0   1   1   1   0   0;...
    0   1   1   1   1   1   0; ...
    0   0   1   1   1   0   0;...
    0   0   0   1   0   0   0; ...
    0   0   0   0   0   0   0;];

Nh(:,:,2)=[ 0   0   0   0   0   0   0; ...
    0   1   1   1   1   1   0; ...
    0   1   1   1   1   1   0;...
    0   1   1   1   1   1   0; ...
    0   1   1   1   1   1   0;...
    0   1   1   1   1   1   0; ...
    0   0   0   0   0   0   0;];

Nh(:,:,3)=[ 0   0   0   0   0   0   0; ...
    0   1   1   1   1   1   0; ...
    0   1   1   1   1   1   0;...
    0   1   1   1   1   1   0; ...
    0   1   1   1   1   1   0;...
    0   1   1   1   1   1   0; ...
    0   0   0   0   0   0   0;];

Nh(:,:,4)=[ 0   0   0   0   0   0   0; ...
    0   0   0   1   0   0   0; ...
    0   0   1   1   1   0   0;...
    0   1   1   1   1   1   0; ...
    0   0   1   1   1   0   0;...
    0   0   0   1   0   0   0; ...
    0   0   0   0   0   0   0;];

se=strel('arbitrary',Nh);
BWGlioma3D=imerode(BWGlioma3D,se);
%      figure('Name',['Glioma Erode ' + filename]),imshow3D(BWGlioma3D)

%% Tumor segmentation part II (active contours)
%Whole Tumor
BWGlioma3D=activecontour(Gflair , BWGlioma3D, iterations, 'Chan-Vese');

BWGlioma3D=imfill(BWGlioma3D,4,'holes');
ItotalL=logical(Target);

G1C(BWGlioma3D~=1) = 0;
G2(BWGlioma3D~=1) = 0;
G1(BWGlioma3D~=1) = 0;
Gflair(BWGlioma3D~=1) = 0;

%% Segment Active Tumor

[BWActivo3D,BWnecroEd]=Segmentations_GliomaRegions(G1C,BWGlioma3D,Umb2);
BWActivo3D=logical(BWActivo3D);

t1=toc; % ending timer 1

% End of Preliminar Tumor Segemetation
%% Visualizing
%
figure('Name',['Flair' + filename]), imshow3D(Flair,[]);%
figure('Name',['Ground Truth ' + filename]), imshow3D(Target,[]); %  (ground truth)

%% Machine learning aplication
[bwClases,bwActivo,bwNecro,bwEdema,t]=Segementation_pixelXpixel(BWGlioma3D,BWActivo3D,BWnecroEd,T1C,T2,T1,Flair,compactNNmodel,PS1);% using for 30 features and Neural Network
% [bwClases,bwActivo,bwNecro,bwEdema,t]=ExtarerCaracteristicasAll2(BWGlioma3D,BWActivo3D,BWnecroEd,T1C,T2,T1,Flair,compactNNmodel,PS1);% using for 60 features

t2=t % ending of timer 2

%%
%      figure('Name',['Clases' + filename]), imshow3D(bwClases); % Neural network output without post-processing
% %      figure('Name','Tumor activo'), imshow3D(bwActivo); % tumor activo
% %      figure('Name',['Necrosis' + filename]), imshow3D(bwNecro); % Necrosis
% %      figure('Name','Edema'), imshow3D(bwEdema); % Edema
%
%   calculation of final Dices coefficients

SegEnd=zeros(size(bwClases));
SegEnd(bwNecro==1)=1; % necro
SegEnd(bwEdema==1)=2; % edema
SegEnd(bwActivo==1)=3; %activo
% Final Segmentation
figure('Name',['Segm final' + filename]), imshow3D(SegEnd); 

%%
TotalM = metricSegmentation(bwNecro+bwActivo+bwEdema,TargetNecro+TargetActivo+TargetEdema);
AtivoM = metricSegmentation(bwActivo,TargetActivo);
EdemaM = metricSegmentation(bwEdema,TargetEdema);
NecroM = metricSegmentation(bwNecro,TargetNecro);
CoreM = metricSegmentation(bwNecro+bwActivo,TargetNecro+TargetActivo);

identify=str2num(serieNum); %str2num(serieNum); i

metrics= [identify;TotalM.Recall; TotalM.Prec; TotalM.Jacc; TotalM.Dice; TotalM.BF; TotalM.H95; ...
    AtivoM.Recall; AtivoM.Prec; AtivoM.Jacc; AtivoM.Dice; AtivoM.BF; AtivoM.H95; ...
    EdemaM.Recall; EdemaM.Prec; EdemaM.Jacc; EdemaM.Dice; EdemaM.BF; EdemaM.H95; ...
    NecroM.Recall; NecroM.Prec; NecroM.Jacc; NecroM.Dice; NecroM.BF; NecroM.H95; ...
    CoreM.Recall ; CoreM.Prec ; CoreM.Jacc ; CoreM.Dice ; CoreM.BF ; CoreM.H95; t1+t2 ];

name = {'serieNum';'TotalM.Recall'; 'TotalM.Prec'; 'TotalM.Jacc'; 'TotalM.Dice'; 'TotalM.BF'; 'TotalM.H95'; ...
    'AtivoM.Recall'; 'AtivoM.Prec'; 'AtivoM.Jacc'; 'AtivoM.Dice'; 'AtivoM.BF'; 'AtivoM.H95';
    'EdemaM.Recall'; 'EdemaM.Prec'; 'EdemaM.Jacc'; 'EdemaM.Dice'; 'EdemaM.BF'; 'EdemaM.H95'; ...
    'NecroM.Recall'; 'NecroM.Prec'; 'NecroM.Jacc'; 'NecroM.Dice'; 'NecroM.BF'; 'NecroM.H95'; ...
    'CoreM.Recall' ; 'CoreM.Prec' ; 'CoreM.Jacc' ; 'CoreM.Dice' ; 'CoreM.BF' ; 'CoreM.H95'; 'Tiempo'};

TablaMetricas = table(name, metrics )






