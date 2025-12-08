# csf donuts
nina fultz - n.e.fultz@lumc.nl - dec 2025
purpose: code for csf donuts manuscript
          1) preprocessing
          2) figures

# preprocessing of data 
1) preprocessing of data can be done by running csfdonut_lydiane_preprocessing_scripts.m

# figures
1) figures can be made by following: csf_donuts_creatingfigures.m
          a) cross sectional and bar plots for Figures 2d,h and 3g,h,i can be made with figures/fig_crosssec_and_barplots.m
          b) violin plots of SAS vs. PVSAS CSF-mobility in figures 2 and 3 can be made with figures/fig_violinplots.m
          c) CSF-mobility and FA comparison between arteries (figure 3o, supplemental figure 4e) can be made: fig_violinplots_aca_m1_postm1.m, fig_violinplots_aca_m1_postm1_FA.m
          d) Cardiac and respiration plots (Figure 6, Supplemental Figure 7): cardiac_and_respiration_binning_allSubjects_MCA.m, cardiac_and_respiration_binning_allSubjects_MCA.m, physio_AveragePlots.m, physio_AveragePlots_ACA.m
          e) violin plots of SAS vs. PVSAS FA in Supplemental Figure 4 can be made with figures/fig_violinplots_FA.m
          f) violin plots of SAS vs. PVSAS CSF-signal in Supplemental Figure 5 can be made with figures/fig_violinplots_b0.m
          g) Vectors are made by running: rgb_maps.m, just_vectors_not_rgb.m
