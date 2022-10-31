function [GBM3,GBM2]=Segmentations_GliomaRegions(Iin,BW,u)
% u=u+1;%añadido
u2=u+1;
% u1=u-1;
% Iin(BW==0)=-1000;
% Iin=im2double(Iin);
% Iin=imadjustn(Iin);

level=multithresh(Iin,5); %N umbrales , N+1 niveles
[F,index]=imquantize(Iin,level);
Mactivo = [0,0,1,1,1,1]; %máscara binaria
GBM3 = (Mactivo(index));%mat2gray


% level = multithresh(Iin,u);%2,3
% bwlevel=imquantize(Iin,level);
% GBM3=(bwlevel==u2);%3
% GBM2=(bwlevel==u);

Vol_r = regionprops3(BW,'Volume');
Vol_total=sum(Vol_r.Volume);

%% Si el volumen es muy pequeño grande a calcular
Vol = regionprops3(GBM3,'Volume');
VolMax=max(Vol.Volume);
Vol4=Vol_total/4;
if VolMax>=Vol4
    i=3;
    while VolMax>=Vol4 %50000
        %         u=u+2;
        %         u2=u+1;% u+1 ultim umbral
        %         level = multithresh(Iin,u);%u=2
        %         bwlevel=imquantize(Iin,level);
        %         GBM3=(bwlevel==u2);%u2=3
        %         GBM2=(bwlevel~=u2);
       % Mactivo(3)=[0,0,0,0,1,1];
        Mactivo(i)=0;
        GBM3 = (Mactivo(index));%mat2gray
        Vol= regionprops3(GBM3,'Volume');
        VolMax=sum(Vol.Volume);
        i=i+1;
    end
end

if VolMax<=500
    i=i-1;
%     Mactivo=[0,0,0,0,1];
    while VolMax<=500 %50000
        %         u=u+2;
        %         u2=u+1;% u+1 ultim umbral
        %         level = multithresh(Iin,u);%u=2
        %         bwlevel=imquantize(Iin,level);
        %         GBM3=(bwlevel==u2);%u2=3
        %         GBM2=(bwlevel~=u2);
        Mactivo(i)=1;
        GBM3 = (Mactivo(index)); %mat2gray
        Vol= regionprops3(GBM3,'Volume');
        VolMax=sum(Vol.Volume);
        i=i-1;
        
    end
end

GBM2 = BW;
GBM2(GBM3==1)=0;

