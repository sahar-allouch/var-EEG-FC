# Effect of analytical variability in estimating EEG-based functional connectivity

The significant degree of variability and flexibility in neuroimaging analysis approaches has recently raised concerns. When running any neuroimaging study, the researcher is faced with a large number of methodological choices, often made arbitrarily. This can produce substantial variability in results, ultimately hindering research replicability, and thus, robust conclusions. Here, we addressed the analytical variability in the EEG source connectivity pipeline and its effects on the consistency /discrepancy of the outcomes. Like most neuroimaging analyses, the EEG source connectivity analysis involves the processing of high-dimensional data and is characterized by a complex workflow that promotes high analytical variability. In this study, we focused on source functional connectivity variability induced by three factors along the analysis pipeline: 
1. number of EEG electrodes, 
2. inverse solution algorithms, 
3. functional connectivity metrics. 
Variability of the outcomes was assessed in terms of group-level consistency, inter-, and intra-subjects similarity, using resting-state EEG data (n = 88). As expected, our results showed that different choices related to the number of electrodes, source reconstruction algorithm, and functional connectivity measure substantially affects group-level consistency, between-, and within-subjects similarity. We believe that the significant impact of such methodological variability represents a critical issue for neuroimaging studies that should be prioritized.


## Tested parameters:
  1) Channel densities: 19, 32, 64
  2) Inverse solutions:
      - weighted minimum norm estimate (wMNE)
      - exact low resolution brain electromagnetic tomography (eLORETA)
      - linearly constrained minimum variance (LCMV) beamforming
  4) Functional connectivity measures:
      - phase-locking value (PLV) without source leakage correction
      - phase-locking value (PLV) with souce leakage correction
      - phase-lag index (PLI)
      - weighted phase-lag index (wPLI)
      - amplitude envelope correlation (AEC) without source leakage correction
      - amplitude envelope correlation (AEC) with source leakage correction

## Running the code:
- To obtain the connectivity matrices of all subjects and epochs (over all conditions), run "run_all()".
- To get the results quantification (group-level consistency, between-subjects similarity, within-subjects similarity) run "get_results_quantif()".

* Please check that the path to data is correct prior to running the codes
* Please check that the path to the fieldtrip toolbox is correct prior to running the codes
* Please add the [Brainstorm](https://neuroimage.usc.edu/brainstorm/Introduction) toolbox to your matlab paths.
