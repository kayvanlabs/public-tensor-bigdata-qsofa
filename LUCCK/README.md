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