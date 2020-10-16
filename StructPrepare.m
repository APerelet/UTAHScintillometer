
function OMS = StructPrepare(OMS, ECData, info)

%EC Data
ECCheck = {'T_FW', 'T_Son', 'T_Slow', 'P', 'Q', 'q', 'rho'};
fields = fieldnames(ECData);

%Check if fields exist
for ii=1:length(ECCheck) 
    flag(:, ii) = cell2mat(cellfun(@(x) ~isempty(strfind(x, ECCheck{ii})), fields, 'UniformOutput', 0));
end
%Finewire Temperature
%%%%NEW
if any(flag(:, 1))
    T_fw = ECData.(fields{flag(:, 1)});
else
    T_fw = nan.*ones(length(ECData.(fields{1})), 1);
end

%Sonic Temperature
if any(flag(:, 2))
    T_son = ECData.(fields{flag(:, 2)});
else
    T_son = nan.*ones(length(ECData.(fields{1})), 1);
end

%Slow Response Temperature
if any(flag(:, 3))
    T_slow = ECData.(fields{flag(:, 3)});
else
    T_slow = nan.*ones(length(ECData.(fields{1})), 1);
end

nancheck = (sum(isnan(T_fw))+sum(isnan(T_son))+sum(isnan(T_slow)))/(3*length(T_fw));
if nancheck>0.95
    error('No temperature data');
end

%r_Tq
if info.rTqAssume
   r_Tq_tmp = nan(size(ECData.HSign));
   r_Tq_tmp(ECData.HSign==1) = info.rTqLim(1);
   r_Tq_tmp(ECData.HSign==0) = info.rTqLim(2);
else
    r_Tq_tmp = nan(size(ECData.HSign));
end
%%%%NEW

%%%%OLD
% % % if any(flag(:, 1))
% % %     T = ECData.(fields{flag(:, 1)});
% % % elseif any(flag(:, 2))
% % %     if exist('T', 'var')
% % %         T(isnan(T)) = ECData.(fields{flag(:, 2)})(isnan(T));
% % %     else
% % %         T = ECData.(fields{flag(:, 2)});
% % %     end
% % % elseif any(flag(:, 3))
% % %     if exist('T', 'var')
% % %         T(isnan(T)) = ECData.(fields{flag(:, 3)})(isnan(T));
% % %     else
% % %         T = ECData.(fields{flag(:, 3)});
% % %     end
% % % else
% % %     error('Cannot find Temperature field in ECData Structure');
% % % end
%%%%OLD

%Pressure
if any(flag(:, 4))
    P = ECData.(fields{flag(:, 4)});
else
    error('Cannot find Pressure field in ECData Structure');
end

%Humidity
if any(flag(:, 5))
    if any(flag(:, 7))
        rho = 1000.*ECData.(fields{flag(:, 7)});
        q = ECData.(fields{flag(:, 5)})./rho;
    else
        error('Cannot find density field in ECData Structure. Density is needed when using absolute Humidity input');
    end
elseif any(flag(:, 6))
    q = ECData.(fields{flag(:, 6)});
else
    error('Cannot find humidity field in ECData Structure');
end

%l1 in um
l1 = info.LASwavelen*1E6;

Ct2_fw = NaN*ones(length(OMS.Cn2(:, 2:end)), 1);
Ctq_fw = Ct2_fw;
Cq2_fw = Ct2_fw;
r_tq_fw = Ct2_fw;

Ct2_son = Ct2_fw;
Ctq_son = Ct2_fw;
Cq2_son = Ct2_fw;
r_tq_son = Ct2_fw;

Ct2_slow = Ct2_fw;
Ctq_slow = Ct2_fw;
Cq2_slow = Ct2_fw;
r_tq_slow = Ct2_fw;
%%A = nan.*ones(length(Ct2_fw), 4);

%Structure parameters
for ii=1:length(OMS.Cn2(:, 2:end))
    check = [OMS.Cn2(ii, 2:end), T_fw(ii), P(ii), q(ii)];
    if ~isnan(sum(check))
        [Ct2_fw(ii), Ctq_fw(ii), Cq2_fw(ii), r_tq_fw(ii), ~] = ...
            scint_StructParams(OMS.Cn2(ii, 2:end)', T_fw(ii), P(ii), q(ii), l1, info.rTqAssume, r_Tq_tmp(ii));
    end
    check = [OMS.Cn2(ii, 2:end), T_son(ii), P(ii), q(ii)];
    if ~isnan(sum(check))
        [Ct2_son(ii), Ctq_son(ii), Cq2_son(ii), r_tq_son(ii), ~] = ...
            scint_StructParams(OMS.Cn2(ii, 2:end)', T_son(ii), P(ii), q(ii), l1, info.rTqAssume, r_Tq_tmp(ii));
    end
    check = [OMS.Cn2(ii, 2:end), T_slow(ii), P(ii), q(ii)];
    if ~isnan(sum(check))
        [Ct2_slow(ii), Ctq_slow(ii), Cq2_slow(ii), r_tq_slow(ii), ~] = ...
            scint_StructParams(OMS.Cn2(ii, 2:end)', T_slow(ii), P(ii), q(ii), l1, info.rTqAssume, r_Tq_tmp(ii));
    end
end
OMS.StructParam = [OMS.MWSC(:, 1), Ct2_fw, Ctq_fw, Cq2_fw, r_tq_fw,...
    Ct2_son, Ctq_son, Cq2_son, r_tq_son,...
    Ct2_slow, Ctq_slow, Cq2_slow, r_tq_slow];
OMS.StructParamHeader = {'Timestamp', 'Ct2_fw', 'Ctq_fw', 'Cq2_fw', 'r_tq_fw',...
    'Ct2_son', 'Ctq_son', 'Cq2_son', 'r_tq_son',...
    'Ct2_slow', 'Ctq_slow', 'Cq2_slow', 'r_tq_slow'};

% % OMS.StructCoeff = A;
% % OMS.StructCoeffHeader = {'A_T_1', 'A_q_1', 'A_T_2', 'A_q_2'};