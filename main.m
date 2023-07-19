%% Observer - Leonardo Russo 2015563

close all
clear all
clc

addpath('SGP4/')
addpath('Library/')
addpath('Input/')
addpath('Output/')

%% Define Time Domain and Main Parameters

% Position of Collepardo Observatory
lat_cp = 41.7653;       % deg
long_cp = 13.3750;      % deg
alt_cp = 555;           % m

mask_angle = 15;    % deg

% Define UTC Time of Observation
obs_start_vec = [2023 05 04 20 30 00];      % [yyyy mm dd hh mm ss]    
obs_start = datetime(obs_start_vec);

obs_duration = hours(4);       % hrs
obs_end = obs_start + obs_duration;

dt60 = 60;      % Rough Time Step in seconds
dt1 = 1;        % Fine Time Step in seconds

tspan = obs_start + seconds(0 : dt60 : seconds(obs_duration))';

M = length(tspan);

% Define a Tolerance for Max Age of TLE
TLE_tol = 3;    % days


%% Read Data from TLE and EOP

% Download and Update the TLE Files
downloadTLE()
downloadTLE100()

[names, tle1s, tle2s] = get_TLE('TLE.txt');
N = length(names);   % n° of entries

% Find EOP at Observation Time
EOPf = findEOPf(obs_start_vec);
MJD = EOPf(4);
X = arcsec2rad(EOPf(5));
Y = arcsec2rad(EOPf(6));
ut1_utc = EOPf(7);
lod = EOPf(8);
dpsi = arcsec2rad(EOPf(9));
deps = arcsec2rad(EOPf(10));
dX = arcsec2rad(EOPf(11));
dY = arcsec2rad(EOPf(12));
DAT = EOPf(13);

%% Rough Propagation

Sats = [];

etas = [];
etas = [etas; 5*N/60];  % initial eta in minutes

