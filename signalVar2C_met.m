%Function for use with Scint_Process
%Calcualtes Cn2 from signal intensity variance of scintillometer
%Then calculates CT2, CTq, Cq2, & r_Tq


function [OMS] = signalVar2C_met(OMS, ECData, WeightFunc, info)

fprintf('Calculating Structure Parameters...\n');
%Calculate Cn2

OMS.Cn2 = [OMS.MWSC(:, 1), ...                %time
    OMS.MWSC(:, 8)./WeightFunc.G(1),... 
    OMS.MWSC(:, 10)./WeightFunc.G(2),...
    OMS.MWSC(:, 9)./WeightFunc.G(3)];
OMS.Cn2Header = {'TIMESTAMP', 'Cn2 LAS', 'Cn2 OMS', 'Cn2 MWS'};


%Calculate CT2 CTq Cq2 r_Tq
OMS = StructPrepare(OMS, ECData, info);