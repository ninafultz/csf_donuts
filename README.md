# csf donuts
nina fultz - n.e.fultz@lumc.nl - dec 2025 - run in MATLAB2020b
purpose: code for csf donuts manuscript
          1) preprocessing
          2) figures

# preprocessing of data 

1. preprocessing of data can be done by running csfdonut_lydiane_preprocessing_scripts.m

# figures

Figures can be generated using the following scripts (look in 'figures' folder):

1. **General figure creation**  
   - `csf_donuts_creatingfigures.m`

2. **Cross-sectional and bar plots** (Figures 2d,h and 3g,h,i)  
   - `fig_crosssec_and_barplots.m`

3. **Violin plots of SAS vs. PVSAS CSF-mobility** (Figures 2 and 3)  
   - `fig_violinplots.m`

4. **CSF-mobility and FA comparison between arteries** (Figure 3o, Supplemental Figure 4e)  
   - `fig_violinplots_aca_m1_postm1.m`  
   - `fig_violinplots_aca_m1_postm1_FA.m`

5. **Cardiac and respiration plots** (Figure 6, Supplemental Figure 7)  
   - `cardiac_and_respiration_binning_allSubjects_MCA.m`  
   - `physio_AveragePlots.m`  
   - `physio_AveragePlots_ACA.m`

6. **Violin plots of SAS vs. PVSAS FA** (Supplemental Figure 4)  
   - `fig_violinplots_FA.m`

7. **Violin plots of SAS vs. PVSAS CSF-signal** (Supplemental Figure 5)  
   - `fig_violinplots_b0.m`

8. **Vector plots**  
   - `rgb_maps.m`  
   - `just_vectors_not_rgb.m`
