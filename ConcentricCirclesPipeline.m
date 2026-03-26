%% Pipeline for Concentric Circles
% nina fultz - february 24th 

cd concentricCircles/

%% using inflow effect at 7T to make vessel mask 
makingVesselfromT1.m

%% dilating vessels so that it hits the CSF signal scan 
VesselDilatingwithBoundaries.m

%% manually correct those vessels

%% make concentric circles on all post-M1 vessels 
ConcentricCircles_lydianesway_onManuallycorrected.m

%% make concentric circles on right vs. left
ConcentricCircles_lydianesway_onManuallycorrected_RightLeft.m

%% plot these images for paper 
PlottingConcentricCircles_lydianeswayNormalized_rightvsleft.m
