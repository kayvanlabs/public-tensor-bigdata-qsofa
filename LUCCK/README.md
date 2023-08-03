# Learning Using Concave and Convex Kernels (LUCCK)
The codebase for the machine learning method Learning Using Concave and Convex Kernels (LUCCK) (https://www.mdpi.com/1099-4300/21/5/442).

Notes on the Flexible Convexity Kernel Method:
In the function myML3. "TrainWeight" was used to compensate for when the distribution over the classes is different for the training data and the testing data. If the distribution is the same (for example if the training data was randomly sampled) then one
can just take a vector of ones.

Using the Model with Categorical/Binary Data:
The method still works for categorical or binary features.
For binary, one could just use the values 0 or 1.
For categorical features with K distinct values one can encode each value as a vector of k-features.
For example, if we have a feature "race" with values "white" "black" and "asian" then we can encode white as [1,0,0], black as [0,1,0] and asian [0,0,1]. This is known as a one-hot encoding.

There may be another feature, for example age, that would still be just a single value. So now the data might look like a matrix
1,0,0,35
0,1,0,20
1,0,0,60
0,0,1,53
etc.


LUCCK Executable

1. Prerequisites for Deployment 

Verify that version 9.9 (R2020b) of the MATLAB Runtime is installed.   
If not, you can run the MATLAB Runtime installer.
To find its location, enter
  
    >>mcrinstaller
      
at the MATLAB prompt.
NOTE: You will need administrator rights to run the MATLAB Runtime installer. 

Alternatively, download and install the Windows version of the MATLAB Runtime for R2020b 
from the following link on the MathWorks website:

    https://www.mathworks.com/products/compiler/mcr/index.html
   
For more information about the MATLAB Runtime and the MATLAB Runtime installer, see 
"Distribute Applications" in the MATLAB Compiler documentation  
in the MathWorks Documentation Center.

2. Files to Deploy and Package

Files to Package for Standalone 
================================
-LUCCK.exe
-MCRInstaller.exe 
    Note: if end users are unable to download the MATLAB Runtime using the
    instructions in the previous section, include it when building your 
    component by clicking the "Runtime included in package" link in the
    Deployment Tool.
-This readme file 



3. Definitions

For information on deployment terminology, go to
https://www.mathworks.com/help and select MATLAB Compiler >
Getting Started > About Application Deployment >
Deployment Product Terms in the MathWorks Documentation
Center.

