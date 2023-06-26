# TautString

This folder contains functions for generating and visualizing the Taut 
String Estimate of a 1-D signal.

The most relevant functions in this folder are:
1. taut_string.m: to generate the Taut String Estimate
2. plot_hrv_tautstring.m: to visualize the original function and its Taut 
   String Estimate
3. feature_compute_staticTS.m: for extracting morphological and statistical 
   features from the Taut String Estimate

The remaining functions are helper functions, with one exception:
'feaure_compute_TautString.m' accepts an HRV signal, calculates a few 
(non Taut String) features directly from the HRV signal, then calculates 
the Taut String Estimate of the HRV signal and then extracts Taut String 
features.

Note: Some of the code here was developed prior to this project (those 
authors include Sardar Ansari and Ashwin Belle).

# Programming Language
Matlab 2017b