# Continuous Sepsis Trajectory Prediction using Tensor-Reduced Physiological Signals
Code for predicting change in qSOFA using features extracted from physiological signals and/or electronic health record data.

## To run the script:  
Operate from the main branch and use runSOFApipeline.m  
Specify directories within the config.json file.  
Once tensor decomposition has been completed, navigate to TrainModels and use callBasicMITrainingWithMI.m to train your model of choice.

## Contributors
The following members of BCIL contributed to or wrote the code included in this repository (listed in alphabetical order):  
[Olivia P. Alge](https://github.com/olialgeUMICH)  
[Sardar Ansari](https://github.com/sardaransari)  
[Harm Derksen](https://github.com/harmderksen)  
[Jonathan Gryak](https://github.com/gryakj)  
[Larry Hernandez](https://github.com/larryhernandez)  
[Joshua Pickard](https://github.com/Jpickard1)  
[Alexander Wood](https://github.com/alexanderwood)  
[Winston Zhang](https://github.com/winstonwzhang)  

And we acknowledge the following people who influcened the code written with their advice, review, and other work:  
[Renaid Kim](https://github.com/renaidkim)  
[Kayvan Najarian](https://najarianlab.ccmb.med.umich.edu/)  
[Neriman Tokcan](https://github.com/nerimantokcan)  

## Software Used 
Creators used Matlab 2020a or 2020b to write the code, unless otherwise specified.

This project used the following software for manipulating tensors in Matlab:  
Brett W. Bader, Tamara G. Kolda and others.  
MATLAB Tensor Toolbox Version 3.1,  
Available online, June 2019.  
URL: https://gitlab.com/tensors/tensor_toolbox. 

Sedghamiz. H, "Matlab Implementation of Pan Tompkins ECG QRS detector.", March 2014. https://www.researchgate.net/publication/313673153_Matlab_Implementation_of_Pan_Tompkins_ECG_QRS_detect  
Hooman Sedghamiz (2023). Complete Pan Tompkins Implementation ECG QRS detector (https://www.mathworks.com/matlabcentral/fileexchange/45840-complete-pan-tompkins-implementation-ecg-qrs-detector), MATLAB Central File Exchange. Retrieved June 19, 2023.
