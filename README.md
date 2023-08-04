# Satellite Observer Code

This Matlab code performs various operations related to satellite observation from a particular location at a specific time. The entire process can be broadly divided into four stages: 

## Initialization

In this stage, the environment is prepared for the computation process. It includes:

1. Clearing all variables, closing all figures, and clearing command line output.
2. Defining the necessary paths for the required resources.
3. Setting the main parameters for the observation.

## Data Reading

In this part, the program reads the required data from the Two Line Element (TLE) and Earth Orientation Parameters (EOP) files. 

The code then:

1. Downloads and updates the TLE Files.
2. Extracts data from TLE files.
3. Extracts the Earth Orientation Parameters (EOP) for the observation time.

## Rough Propagation

The code simulates the orbits of the satellites and checks their visibility from the observatory location. This is done through these steps:

1. Definition of the `Sat` data structure.
2. Identification of the satellite using its TLE.
3. Calculation of the satellite's position and velocity at each timestep.
4. Check for visibility conditions: satellite must be lit by the Sun, the observatory must be dark, and the satellite must be over the mask angle.

The results of the rough propagation are then saved, and unobservable satellites are removed.

## Precise Propagation

The rough propagation is followed by a more precise propagation to increase the accuracy of the results.

After the main propagation process, several results and checks are performed:

1. Unobservable satellites are removed.
2. The remaining satellites are ordered according to observation time.
3. Conflicts are resolved if two satellites appear at the same time.
4. A more precise propagation is performed.

The results are displayed as a graphical output showing the observable satellites at different time instances. The results can be saved for further analysis.

## Execution

To run this program, start MATLAB, navigate to the directory containing the program files, and run the script in MATLAB's command window.

Please note that this program requires the necessary TLE and EOP files in the specified paths. Ensure that you have the necessary permissions to read these files.

**Contributor:** Leonardo Russo, 2025563

**Last Updated:** (insert date here)
