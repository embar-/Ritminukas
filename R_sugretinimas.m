function [Rt_greta,Rtm_greta,RRI_laiku_prasislinkimas,SR_mdl]=R_sugretinimas(Rt,Rtm,modeliuojamas_laikotarpis,issamios_klaidos)

% (c) 2022-2023 Kauno technologijos universitetas
% (c) 2022-2023 Mindaugas Baranauskas

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
        if nargin<4
            issamios_klaidos=0;
        else
            ws=warning('on');
            wv=warning('verbose','off'); % 
            wb=warning('backtrace'); % tik būseną nuskaityti
        end
        Rt=Rt(:);
        Rtm=Rtm(:);
        Rt_greta=Rt(Rt >= modeliuojamas_laikotarpis(1) & Rt <= modeliuojamas_laikotarpis(2));
        Rtm_greta=Rtm(Rtm >= modeliuojamas_laikotarpis(1) & Rtm <= modeliuojamas_laikotarpis(2));
        RtpergreituN=0;
        Rtpergreitas=find(Rt_greta(2:min(length(Rt_greta),length(Rtm_greta)))<Rtm_greta(1:min(length(Rt_greta),length(Rtm_greta))-1),1,'first');
        while ~isempty(Rtpergreitas)
            RtpergreituN=RtpergreituN+1;
            if issamios_klaidos
                if RtpergreituN == 1
                    warning('Virtualus/modeliuotas R užsivėlino daugiau nei per vieną tikrąjį R.');
                    warning('backtrace','off');
                end
                warning(' Įterpiamas NaN kaip tikrojo R nr. %d (%f s) pora', Rtpergreitas, Rt_greta(Rtpergreitas));
            end
            Rtm_greta=[Rtm_greta(1:Rtpergreitas-1); NaN; Rtm_greta(Rtpergreitas:end)];
            Rtpergreitas=find(Rt_greta(2:min(length(Rt_greta),length(Rtm_greta)))<Rtm_greta(1:min(length(Rt_greta),length(Rtm_greta))-1),1,'first');
        end
        if length(Rt_greta) ~= length(Rtm_greta) 
            if issamios_klaidos && abs(length(Rt_greta)-length(Rtm_greta))>1 
            % jei jie skiriasi – tai turėtų būti modelio klaida...
            % bet paklaidą per 1 galima toleruoti, galbūt po paskutinio tikro nespėjo atsirasti modeliuotas per modeliavimo laką
                warning('Nors įjungtas R gretinimas, bet netikėtai nesutampa \n\t tikrų (N=%d) ir virtualių (N=%d) dūžių skaičius.', length(Rt_greta), length(Rtm_greta))
            end
            R_greta_N=min(length(Rt_greta),length(Rtm_greta));
            Rt_greta =Rt_greta( 1:R_greta_N);
            Rtm_greta=Rtm_greta(1:R_greta_N);
        end
        if nargout >= 3
            RRI_laiku_prasislinkimas=Rt_greta-Rtm_greta; % čia <tikras minus modeliuotas>, bet ŠR paklaidos atvirškčiai <modeliuotas minus tikras>
        end
        if nargout >= 4
            SR_mdl=60./(diff(Rt_greta)-RRI_laiku_prasislinkimas(2:end));
        end
        if issamios_klaidos
            warning(ws);
            warning(wv);
            warning(wb);
        end
        