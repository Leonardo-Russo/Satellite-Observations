function NewSats = RemoveUnobservables(Sats)
% Description: this function takes as input the Satellites Data Structures
% and yields a new version in which there are no Unbservable Satellites.

N = length(Sats);

NewSats = [];

for i = 1 : N
    
    Sat = Sats(i);

    if any( Sat.Observable(:) == true )
        NewSats = [NewSats; Sat];
    end

end