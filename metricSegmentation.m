function [metric]= metricSegmentation(Iseg , GT)

% ACC
[X,Y,Z]=size(Iseg);
vp=0;
fn=0;
fp=0;
for z=1:Z
    for x=1:X
        for y=1:Y
            if ((Iseg(x,y,z) == true) && (Iseg(x,y,z) == GT(x,y,z)))
                vp=vp+1;
            elseif GT(x,y,z) == true
                fn=fn+1;
            elseif (Iseg(x,y,z) == true)
                fp=fp+1;   
            end
        end
    end
end
metric.Recall = vp/(vp+fn);
metric.Prec = vp/(vp+fp);

%% Jaccard
metric.Jacc = jaccard(Iseg , GT);
               
%% Dice
metric.Dice = dice(Iseg , GT);
%% BFscore
metric.BF = bfscore(Iseg , GT);
%% Housedorff
metric.H95 = imhausdorff(Iseg, GT); %imhausdorff

