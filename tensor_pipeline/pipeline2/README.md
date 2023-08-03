# Tensor Decomposition Pipeline

Auth: Joshua Pickard jpic@umich.edu

Date: April 6, 2022

---
This directory contains a pipeline for feature vector construction from tensors. It is designed to replicate the original DoD pipeline and to hopefully be more understandable. The pipeline is split between 2 directories:
1. `construct_tensors/`
2. `tensor_decomp_2/`

and additionally a `utils/` directory was created to host additional tools and code the are primarily used for loading and saving data. The `construct_tensors/` directory contains code for building tensors from raw signal data, and the `tensor_decom_2/` directory contains code for performing HOSVD and CP tensor decompositions similar to what is done in the original DoD paper. These three directories are designed to work as a seamless pipeline to go from raw signals  tensors to feature vectors to a machine learning experiment, but if you already have tensors constructed, it is possible to use the `tensor_decomp_2/` code alone. A summary of each of these 3 directories and the formats of the data needed for each are given below.

## General Usage

The `utils/` directory primarily contain code that is used as helper functions and for loading data and parameters into other directories, but the `construct_tensors/` and `tensor_decomp_2/` are organized similarly. Each of these directories contains a bash script function, with the name `script_....sh` and a `driver_....m` function, which organize and call all of the code in their respective directories. If your data is formatted and loaded correctly, then you should only need to access the script and `utils/load...` functions to modify the parameters and run this pipeline (There is a single case where the Taut String epsilon values actually do need to be set from within the driver file, but this problem is currently being worked on).

## Tensor Construction: `construct_tensors/`

This directory takes raw signals data and constructs tensors from it. Either Taut String or Wavelet base features can be extracted for multiple epsilon values. Each set of signals constructs a 4 mode tensor, where the modes represents:
1. signals (in the case where multiple signals are recorded simultaneously) 
2. windows of the signal
3. epsilon values
4. features
The number of signals is fixed by your data set. The epsilon values must be set in the driver function (This should be the only variable that requires accessing a driver function to set). The number of windows and feature type are set in she bash script as function parameters, where the feature type is a string and the number of windows is variable that can be set either singularly or as an array job.

The data input to this function will come from load_data_raw.m, which calls `load_<data_set>_ raw.m` As you add new data sets, you will need to write a `load_<data_set>_ raw.m` function, which is primarily responsible for loading in the raw data into a matlab table that has a specific format (specified below). The output tensors will be saved to files: `<path of your data set>/<experiment_name>/tensors_<number of windows>.m` To compile all of the different tensorizations (different number of windows) you can run the compile_tensors.m, which stores all of the tensors in a single file at `<path of your data set>/<experiment_name>/tensors.m` This file has the structure of a dictionary where the keys are the number of windows in the tensor and the value is a matlab table.

## Tensor Decomposition: `tensor_decom_2/`

This directory constructs feature vectors from the tensor(s). It is set up to uses either one or multiple tensors to construct each feature vector, if multiple types of signals are samples. It uses HOSVD and CP decomposition, currently implemented with CP ALS, to reduce and extract factor matrices from these tensors, and then it uses these results to construct feature vectors from the individual tensors. This decomposition must be tied to a specific machine learning experiment due to how the tensor decomposition works, so by default it is set to construct feature vectors for 5 fold cross validation.

The output from compile_tensors.m is loaded into the driver file from the function `load_tensors.m` which calls `load_<data set>_ tensors.m`. You will need t create `load_<data set>_ tensors.m` and modify `load_tensors.m` as you work with new data sets in order to use this pipeline.

`load_<data set>_ tensors.m` has 2 main jobs. The first job is to load and return tensors in the format expected by the remainder of the code in this directory. This is the same format output by `compile_tensors.m`, so if you are using the first part of the pipeline to construct tensors, then this only requires loading your file saved at `<path of your data set>/<experiment_name>/tensors.m`. However, if you are using a different method for constructing your tensors, when you write `load_<data set>_ tensors.m` you will need to load the tensors in the format specified below.

