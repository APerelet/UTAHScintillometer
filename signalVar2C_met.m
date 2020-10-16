%Function for use with Scint_Process
%Calcualtes Cn2 from signal intensity variance of scintillometer
%Then calculates CT2, CTq, Cq2, & r_Tq


function [OMS] = signalVar2C_met(OMS, ECData, WeightFunc, info)

tmp = OMS.MWSC(:, [2, 4, 8]);

fprintf('Calculating Structure Parameters...\n');
%Calculate Cn2

OMS.Cn2 = [OMS.MWSC(:, 1), ...                %time
    tmp(:, 3)./WeightFunc.G(1),... 
    tmp(:, 2)./WeightFunc.G(2),...
    tmp(:, 1)./WeightFunc.G(3)];
OMS.Cn2Header = {'TIMESTAMP', 'Cn2 LAS', 'Cn2 OMS', 'Cn2 MWS'};


%Calculate CT2 CTq Cq2 r_Tq
OMS = StructPrepare(OMS, ECData, info);