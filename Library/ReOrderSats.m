function NewSats = ReOrderSats(Sats)

NewSats = Sats;

index = 1;
allchecked = false;

N = size(Sats,1);
M = size(Sats(1).Ra,2);

LEOSat = 0;
GEOSat = 0;

% Count the LEO and GEO Satellites
for i = 1 : N
    if Sats(i).SemiMajorAxis < 2
        LEOSat = LEOSat + 1;
    else
        GEOSat = GEOSat + 1;
    end
end

% Initialize Data Structures
Sat = struct('Name',char(zeros(1,24)),'Ra',zeros(1,M),'Dec',zeros(1,M),'Epoch',NaT(1,M),...
       'Lit_Satellite',false(1,M),'Dark_Observatory',false(1,M),'Over_Mask',false(1,M),...
       'Observable',false(1,M),'Obs_Indices',zeros(1,M),'Obs_Duration',NaT(1, M) - NaT(1),...
       'NoradID', 0, 'SemiMajorAxis', 0);

Sat_Buffer = Sat;

for k = 1 : M

    obs_mask = [];
    for i = index : N
        obs_mask = [obs_mask; Sats(i).Observable(k)];
    end

    if ~ isempty(find(obs_mask, 1))

        obs_sat = (find(obs_mask) + index) - 1;

        Sat_Buffer = Sats(obs_sat);
        Sats(obs_sat) = Sats(index);
        Sats(index) = Sat_Buffer;

        index = index + 1;

        if index == N
            allchecked = true;
            break
        end

    else
        continue
    end

end

% Split Satellites between LEO and GEO

SatsLEO = [];
SatsGEO = [];

for i = 1 : N

    if Sats(i).SemiMajorAxis < 2
        SatsLEO = [SatsLEO; Sats(i)];
    else
        SatsGEO = [SatsGEO; Sats(i)];
    end

end

LEOs = length(SatsLEO);
GEOs = length(SatsGEO);


% Create NewSats Structure by appending each Satellite
NewSats = [];

for i = 1 : LEOs
    NewSats = [NewSats; SatsLEO(i)];
end

for i = 1 : GEOs
    NewSats = [NewSats; SatsGEO(i)];
end


end