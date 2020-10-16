function OMS = scintFlux(OMS, ECData, WeightFunc, info)

fprintf('Calculating Fluxes...\n');

%EC Data
fields = fieldnames(ECData);

flag(:, 1) = cell2mat(cellfun(@(x) ~isempty(strfind(x, 'T_FW')), fields, 'UniformOutput', 0));
flag(:, 2) = cell2mat(cellfun(@(x) ~isempty(strfind(x, 'T_Son')), fields, 'UniformOutput', 0));

%Air Temperature
if any(flag(:, 1))
    T = ECData.T_FW;
    if any(flag(:, 2))
        T(isnan(T)) = ECData.T_Son(isnan(T));
    end
else
    T = ECData.T_Son;
end
    

      
rho = ECData.rho;        %Air Density
Cp = ECData.Cp;
Lv = ECData.Lv;
if any(cell2mat(cellfun(@(x) contains(x, 'Dir'), fields, 'UniformOutput', 0)))
    WndDir = ECData.WndDir;     %Wind Direction
else
    WndDir = nan.*ones(size(Cp));
end

WndSpd = ECData.WndSpd;
if any(cell2mat(cellfun(@(x) ~isempty(strfind(x, 'uStar')), fields, 'UniformOutput', 0)))
    uStar = ECData.uStar;     %Friction velocity
else 
    uStar = 0.1.*WndSpd;
end
%Sign for Scintillometer flux
if info.useECsign
    HSign = ECData.HSign;
else
    tmp = sign(OMS.StructParam(:, 5));
    tmp(tmp==-1) = 0;
    tmp(isnan(tmp)) = 0;
    HSign = logical(tmp);
end

%Calculate Effective height
fprintf('Calculating Effective Height...\n');
z_eff = effScintHeight(info.Z_LAS, WeightFunc.PWF(:, 2), info.L);

%Calculated Fluxes from OMS
[OMS.H, OMS.LHflux, OMS.L] = ...
    StructParam_Flux(OMS.StructParam(:, 6), ... %Ct2
    OMS.StructParam(:, 8),...                   %Cq2
    OMS.StructParam(:, 9),...                   %r_tq
    z_eff,...                                   %Effective Height
    WndDir, WndSpd, uStar, T, rho, Cp, Lv,...           %Avg Met quantities
    info.xt, info.xq,...                        %MOST Coefficients KH16
    ~HSign,...                                  %Night Flag
    info);                                      %info structure (for displacement height info


OMS.H = [OMS.MWSC(:, 1), OMS.H];
OMS.LHflux = [OMS.MWSC(:, 1), OMS.LHflux];
OMS.L = [OMS.MWSC(:, 1), OMS.L];

OMS.HHeader = {'TIMESTAMP', 'T_star', 'H [W/m^2]'};
OMS.LHfluxHeader = {'TIMESTAMP', 'q_star', 'LE [W/m^2]'};

OMS.LHeader = {'TIMESTAMP', 'z_eff', 'u_star', 'L_ob'};