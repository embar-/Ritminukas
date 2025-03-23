function [SimIn,fiksuoti_ir_kint_param_struct]=r_vars2simstruct(SimModel,keiciamu_param_vardai,keiciamu_prad_param_reiksmes,fiksuoti_param,fizio_datasets,trukme,varargin)
%% SimIn=r_vars2simstruct(SimModel,kintam_pavad,keiciami_param_reiksmes,fiksuoti_param,fizio_datasets,trukme,varargin)
% Įvairių kintamųjų perkėlimas į spec. Simulink struktūrą
%
% (c) 2020-2022 Kauno technologijos universitetas
% (c) 2020-2022 Mindaugas Baranauskas

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

SimIn = Simulink.SimulationInput(SimModel);
fizio_flds=fieldnames(fizio_datasets);
if ~(all(ismember({'Rt' 'kvepavimas'},fizio_flds)))
    error('Privaloma fizio_datasets struktūroje pateikti širdies ritmo "Rt" ir kvėpavimo "kvepavimas" timeseries kintamuosius.')
end
for i=1:numel(fizio_flds)
    SimIn = setVariable(SimIn,fizio_flds{i},fizio_datasets.(fizio_flds{i}),'Workspace',SimModel);
end
fiksuoti_kint_flds=fieldnames(fiksuoti_param);
for i=1:numel(fiksuoti_kint_flds)
    SimIn = setVariable(SimIn,fiksuoti_kint_flds{i},fiksuoti_param.(fiksuoti_kint_flds{i}),'Workspace',SimModel);
end
for i=1:numel(keiciamu_prad_param_reiksmes)
    SimIn = setVariable(SimIn,keiciamu_param_vardai{i},keiciamu_prad_param_reiksmes(i),'Workspace',SimModel);
end
if length(trukme) < 2
    SimIn = SimIn.setModelParameter('StopTime',num2str(trukme));
else
    SimIn = SimIn.setModelParameter('StartTime',num2str(trukme(1)),'StopTime',num2str(trukme(2)));
end
if nargout > 1
    fiksuoti_ir_kint_param_struct=cell2struct([struct2cell(fiksuoti_param);num2cell(keiciamu_prad_param_reiksmes(:))],[fieldnames(fiksuoti_param); keiciamu_param_vardai(:)]);
end
