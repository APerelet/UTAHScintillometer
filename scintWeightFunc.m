%Scintillometer Weighting functions
%Inputs
    %L - Pathlength [m]
    %d_Tx - seperation distance between transmitter centers [m]
    %d_Rx - seperation distance between receiver centers (from same ref point as d_Tx) [m]
    %R_r1 - radius of BLS Rx
    %R_t1 - radius of BLS Tx
    %R_r2 - radius of MWS Rx
    %R_t2 - radius of MWS Tx
    %lambda1 - BLS wavelength [m]
    %lambda2 - MWS wavelength [m]
%Outputs
    %SFF - Spectral Filter Function
    %PWF - Path Weighting function 
    
function WeightFunc = scintWeightFunc(info)

if exist([info.rootDir, filesep, 'WeightFunc.mat'], 'file')
    fprintf('\nPreviously calculated weighting functions found.\n');
    reCal = input(['Recalculate weighting functions?\n',...
        'Yes [1] / No [0]:', char(9)]);
    if reCal
        %Continue
    else
        load([info.rootDir, filesep, 'WeightFunc.mat']);
        return;
    end
else
    fprintf('\nNo previous calculated weighting function found....');
end

L = info.L;
N = info.N;
d_Tx = info.d_Tx;
d_Rx = info.d_Rx;
lambda1 = info.lambda(:, 1);
lambda2 = info.lambda(:, 2);

res_k = 50000;
x = linspace(0, L, N)';
k = linspace(0, 500, res_k);

for kk=1:length(lambda1)
    k1 = 2*pi/lambda1(kk);
    k2 = 2*pi/lambda2(kk);
    R_r1 = info.R(kk, 1);
    R_r2 = info.R(kk, 2);
    d = abs((1-x./L).*d_Tx+x./L.*d_Rx);
    PWFtmp = zeros(length(x), length(k));
    fprintf('\n--------------------------------------------------------');
    fprintf(['\nCalculating H with: L = ', num2str(L), 'm, lamba1 = ', num2str(lambda1(kk)), 'm & lambda2 = ', num2str(lambda2(kk)), 'm...']);
    H = sin((x./L.*(L-x)*k.^2)./(2*k1)).*sin((x./L.*(L-x)*k.^2)./(2*k2));
    fprintf('DONE\n');

    fprintf('\nCalculating F...');
    %1st Order Bessel Functions of the first kind
    J1{1} = besselj(1, (1-x./L)*k.*R_r1);
    J1{2} = besselj(1, x./L*k.*R_r1);
    J1{3} = besselj(1, (1-x./L)*k.*R_r2);
    J1{4} = besselj(1, x./L*k.*R_r2);

    %Aperture Averaging Term
    denom = ((1-x./L).^2.*(x./L).^2)*k.^4*R_r1^2*R_r2^2;
    F = (J1{1}.*J1{2}.*J1{3}.*J1{4})./denom;
    fprintf('DONE\n');
    %Zeroth Order Bessel Functions of the first Kind
    if k1~=k2
        J0 = besselj(0, d*k);
    else
        J0 = ones(length(x), length(k));
    end
    %Path Weighting function
    fprintf('\nPopulating Weighting Functions...\n');
    for ii=1:length(x)
        PWFtmp(ii, :)  = k.^(-8/3).*H(ii, :).*F(ii, :).*J0(ii, :);
    end
    PWFtmp(isnan(PWFtmp)) = 0;

    PWF = trapz(k, PWFtmp, 2);
    SWF = 8.448*pi^2*k1*k2.*trapz(x, PWFtmp, 1);
    G = trapz(k, SWF);
    fprintf('DONE\n');

    WeightFunc.PWF(:, 1) = x;
    WeightFunc.PWF(:, 1+kk) = PWF;
    WeightFunc.PWFHeader = {'Distance [m]', 'LAS', 'OMS', 'MWS'};
    WeightFunc.SWF(:, 1) = k;
    WeightFunc.SWF(:, 1+kk) = SWF;
    WeightFunc.SWFHeader = {'Wavenumber [m^-1]', 'LAS', 'OMS', 'MWS'};
    WeightFunc.G(:, kk) = G;
    WeightFunc.GHeader = {'LAS', 'OMS', 'MWS'};
end
    
save([info.rootDir, filesep, 'WeightFunc.mat'], 'WeightFunc');