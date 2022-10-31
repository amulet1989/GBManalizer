function [Rasgos]=ExtraerRasgosT1C(Ibox,ROIonly,levels)
Rasgos=zeros(1,10);
Ibox1=Ibox';
IVect=[Ibox1(:)]';
%% 1st order descriptive statistics
Rasgos(1)=range(IVect);%ok(4)
Rasgos(2)=max(IVect);%ok(7)
Rasgos(3)=min(IVect);%ok(8)

%% Texture statistics 2nd order GLCM

%Globals
Nbins=length(levels);
CaractGlobal=getGlobalTexturesT1C(ROIonly,Nbins);%Ibox
%4
Rasgos(4)=CaractGlobal.Variance;
%5
Rasgos(5)=CaractGlobal.Skewness;
%6
% Rasgos(6)=CaractGlobal.Kurtosis;

%% Textura locales
GLCMs=getGLCM(ROIonly,levels);
CaractH1=getGLCMtexturesT1C(GLCMs(:,:,1));
%7
% Rasgos(7)=CaractH1.Energy;
%8
Rasgos(6)=CaractH1.Contrast;
%9
% Rasgos(6)=CaractH1.Entropy;
%10
% Rasgos(10)=CaractH1.Homogeneity;
%11
Rasgos(7)=CaractH1.Correlation;
Rasgos(8)=CaractH1.SumAverage; %12
Rasgos(9)=CaractH1.Variance;   %13
% Rasgos(10)=CaractH1.Dissimilarity;%14
Rasgos(10)=CaractH1.AutoCorrelation;%15
end
%% Global
function [textures] = getGlobalTexturesT1C(ROIonly,Nbins)
% -------------------------------------------------------------------------
% function [textures] = getGlobalTextures(ROIonly,Nbins)
% -------------------------------------------------------------------------
% DESCRIPTION: 
% This function computes Global texture features from the region of 
% interest (ROI) of an input volume.
% -------------------------------------------------------------------------
% PRELIMINARY
vectorValid = ROIonly(~isnan(ROIonly));
histo = hist(vectorValid,Nbins);
histo = histo./(sum(histo(:)));
vectNg = 1:Nbins;
u = histo*vectNg';

% COMPUTATION OF TEXTURES
% 4. Variance
variance = 0;
for i=1:Nbins
    variance = variance+histo(i)*(i-u)^2;
end
sigma = sqrt(variance);
textures.Variance = variance;

% 5. Skewness
skewness = 0;
for i = 1:Nbins
    skewness = skewness+histo(i)*(i-u)^3;
end
skewness = skewness/sigma^3;
textures.Skewness = skewness;

% 6. Kurtosis
% kurtosis = 0;
% for i = 1:Nbins
%     kurtosis = kurtosis+histo(i)*(i-u)^4;
% end
% kurtosis = (kurtosis/sigma^4) - 3;
% textures.Kurtosis = kurtosis;

end

%% Textura
function [textures] = getGLCMtexturesT1C(GLCM)
% -------------------------------------------------------------------------
% function [textures] = getGLCMtextures(GLCM))
% -------------------------------------------------------------------------
% DESCRIPTION: 
% This function computes texture features from an input Gray-Level 
% Co-occurence Matrix (GLCM).
% -------------------------------------------------------------------------

% PRELIMINARY
textures = struct;
matrixtemp = GLCM;
GLCM = GLCM/(sum(GLCM(:))); % Normalization of GLCM
nL = max(size(GLCM));
indVect = 1:nL;
[colGrid,rowGrid] = meshgrid(indVect,indVect);


% COMPUTATION OF TEXTURE FEATURES
% 7. Energy, Ref.[1]
% textures.Energy = sum(sum(GLCM.^2));

% 8. Contrast, Ref.[1]
contrast = 0.0;
for n = 0:nL-1
   temp = 0;
   for i = 1:nL
      for j = 1:nL
         if (abs(i-j) == n)
            temp = temp+GLCM(i,j);
         end
      end
   end
   contrast = contrast + n^2*temp;
end
textures.Contrast = contrast;

% 9. Entropy, Ref.[1]
% textures.Entropy = -sum(sum(GLCM.*log2(GLCM + realmin)));

% 10. Homogeneity, adapted from Ref.[1]
% temp = 0;
% for i = 1:nL
%    for j = 1:nL
%       temp = temp + GLCM(i,j)/(1+abs(i-j));
%    end
% end
% textures.Homogeneity = temp;
% 
% 11. Correlation, adapted from Ref. [1] (this definition from MATLAB is preferred from the original one in [1])
textures.Correlation = graycoprops(round(matrixtemp),'Correlation');
textures.Correlation = struct2cell(textures.Correlation);
textures.Correlation = textures.Correlation{1};

% 12. Variance, Ref.[2]; and 13. SumAverage, Ref.[2]. (adapted from Variance and SumAverage metrics defined by Haralick in Ref. [1])
% However, in order to compare GLCMs of different sizes, the metrics
% are divided by the total number of elements in the GLCM (nL*nL). Also,
% there is probably an error in Assefa's paper [2]: in the variance equation,
% 'u' should appropriately be replaced by 'ux' and 'uy' as calculated in A1
% and A2 of the same paper (read 'ui' and 'uj' in our code).
ui = indVect*sum(GLCM,2);
uj = indVect*sum(GLCM)';
tempS = rowGrid.*GLCM + colGrid.*GLCM;
tempV = (rowGrid-ui).^2.*GLCM + (colGrid-uj).^2.*GLCM;
textures.SumAverage = 0.5*sum(tempS(:))/(nL^2);
textures.Variance = 0.5*sum(tempV(:))/(nL^2);

% 14. Dissimilarity, Ref.[3] 
% diffMat = abs(rowGrid-colGrid);
% temp = diffMat.*GLCM;
% textures.Dissimilarity = sum(temp(:));

% 15. AutoCorrelation, Ref.[4]
temp = rowGrid .* colGrid .* GLCM;
textures.AutoCorrelation = sum(temp(:));


end