The second main task of `load_<data set>_ tensors.m` is to set parameters for HOSVD decomposition. These parameters are passed as a dictionary object `params` with the following keys:
1. Ranks: An array of the ranks to try for the CP decomposition
2. CP ALS Rank: A null parameter that is used later in the code. By default I set this to -1
3. HOSVD Modes: An array where each element represents one of the tensor types being converted into a feature vector. If HOSVD is to be applied to a tensor, the corresponding element should be 1. Otherwise it should be 0.
4. HOSVD Errors: An array where each element represents one of the tensor types being converted into a feature vector. If HOSVD is to be applied to a tensor, the corresponding element in the array is the tolerance of the HOSVD decomposition. Otherwise it should be 0.
5. Non-Tensor-Features: This is a binary variable indivating if there are additional features (not from the tensor) that should be included in the feature vectors.
6. Feature Mode: This indicates which mode of the tensors represents the features extracted from the signals.

## Loading and formatting the data: `utils/`

The `utils/` directory contain a series of `load_...` functions that are designed to make using this pipeline easy in the sense that parameters only need to be set with in the `load_...` functions and bash scripts, but these functions must format the data correctly in order for the pipeline to run. There are 3 main types of data that need to be loaded:
1. raw signals data (before `construct_tensors/`)
2. tensor data (before `tensor_decom_2/` and output by `construct_tensors/`)
3. feature vectors (before your machine learning experiment and output by `tensor_decom_2/`)

additionally, it can be helpful to have function for loading the path to each data set and experiments so that it is easier to work with and save the results. All of these 4 types of data that would need to be loaded have a corresponding general function `load_data_raw.m`, `load_tensors.m`, etc. that call the specific version of the function for your data set. The inputs and outputs of each are explaned below.

These can be a little tricky, so use the `load_CWR_...` functions as good examples for what the correctly formatted loaded data should look like.

### Loading Signals: `load_data_raw.m`

This function is passed a data set as its only argument and calls the correct function to load that data sets raw signals. It returns 4 things:
1. raw data: This is a table containing all of the raw signal information. Its format is explaind below.
2. params: A dictionary of parameters that will be used to construct the tensors including: the maximum, minimum, and sampling frequencies of the signal, an indicator if non tensor features are also being loaded in, and an argument for the maximum epsilon value (which it not currently used).
3. data_path: The path of the directory storing your data and the location where your tensors will be saved to
4. filtered: A flag indifating if the loaded data has been filtered. This is not necessary, but I have found it helpful so to track different experiments.

Raw rata table: this table organizes the raw signal information prior to being tensorized. It contains 4 fields:
1. Ids: This is the id of the source generating the signal. To ensure that signals from the same patient or source do not end up in different folds during the classification experiment, every signal should have a numbered id corresponding to the source it comes from. If this is not a concern, then make sure every sample has a unique id.
2. Labels: This is the corresponding label to each sample in the table.
3. Signals: This column contains cell arrays of the signals that are being used to construct tensors. Each signal is stored separately in the cell array (not all together as a matrix)
4. Non-tensor features: This field contains vectors of non-tensor features that can be included in the feature vectors.

### Load Tensors: `load_tensors.m`

This function loads tensors and decomposition parameters into the driver of `tensor_decom_2/`. If your tensors were created in the `construct_tensors/` directory then the only thing that needs to be done is load your file `<path to data set>/<experiment_name>/tensors.m`, in addition to setting the parameters. In all, this function returns 4 things:
1. Tensor map: A map object, where each key corresponds to a specific type of tensorization and the values of the map are a table of tensors in the format explained below.
2. params: These are the parameters for the tensor decomposition (they are listed above).
3. Data path: This is used for saving the feature vectors to the correct location.

Tensor table: These tables contain 4 fields.
1. Ids: Similar to the Ids in the raw data table
2. Labels: Similar to the labels in the raw data table
3. Tensors: This column contains the tensors you are working with
4. Non-tensor features: Similar to the same field in the raw data table

### Load Feature Vectors: `load_feature_vectors.m`

This function loads the feature vectors produced by the `tensor-decomp_2/` directory. It returns the data path for your data set and experiment and the feature vectors in a table with the 8 following fields:
1. Number of Windows: The number of windows from the tensor used to make the corresponding feature vectors
2. Decomposition: Either tensor or vector, depending on if the feature vectors for that row were obtained with the tensor decomposition or vectorization
3. Fold: The fold used for k-fold cross validation that the feature vectors belong to
4. Rank: The rank used by the CP decomposition for that set of feature vectors or 0 if vectorization was used
5. Training_X: Feature vectors for training
6. Training_Y: Labels for training
7. Validation_X: Feature vectors for testing
8. Validation_Y: Labels for testing

This table will be generated automatically by `tensor_deocmp_2/` and should be saved at the path: `<data set path>/<experiment_name>/.../feature_vectors.m`.
