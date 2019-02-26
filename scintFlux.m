function OMS = scintFlux(OMS, ECData, info)

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
uStar = ECData.uStar;     %Friction velocity
Cp = ECData.Cp;
Lv = ECData.Lv;
if any(cell2mat(cellfun(@(x) ~isempty(strfind(x, 'Dir')), fields, 'UniformOutput', 0)));
    WndDir = ECData.Dir;     %Wind Direction
else
    WndDir = nan.*ones(size(Cp));
end


% % % [Lat, Long] = utm2ll(info.Coord_Rx(2), info.Coord_Rx(3), info.Coord_Rx(1));
% % % Long = abs(Long);
% % % timeFlag = dayNightFlag(OMS, Lat, Long, datestr(OMS.MWSC(1, 1), 'dd-mm-yyyy'), info.avgPer, info.UTC_offset, info.DST);

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
z_eff = effScintHeight(info.Z_LAS, OMS.WeightFunc.PWF(:, 2), info.L);

%Calculated Fluxes from OMS
[OMS.H, OMS.LHflux, OMS.L] = ...
    StructParam_Flux(OMS.StructParam(:, 2), ... %Ct2
    OMS.StructParam(:, 4),...                   %Cq2
    OMS.StructParam(:, 5),...                   %r_tq
    z_eff,...                                   %Effective Height
    WndDir, uStar, T, rho, Cp, Lv,...           %Avg Met quantities
    info.xt, info.xq,...                        %MOST Coefficients KH16
    ~HSign,...                                  %Night Flag
    info);                                      %info structure (for displacement height info


OMS.H = [OMS.MWSC(:, 1), OMS.H];
OMS.LHflux = [OMS.MWSC(:, 1), OMS.LHflux];
OMS.L = [OMS.MWSC(:, 1), OMS.L];

OMS.HHeader = {'TIMESTAMP', 'T_star', 'H [W/m^2]'};
OMS.LHfluxHeader = {'TIMESTAMP', 'q_star', 'LE [W/m^2]'};

OMS.LHeader = {'TIMESTAMP', 'z_eff', 'L_ob'};