for i = 1 : N   % cycle though satellites

    tic
    
    % Initialize Data Structure
    Sat = defineSat(M);

    % Identify i-th Satellite
    name = names(i);    % store name as string
    tle1 = tle1s(i, :);    % store TLE as char arrays
    tle2 = tle2s(i, :);
    
    % UI to Show Progress
    clc
    fprintf('Propagation of Satellite %s\n%.0f / %.0f\nETA: %.1f minutes\n', [name, i, N, mean(etas)])    
    
    Sat.Name = name;
    Sat.tle1 = tle1;
    Sat.tle2 = tle2;

    [~, ~, ~, satrec] = twoline2rv(tle1, tle2, 'c', [], [], 84);

    Sat.NoradID = satrec.satnum;
    Sat.SemiMajorAxis = satrec.a;

    % Compute TLE epoch and Check Validity
    TLE_epoch = datetime(satrec.jdsatepoch + satrec.jdsatepochf,'ConvertFrom','juliandate');
    
    if (datetime('now') - TLE_epoch) > duration(TLE_tol*24,0,0) 
        warning(strcat('I TLE del satellite ''', name,''' sono più vecchi di 3 giorni'));
    end
    
    
    for k = 1 : M   % propagation in time
        
        obs_epoch = tspan(k);
        obs_epoch_vec = datevec(obs_epoch);
        [obs_y, obs_mo, obs_d, obs_h, obs_mi, obs_s] = split_epochvec(obs_epoch_vec);

        % Observatory Coordinates in ECI
        obs_ECI = lla2eci([lat_cp, long_cp, alt_cp], obs_epoch_vec, 'IAU-2000/2006', DAT, ut1_utc, [X, Y], 'dcip', [dX, dY])' * 1e-3;   % km

        % Compute tsince as time elapsed from TLE to Observation in minutes
        tsince = minutes(obs_epoch - TLE_epoch);

        % Propagation of position to Observation Time
        [~, r_vectTEME, v_vectTEME] = sgp4(satrec, tsince);
        
        % Evaluate ttt from UTC ???
        [~, ~, jdut1, jdut1f, ~, ~, ~, ttt, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~]...
            = convtime(obs_y, obs_mo, obs_d, obs_h, obs_mi, obs_s, 0, ut1_utc, DAT);     % timezone has been set to 0
        
        jdut1 = jdut1 + jdut1f;
        
        % Convert from TEME to ECI
        [r_vectECI, v_vectECI, aeci] = teme2eci(r_vectTEME', v_vectTEME', 0, ttt, dpsi, deps);  % km, km/s
        
        % Keep the ECEF Position instead of ECI for the 3D Representation
        [r_vectECEF, ~] = teme2ecef(r_vectTEME', v_vectTEME', 0, ttt, jdut1, lod, X, Y, 2);
        Sat.rMatrixECEF(k, :) = r_vectECEF';    % store it inside Sat structure
        
        % Compute Topocentric RA and DEC
        [tRA, tDEC] = ECI2TopoRaDec(obs_ECI, r_vectECI);
        trho_vect = r_vectECI - obs_ECI;

        % Compute Azimuth and Elevation
        [rho, Az, El, drho, dAz, dEl] = rv2razel(r_vectECI, v_vectECI, deg2rad(lat_cp), deg2rad(long_cp), alt_cp*1e-3, ttt, jdut1, lod, X, Y, 0, dpsi, deps);
        % or, alternatively
        % [Az, El] = RaDec2AzEl(tRA, tDEC, lat_cp, long_cp, datestr(obs_epoch,'yyyy-mm-dd HH:MM:SS'));
        
        Az = checkAngle(Az, 'rad');
        
        Az = rad2deg(Az);
        El = rad2deg(El);

        Sat.Ra(k) = tRA;
        Sat.Dec(k) = tDEC;
        Sat.rho(k, :) = trho_vect';
        Sat.Epoch(k) = obs_epoch;

        
        %%% Visibility Checks %%%

        % Lit Satellite Check
        sat_lit = Light(r_vectECI, satrec.jdsatepoch + satrec.jdsatepochf, 'e');
        if matches(sat_lit, 'yes')
            Sat.Lit_Satellite(k) = true;
        end

        % Satellite Elevation Check if Over Mask Angle
        if El > mask_angle
            Sat.Over_Mask(k) = true;
        end


        % Non-Lit Observatory Check
        obs_lit = Light(obs_ECI, satrec.jdsatepoch + satrec.jdsatepochf, 'e');
        if matches(obs_lit, 'no ')
            Sat.Dark_Observatory(k) = true;
        end

        
        % Final Visibility Check
        if Sat.Lit_Satellite(k) && Sat.Over_Mask(k) && Sat.Dark_Observatory(k)
            Sat.Observable(k) = true;
        end
    

    end

    Sats = [Sats; Sat];
    
    % Compute ETA
    eta = toc * (N-i) / 60;    % minutes
    if i <= 10
        etas = [etas; eta];
    else
        etas = [etas(2:end); eta];
    end

end

clc
fprintf('The Rough Propagation is Complete!\n')
save('Output/Rough Propagation Workspace.mat');


%% Rough Propagation Results

close all

load('Output/Rough Propagation Workspace.mat');

show_orbits = '0';

Sats = RemoveUnobservables(Sats);   % first we remove unobservables

if isempty(Sats)    % check presence of at least one visible satellite
    clc
    fprintf('No Satellite is Visible.\n')
    return
end

figure('Name', 'Not Ordered Visible Satellites')

hold on
for i = 1 : length(Sats)
    plot(Sats(i).Epoch, Sats(i).Observable * i,'*');
end
ylabel('\textit{i}', 'Interpreter','latex', 'FontSize', 12)
ylim([0.5 i+0.5])
title('Not Ordered Visible Satellites')
hold off


%%% Conflict Resolution %%%

[Sats, ~] = OrderSats(Sats);    % order satellites wrt obs time
Sats = ConflictResolution(Sats, dt60);    % resolve conflicts
[Sats, indices] = OrderSats(Sats);

figure('Name', 'Roughly Ordered Visible Satellites')

hold on
for i = 1 : length(Sats)
    plot(Sats(i).Epoch, Sats(i).Observable * i,'*');
%     text(Sats(i).Epoch(indices(i)), i+0.1, Sats(i).Name)
end
ylim([0.5 i+0.5])
title('Roughly Ordered Visible Satellites')
hold off


%%% Orbit Representation %%%

if show_orbits == '1'
    for i = 1 : length(Sats)
        DrawTraj3D(Sats(i))
    end
end


%% Precise Propagation

PreciseSats = [];

tspan = obs_start + seconds(0 : dt1 : seconds(obs_duration))';
M = length(tspan);
N = length(Sats);

for i = 1 : N

    % Initialize Data Structure
    Sat = defineSat(M);

    % Identify i-th Satellite
    name = Sats(i).Name;
    tle1 = Sats(i).tle1;
    tle2 = Sats(i).tle2;
    
    % UI to Show Progress
    clc
    fprintf('Propagation of Satellite %s %.0f / %.0f\n', [name, i, N])

    [~, ~, ~, satrec] = twoline2rv(tle1, tle2, 'c', [], [], 84);

    Sat.Name = name;
    Sat.tle1 = tle1;
    Sat.tle2 = tle2;

    Sat.NoradID = satrec.satnum;
    Sat.SemiMajorAxis = satrec.a;

    % Compute TLE epoch and Check Validity
    TLE_epoch = datetime(satrec.jdsatepoch + satrec.jdsatepochf,'ConvertFrom','juliandate');
    
    if (datetime('now') - TLE_epoch) > duration(TLE_tol*24,0,0) 
        warning(strcat('I TLE del satellite ''', name,''' sono più vecchi di 3 giorni'));
    end
    
    
    for k = 1 : M   % propagation in time
        
        obs_epoch = tspan(k);
        obs_epoch_vec = datevec(obs_epoch);

        [obs_y, obs_mo, obs_d, obs_h, obs_mi, obs_s] = split_epochvec(obs_epoch_vec);

        % Observatory Coordinates in ECI
        obs_ECI = lla2eci([lat_cp, long_cp, alt_cp], obs_epoch_vec, 'IAU-2000/2006', DAT, ut1_utc, [X, Y], 'dcip', [dX, dY])' * 1e-3;   % km

        % Compute tsince as time elapsed from TLE to Observation in minutes
        tsince = minutes(obs_epoch - TLE_epoch);

        % Propagation of position to Observation Time
        [satrec_t, r_vectTEME, v_vectTEME] = sgp4(satrec, tsince);
        
        % Evaluate ttt from UTC ???
        [~, ~, ~, ~, ~, ~, ~, ttt, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~]...
            = convtime(obs_y, obs_mo, obs_d, obs_h, obs_mi, obs_s, 0, ut1_utc, DAT);     % timezone has been set to 0
        
        % Convert from TEME to ECI
        [r_vectECI, v_vectECI, aeci] = teme2eci(r_vectTEME', v_vectTEME', 0, ttt, dpsi, deps);
        
        % Compute Topocentric RA and DEC
        [tRA, tDEC] = ECI2TopoRaDec(obs_ECI, r_vectECI);
        % or alternatively,
        % [trho,tRA,tDEC,dtrho,dtRA,dtDEC] = rv2tradc(r_vectECI, v_vectECI, lat_cp, long_cp, alt_cp, ttt, jdut1, lod, dX, dY, [], dpsi, deps);

        % Compute Azimuth and Elevation
        [Az, El] = RaDec2AzEl(tRA, tDEC, lat_cp, long_cp, datestr(obs_epoch,'yyyy-mm-dd HH:MM:SS'));

        Sat.Ra(k) = tRA;
        Sat.Dec(k) = tDEC;
        Sat.Epoch(k) = obs_epoch;

        % Visibility Checks %

        % Lit Satellite Check
        sat_lit = Light(r_vectECI,satrec.jdsatepoch + satrec.jdsatepochf,'e');      % produces text :(
        if ~ isempty(intersect(sat_lit, 'yes'))
            Sat.Lit_Satellite(k) = true;
        end


        % Il satellite è sopra la maschera di elevazione in input?
        if El > mask_angle
            Sat.Over_Mask(k) = true;
        end


        % L'osservatorio è al buio nel momento dell'osservazione? 
        obs_lit = Light(obs_ECI,satrec.jdsatepoch + satrec.jdsatepochf,'e');
        if isempty(intersect(obs_lit,'yes'))
            Sat.Dark_Observatory(k) = true;
        end

        
        % Final Visibility Check
        if Sat.Lit_Satellite(k) && Sat.Over_Mask(k) && Sat.Dark_Observatory(k)
            Sat.Observable(k) = true;
        end
    

    end

    PreciseSats = [PreciseSats; Sat];

end

clc
fprintf('The Fine Propagation is Complete!\n')
save('Output/Fine Propagation Workspace.mat');


%% Precise Propagation Results

load('Output/Fine Propagation Workspace.mat');

[Sats, indices] = OrderSats(PreciseSats);

figure('Name', 'Precisely Ordered Visible Satellites')

hold on
for i = 1 : length(Sats)
    plot(Sats(i).Epoch, Sats(i).Observable * i,'*');
    text(Sats(i).Epoch(indices(i)), i+0.1, Sats(i).Name)
end
ylim([0.5 i+0.5])
title('Precisely Ordered Visible Satellites')
hold off


%% Orchestrate File Creation

% Define Observation Duration
Sats = ObsDuration(Sats);

OrcPath = 'Output/Orchestrate.txt';

GenerateOrchestrate(OrcPath, Sats);






