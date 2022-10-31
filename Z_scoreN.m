function ROIonlyNorm=Z_scoreN(ROIonly) 


ROIonly = double(ROIonly);
ROItemp=ROIonly;
min=ROIonly(2,2,2);
ROIonly(ROItemp == min) = NaN;

temp = ROIonly(~isnan(ROIonly));

u = mean(temp);
sigma = std(temp);

% ROIonlyNorm = ROIonly;
ROIonlyNorm=(ROIonly-u)/sigma;


% ROIonlyNorm(ROIonly < (u - 3*sigma)) = NaN;




