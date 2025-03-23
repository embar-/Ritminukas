function [indeksai, hrSeka, rrSeka] = fun_qrsDetector(data, nejautra, Fs)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % FUNCTION: R wave detection
    % A modified Pan-Tompkins (1985) algorithm
    
    % 
    % AUTHORS:  Andrius Petrenas (Kauno technologijos universitetas)
    % DATE:     2019-03-13
    %
    % USAGE: 
    % data - 
    % nejautra = Fs*0.4 % 400 ms (sirdies ritmas 150 k/min)
    % Fs - 
    %
    % RETURN VALUES:
    % indeksai - 
    % hrvSeka - 
    % rrSeka - 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

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
    
    %% EKG signalo filtravimas
    [bLp, aLp] = butter(2,30/(Fs/2),'low');  % 30 Hz
    [bHp, aHp] = butter(2,10/(Fs/2),'high'); % 10 Hz
    dataN = filtfilt(bLp,aLp,data);
    dataN = filtfilt(bHp,aHp,dataN);
    
    %% R darteliu isryskinimas (signalo paruosimas)
    data_temp = dataN.^3;
    [dataN, ~] = func_envelope(data_temp);
    dataN = dataN';
    rmsValue = sqrt(sum(dataN.*conj(dataN))/size(dataN,1));

    %% kintamieji
    rrIndNew = 0;
    rrIndOld = 0;
    ekgSampleNew = 0;
    rrSeka = [];
    hrSeka = [];
    slenkscioSeka = [];
    indeksai = [];
    iNejautra = nejautra + 1;
    rSlenkstis = rmsValue/5;
    
    %% R danteliu radimas
    for i = 1:length(dataN) % ciklas kiekvienai EKG atskaitai
        ekgSampleTemp = dataN(i, 1);
        ekgSampleOld = ekgSampleNew;
        ekgSampleNew = ekgSampleTemp;
        if(iNejautra>nejautra) % ar praeitas nejautros etapas?
            if(ekgSampleNew > rSlenkstis)
                if(ekgSampleNew>ekgSampleOld)
                    rrIndNew = i;
                else
                    if  rrIndNew > rrIndOld
                        if rrIndNew+10 < length(dataN)
                            interv = data(rrIndNew-10:rrIndNew+10);
                            [pks,locs] = findpeaks(interv);
                            if ~isempty(locs)
                                [~, ml] = max(pks);
                                rrIndNew2 = rrIndNew+(locs(ml)-10-1);
                                rrIndNew = rrIndNew2;
                            end
                        end
                        indeksai = [indeksai  rrIndNew];
                        slenkscioSeka = [slenkscioSeka rSlenkstis];
                        RRI = ((rrIndNew - rrIndOld)/Fs)*1000; % in ms
                        HR = (Fs*60)/(rrIndNew - rrIndOld);
                        hrSeka = [hrSeka HR];
                        rrSeka = [rrSeka RRI];
                        rrIndOld = rrIndNew;
                        iNejautra = 0;
                    end
                end
            end
        end
        iNejautra = iNejautra + 1;
    end
    
    %% Patikslinimas (pasalinamas nereikalingos reiksmes)
    hrSeka(1) = [];
    rrSeka(1) = [];



function [upperenv, lowerenv] = func_envelope(sig, method)
% Find upper and lower envelopes of a given signal
% The idea is from Envelope1.1 by Lei Wang, but here it works well when the signal contains
% successive equal samples and also includes first and last samples of the signal in the envelopes.
% inputs:
%   sig: vector of input signal
%   method: method of interpolation (defined as in interp1)
% outputs:
%   upperenv: upper envelope of the input signal
%   lowerenv: lower envelope of the input signal
if nargin == 1 
    method = 'linear';
end
upperind = find(diff(sign(diff(sig))) < 0) + 1;
lowerind = find(diff(sign(diff(sig))) > 0) + 1;
f = 1;
l = length(sig);
try
    upperind = [f upperind l];
    lowerind = [f lowerind l];
catch 
    upperind = [f; upperind; l];
    lowerind = [f; lowerind; l];
end
xi = f : l;
upperenv = interp1(upperind, sig(upperind), xi, method, 'extrap');
lowerenv = interp1(lowerind, sig(lowerind), xi, method, 'extrap');

