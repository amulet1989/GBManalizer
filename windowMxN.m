function [Imn, ROIout]=windowMxN(x,y,m,n,I,ROIin)

x1=x-m;
x2=x+m;
y1=y-n;
y2=y+n;
Imn=I(x1:x2,y1:y2);
ROIout=ROIin(x1:x2,y1:y2);
% Imn=Imn(:)';% para rasgos pixeles
end