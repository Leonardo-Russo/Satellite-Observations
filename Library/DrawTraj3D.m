function DrawTraj3D(Sat)
% Description:
% Create a 3D Plot of the propagated orbit and save it into
% a pdf file.

rMatrixECEF = Sat.rMatrixECEF;

X = rMatrixECEF(:, 1);
Y = rMatrixECEF(:, 2);
Z = rMatrixECEF(:, 3);

M = length(Sat.Observable);

X_obs = [];
X_unobs = [];
Y_obs = [];
Y_unobs = [];
Z_obs = [];
Z_unobs = [];

for j = 1 : M
    
    if Sat.Observable(j)
        X_obs = [X_obs; X(j)];
        Y_obs = [Y_obs; Y(j)];
        Z_obs = [Z_obs; Z(j)];
    else
        X_unobs = [X_unobs; X(j)];
        Y_unobs = [Y_unobs; Y(j)];
        Z_unobs = [Z_unobs; Z(j)];
    end

end

fig_title = strcat("Orbit of the Satellite ", Sat.Name);

figure('Name', fig_title, 'NumberTitle', 'off')

[x,y,z]=sphere;

I = imread('terra.jpg');

surface(6378.1363*x, 6378.1363*y, 6378.1363*z, flipud(I), 'FaceColor', 'texturemap', 'EdgeColor', 'none', 'CDataMapping', 'direct')

hold on
plot3(X_obs,Y_obs,Z_obs,'Color','#ff7403', 'Marker', '.','MarkerSize', 10, 'Linestyle', 'none')
plot3(X_unobs,Y_unobs,Z_unobs,'Color','#34c1e0', 'Marker', '.','MarkerSize', 5, 'Linestyle', 'none')
plot3(0,0,0,'g*')
hold off
grid on
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
view([130,25])


end