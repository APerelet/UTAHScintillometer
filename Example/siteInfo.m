% site specific script to load site information
% Airport Wetlands 2015

clear; close all force; clc;
%% --------------------------INPUTS----------------------------------------
%Scintillometer Data Root Dir
%Supplementary eddy covariance data file should exist in here
info.rootDir = 'G:\Alexei\Data\Airport_Wetlands\Scintillometer';
info.ECFileName = 'ECData.mat';

%Save Directory
info.saveDir = 'G:\Alexei\Data\Airport_Wetlands\Scintillometer\Processed';

%Days per split file
    info.daysPerFile = 1;
    
% Use Sign of Eddy covariance flux
    info.useECsign = true;
  
% Site Name
    info.siteName = 'Westmount16';

% Scintillometer frequency [hz]
    info.freq = 1/60;
% Averaging Period in minutes
    info.avgPer = 30;
    info.ECavgPer = 30;
    
% UTC offset at scintillometer location
    info.UTC_offset = -7;
    info.DST = 1;
    
% Coefficients for MOST
    info.xt = [5.6, 6.5; 5.5, 1.1]'; %KH16
    info.xq = [4.5, 7.3; 4.5, 1.1]'; %KH16
    info.Coeff = 'KH16';
    
% Scintillometer GPS Coordinates [Zone, Easting, Northing]
    info.Coord_Rx = [12, 412142.90, 4517477.04];
    info.Coord_Tx = [12, 411617.64, 4517999.56];

%Enter Infrared Large Aperture Scintillometer information
    %wavelength
    info.LASwavelen = 880E-9; % -- [m]
    %Aperture
    info.LASaperture = 0.15/2; % -- [m]
    %Transmitter Height
    info.LAS_hTx = 3.25; % -- [m]
    %Receiver Height
    info.LAS_hRx = 2.77; % -- [m]

%Enter Microwave Scintillometer information
    %wavelength
    info.MWSwavelen = 1.86E-3; % -- [m]
    %Aperture
    info.MWSaperture = 0.3/2; % -- [m]
    %Transmitter Height AGL
    info.MWS_hTx = 2.77; % -- [m]
    %Receiver Height AGL
    info.MWS_hRx = 3.41; % -- [m]
    
%enter horizontal path perpendicular displacement (relative to LAS)
    %Receiver
    info.yRx = 0; % -- [m]
    %Transmiter
    info.yTx = 0; % -- [m]

%Path information
    %Number of points for path weighting function calculation
    info.N = 301; 
    %Elevation of Receiver and Transmitter Tower
    info.beamEle = [1289, 1289]; % -- [m]
    %elevation along path - NOTE: if flat one evelation ok, otherwise provide a vector of length N (from above) of elevation profile
    %Make sure end points match elevation measured at towers
    info.GroundEle = 1289; % -- [m]
    %Displacement height
    info.h_canopy = 0; %Canopy height [m]
    info.windSectorWidth = 360;  %Wind Sector Width [degrees]
    info.d_h = 0;   %d/h that correspond to wind sectors
    
%Spike Test
    info.spikeTest.windowSizeFraction = 1;
    info.spikeTest.maxRuns = 10;
    info.spikeTest.maxConsecutiveOutliers = 3;
    info.spikeTest.spikeDef = 3;
%% --------------------------CALCULATIONS----------------------------------

info.lambda = [info.LASwavelen, info.LASwavelen; info.LASwavelen, info.MWSwavelen; info.MWSwavelen, info.MWSwavelen];
info.R = [info.LASaperture, info.LASaperture; info.LASaperture, info.MWSaperture; info.MWSaperture, info.MWSaperture];

info.d_Tx = sqrt((0-info.yTx)^2+(info.LAS_hTx-info.MWS_hTx)^2);
info.d_Rx = sqrt((0-info.yRx)^2+(info.LAS_hRx-info.MWS_hRx)^2);
if info.MWS_hTx-info.LAS_hTx<0;     info.d_Tx = -info.d_Tx;     end
if info.MWS_hRx-info.LAS_hRx<0;     info.d_Rx = -info.d_Rx;     end

%Beam Length
info.L = sqrt((info.Coord_Rx(2)-info.Coord_Tx(2))^2+(info.Coord_Rx(3)-info.Coord_Tx(3))^2);

%Beam Orientation
info.BeamOrient = 270+acos((info.Coord_Rx(2)-info.Coord_Tx(2))/info.L)*180/pi;

% Beam tilt from Receiver to Transmitter
info.pathTilt_LAS = atan(((info.beamEle(2)+info.LAS_hTx)-(info.beamEle(1)+info.LAS_hRx))/info.L)*180/pi;
info.pathTilt_MWS = atan(((info.beamEle(2)+info.MWS_hTx)-(info.beamEle(1)+info.MWS_hRx))/info.L)*180/pi;

% Beam Height
tmp = linspace(0, info.L, info.N);
tmp2 = info.beamEle(1)+info.LAS_hRx+tmp*tan(info.pathTilt_LAS*pi/180);
info.Z_LAS = tmp2-info.GroundEle';

tmp2 = info.beamEle(1)+info.MWS_hRx+tmp*tan(info.pathTilt_MWS*pi/180);
info.Z_MWS = tmp2-info.GroundEle';

%Displacement Height
info.wind_Sector = [(0:info.windSectorWidth:(360-info.windSectorWidth)); (info.windSectorWidth:info.windSectorWidth:360)]';
info.d = info.h_canopy.*info.d_h;

%load EC Data
load([info.rootDir, filesep, info.ECFileName]);
%% ------------------------Check Inputs------------------------------------
if ~exist(info.rootDir, 'dir')
    error(['Scintillometer Directory <', info.rootDir, '> Does not exist. Check siteInfo.m']);
end

if ~exist(info.saveDir, 'dir')
    mkdir(info.saveDir);
end

%% -----------------------RUN Scint Process--------------------------------
run('UTSapp_MAIN.m');