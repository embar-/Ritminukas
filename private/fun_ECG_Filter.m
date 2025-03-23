function [ecg] = fun_ECG_Filter(Fs_ekg, ecg)

% (c) 2019 Kauno technologijos universitetas

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Ši programa yra laisva. Jūs galite ją platinti ir/arba modifikuoti
% remdamiesi Free Software Foundation paskelbtomis GNU Bendrosios
% Viešosios licencijos sąlygomis: 3 licencijos versija, arba (savo
% nuožiūra) bet kuria vėlesne versija.
%
% Ši programa platinama su viltimi, kad ji bus naudinga, bet BE JOKIOS
% GARANTIJOS; taip pat nesuteikiama jokia numanoma garantija dėl TINKAMUMO
% PARDUOTI ar PANAUDOTI TAM TIKRAM TIKSLU. Daugiau informacijos galite 
% rasti pačioje GNU Bendrojoje Viešojoje licencijoje.
%
% Jūs kartu su šia programa turėjote gauti ir GNU Bendrosios Viešosios
% licencijos kopiją; jei ne - žr. <https://www.gnu.org/licenses/>.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%%

    %% ECG Low-pass, cut off frequency ECG - 35 Hz
    ecg = ((ecg/8)*2.4)/(2^24)/100;
    N1 = 2;
    fc1 = 35;
    [b1,a1] = butter(N1,fc1*2/Fs_ekg,'low');
    ecg = filtfilt(b1,a1,ecg);
    
    %% ECG High-pass, cut off frequency 0.4 Hz
    fc2 = 0.4;
    N2 = 4;
    [b2,a2] = butter(N2,fc2*2/Fs_ekg,'high');
    ecg = filtfilt(b2,a2,ecg);
    
    %% ECG Rejection filter, cut off frequency 50Hz 
    b3 = [1, -1.6181 1];
    a3 = [1,-1.5452, 0.912];
    ecg = filtfilt(b3,a3,ecg);
end
