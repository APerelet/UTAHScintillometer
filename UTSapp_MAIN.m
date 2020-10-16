%Scintillometer Data Process
%Created by: Alexei Perelet
%alexei.pere@gmail.com
%Version 1.0
%Version Date: 01 April 2018

%Usage:
%   Supplementary Meteorological Data Format:
%   Should include values for the entire time frame
%   Mean values over entire scintillometer footprint. Ideally at the same
%   measurement height as the effective height of the scintillometer
%   If no values exist, the receiver mounted Vaisala weather station data
%   will be used
%       ECData.<FIELDS>
%           T_FW    -> Finewire temperature [K]
%           T_Son   -> Sonic Temperature [K]
%           T_Slow* -> Slow response sensor Temperature [K]
%           P*      -> Air pressure [Pa]
%           q       -> specific Humidity [g/g]
%           rho     -> Air density [kg/m&3]
%           RH_Slow*-> Slow response sensor Relative Humidity [%]
%           uStar  -> Friction velocity
%           Cp      -> Specific heat air
%           Lv      -> Latent heat of vaporization
%           Time    -> Timestamp corresponding to each measurement in
%                      matlab datenum format
%           HSign   -> Sign of sensible heat flux
%           WndSpd  -> Wind speed [m/s]
%           WndDir  -> Wind direction
%
%   *Minimum required
%   ECData should be quality controlled
%   Tmperature data selection hierarchy
%       T_FW
%       T_Son
%       T_Slow
%   Humidity data selection hierachy
%       Q & rho
%       RH_slow
%   Air pressure data selection hierarchy
%       P
%       Evelation and standard atmosphere-> when no P data


%Scint_Process Version
info.ScintVer = '1.0';
%% ----------------------------------------------PROCESS------------------------------------------------------------
%Check inputs with user before continuing
    done = checkInputs(info);
    if done==0
        error('Check siteInfo.m');
    end

%Calculate Spectral Weighing function and Path Weighting function
    WeightFunc = scintWeightFunc(info);
    
%Determine what files to load
    [dataFiles, fileFlag] = findScintFiles(info);
    
%Load scintillometer data and Process
    for ii=1:length(dataFiles)
        
        %Load scintillometer data
        OMS = loadScintData(dataFiles, fileFlag, ii);

        %Condition Data
        [OMS, ECDataCut] = conditionUTSappData(OMS, ECData, info);
        
        if ~isempty(ECDataCut.Time)
            %Calculate refractive index & meteorological Structure parameters
            OMS = signalVar2C_met(OMS, ECDataCut, WeightFunc, info);

            %Calculate scintillometer fluxes
            OMS = scintFlux(OMS, ECDataCut, WeightFunc, info);

            %Save Data
            saveScintOutput(OMS, ECDataCut, info)
        end

    end
    gong();