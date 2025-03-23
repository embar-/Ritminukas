function [rz, vardas2, busena]=ritminukas(vardas, katalogas_su_rinkmena, parinktys)

% [rz, vardas2]=ritminukas(vardas,rinkmena, parinktys)
%
%
% Įvedimo kintamieji:
%    vardas    - pavadinimas saugant rezultatus;
%    rinkmena  - vienos rinkmenos vardas su pilnu keliu iki jos;
%    parinktys - parinkčių struktūra, kurią perduoda u_RITMINUKAS_GUI
%
% Išvedimo kintamieji:
%    rz        - duomenys išvedimui į TXT, kurį atlieka u_RITMINUKAS_GUI
%    vardas2   - paveikslėlio ar kitas alternatyvus pavadinimas
%    busena    - 1=įrašytas naujas MAT, 0=liko pradiniai duoti, -1=nerado gero sprendimo, -2=netaikoma/neaišku
%
% (c) 2020-2023 Kauno technologijos universitetas
% (c) 2020-2023 Mindaugas Baranauskas

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


%% Paruošimas ir parinktys
disp(datestr(now,'yyyy-mm-dd HH:MM:SS'))
tic
rz=[];
busena=-2;

if ischar(parinktys)
    if exist(parinktys,'file')
        MAT_kintamieji_parinkt = who('-file', parinktys);
        if ismember('parinktys',MAT_kintamieji_parinkt)
            load(parinktys, 'parinktys'); % parinktys kaip tekstas turėtų būti pakeistas į struktūrą
        end
    end
end
if ~isstruct(parinktys)
    error('Kintamasis "parinktys" nėra nei struktūra, nei MAT rinkmena su struktūra "parinktys".')
end

if isfield(parinktys,'modelis') && ischar(parinktys.modelis) && ...
   exist(fullfile(fileparts(which(mfilename)),[parinktys.modelis '.slx']),'file')
    modelis=parinktys.modelis;
elseif exist(fullfile(fileparts(which(mfilename)),'ritminukas25.slx'),'file')
    modelis='ritminukas25';
elseif exist(fullfile(fileparts(which(mfilename)),'ritminukas24.slx'),'file')
    modelis='ritminukas24';
elseif exist(fullfile(fileparts(which(mfilename)),'ritminukas23.slx'),'file')
    modelis='ritminukas23';
elseif exist(fullfile(fileparts(which(mfilename)),'ritminukas22.slx'),'file')
    modelis='ritminukas22';
elseif exist(fullfile(fileparts(which(mfilename)),'ritminukas21.slx'),'file')
    modelis='ritminukas21';
else
    mfilename_katal=fileparts(which(mfilename));
    matomi_modeliai=filter_filenames(fullfile(mfilename_katal,['ritminukas' '*.slx']));
    matomi_modeliai=regexprep(matomi_modeliai,['^' mfilename_katal filesep ],'');
    matomi_modeliai=regexprep(matomi_modeliai,'.slx','');
    
    if iscellstr(matomi_modeliai) && ~isempty(matomi_modeliai) %#ok
        if length(matomi_modeliai) == 1
            modelis=matomi_modeliai{1};
            wb=warning('backtrace','off');
            warning('Aptiktas modelis: %s', modelis)
            warning(wb);
        else
            disp('Matomi modeliai:')
            fprintf('  %s\n',matomi_modeliai{:})
            error('Automatiškai aptiktas daugiau nei vienas Simulink modelis.')
        end
    elseif ischar(matomi_modeliai) % netikėta
        modelis=matomi_modeliai;
    else
        error('Nerastas arba nurodytas netikėtas Simulink modelis.')
    end
end

paklaidos_ivertis=NaN;
%{
paklaida_sr=NaN;
paklaida_bp=NaN;
bauda=NaN;
%}
[katalogas,rinkmena]=fileparts(katalogas_su_rinkmena);
if isempty(vardas)
    vardas=rinkmena;
end
if ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
    rezu_mat_rinkmena=katalogas_su_rinkmena;
else
    if ~isfield(parinktys,'trukme') || isempty(parinktys.trukme)
        priesaga='';
    elseif length(parinktys.trukme) == 1
        priesaga=[ '_' num2str(round(parinktys.trukme)) ];
    else
        priesaga=[ '_' num2str(floor(parinktys.trukme(1))) '-' num2str(round(parinktys.trukme(2))) ];
    end
    if ~isempty(regexp(katalogas_su_rinkmena, ['.' modelis priesaga '.*.mat$'], 'once'))
        % nurodyta rinkmena yra ankstesni rezultatai - ne pradinis fiziologinių duomenų rinkinys
        rezu_mat_rinkmena=katalogas_su_rinkmena;
    elseif isfield(parinktys,'saugoti_parametrus_poaplankyje') && ~isempty(parinktys.saugoti_parametrus_poaplankyje) && ...
          ~isequal(parinktys.saugoti_parametrus_poaplankyje,0) && ~isequal(parinktys.saugoti_parametrus_poaplankyje, false)
        if ischar(parinktys.saugoti_parametrus_poaplankyje)
            rezu_mat_rinkmena=fullfile(katalogas,parinktys.saugoti_parametrus_poaplankyje,[rinkmena '.' modelis priesaga '.mat']);
        elseif isequal(parinktys.saugoti_parametrus_poaplankyje,1) || isequal(parinktys.saugoti_parametrus_poaplankyje, true)
            rezu_mat_rinkmena=fullfile(katalogas,priesaga(2:end),[rinkmena '.' modelis priesaga '.mat']);
        elseif isnumeric(parinktys.saugoti_parametrus_poaplankyje)
            rezu_mat_rinkmena=fullfile(katalogas,num2str(parinktys.saugoti_parametrus_poaplankyje),[rinkmena '.' modelis priesaga '.mat']);
        end
    else
        rezu_mat_rinkmena=fullfile(katalogas,[rinkmena '.' modelis priesaga '.mat']);
    end
end
if ~isfield(parinktys,'laikas') || ~ischar(parinktys.laikas) || isempty(parinktys.laikas)
    parinktys.laikas=datestr(now, 'yyyy-mm-dd_HHMMSS');
end
paveikslo_priesaga='';
% perdavimui į f-ją „r_modelio_1prasukimas“ 
kita.modelis=modelis;
kita.vardas=vardas;
if isfield(parinktys,'zymekliai')
    kita.zymekliai=parinktys.zymekliai;
end
if isfield(parinktys,'issamesne_iteraciju_info')
    kita.issamesne_iteraciju_info=parinktys.issamesne_iteraciju_info;
end
if ~isfield(parinktys,'rodyti_grafikus') || isempty(parinktys.rodyti_grafikus) || parinktys.rodyti_grafikus
    kita.rodyti_grafikus=1;
else
    kita.rodyti_grafikus=0;
end
if ~isfield(parinktys,'saugoti_grafikus') || isempty(parinktys.saugoti_grafikus)
    parinktys.saugoti_grafikus=1;
end
if isfield(parinktys,'paklaidos_sudedamosios') && ~isempty(parinktys.paklaidos_sudedamosios)
    kita.paklaidos_sudedamosios=parinktys.paklaidos_sudedamosios;
    paveikslo_priesaga=[paveikslo_priesaga '_Pg' sprintf('%s', parinktys.paklaidos_sudedamosios{1}) sprintf('+%s', parinktys.paklaidos_sudedamosios{2:end}) ];
end
if isfield(parinktys,'R_greta') && ~isempty(parinktys.R_greta)
    kita.R_greta=parinktys.R_greta;
else
    kita.R_greta=0;
end

if ischar(parinktys)
    if exist(parinktys,'file')
        MAT_kintamieji = who('-file', parinktys);
        if ismember('parinktys',MAT_kintamieji)
            load(parinktys, 'parinktys'); % parinktys kaip tekstas turėtų būti pakeistas į struktūrą
        end
    end
end
if isempty(parinktys)
    warning('Nenurodytos parinktys');
    parinktys=struct();
end
if ~isstruct(parinktys)
    error('Kintamasis "parinktys" nėra nei struktūra, nei MAT rinkmena su struktūra "parinktys".')
end


%% Įkėlimas
Ar_turim_fizio=0;
if exist(rezu_mat_rinkmena,'file')
    seni=load(rezu_mat_rinkmena);
end
if ~isequal(rezu_mat_rinkmena, katalogas_su_rinkmena) && ...
   ~isempty(regexp(katalogas_su_rinkmena, ['.' modelis '.*.mat$'], 'once'))
    seni2=load(katalogas_su_rinkmena);
    for fld={'parinktys' 'modelis' 'fizio_datasets' 'fiksuoti_param' ...
             'keiciamu_param_vardai' 'keiciamu_param_prad_reiksmes' 'optimalus_param'}
         fld1=fld{1};
         if isfield(seni2,fld1)
            seni.(fld1)=seni2.(fld1);
         end
    end
end
if exist('seni','var') && isstruct(seni)
    if isfield(seni,'fizio_datasets') && isstruct(seni.fizio_datasets) && ...
            isfield(seni.fizio_datasets,'Rt') && isfield(seni.fizio_datasets,'kvepavimas')
        fizio_datasets=seni.fizio_datasets;
        Ar_turim_fizio=1;
        wb=warning('backtrace','off');
        %warning('Rinkmena jau apdorota, fiziologiniai duomenys imami iš:\n %s', rezu_mat_rinkmena);
        warning('Rinkmena jau apdorota, fiziologiniai signalai irgi imami iš jos.')
        warning(wb);
    elseif ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
        %warning('Rinkmena jau apdorota, bet neturi fiziologinių duomenų:\n %s', rinkmena_irasymui);
        %warning('Rinkmena rezultatams jau yra, gal jau apdorota anksčiau?') % Bet nuskai
    end
end
amzius=[];
if ~Ar_turim_fizio && ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
    [fizio_datasets, amzius, visakita]=r_ikelk_fizio_signalus(katalogas_su_rinkmena, modelis);
    if ~exist('seni','var') && ~isempty(visakita)
        seni=visakita;
        if ~isempty(regexp(katalogas_su_rinkmena, ['.' modelis '.*.mat$'], 'once'))
            rezu_mat_rinkmena=katalogas_su_rinkmena;
        end
    end
    clear visakita
end
if (isfield(fizio_datasets,'abp') && isempty(fizio_datasets.abp)) || ( isfield(parinktys,'ABP') && ~parinktys.ABP )
   % || ( ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'}) && ~ismember('abp',fieldnames(fizio_datasets)) )
    fizio_datasets.abp=[0 0];
    
    if ~isfield(parinktys,'R_tikras') || ... % R_tikras nenurodytas
       (isfield(parinktys,'R_tikras') && ~isempty(parinktys.R_tikras) && parinktys.R_tikras) % R_tikras=1
        paveikslo_priesaga=[paveikslo_priesaga '_KSpgRtikr'];
    elseif ~kita.R_greta
        paveikslo_priesaga=[paveikslo_priesaga '_KSpilnaiModel'];
    end
elseif strcmpi(modelis,'ritminukas25str') && ~isfield(fizio_datasets,'abp')
    error('Fiziologiniuose duomenyse privalomai turi būti ABP, jei norite naudoti su %s modeliu', modelis)
else
    paveikslo_priesaga=[paveikslo_priesaga '_KSsigOrig'];
end
if kita.R_greta
    paveikslo_priesaga=[paveikslo_priesaga '_Rgrt'];
end
if exist(fullfile(pwd,[vardas '_' parinktys.laikas paveikslo_priesaga '.png']),'file')
    laiko_priesaga=datestr(now, 'yyyy-mm-dd_HHMMSS');
else
    laiko_priesaga=parinktys.laikas;
end
paveikslo_priesaga=['_' laiko_priesaga paveikslo_priesaga];
vardas2=[vardas paveikslo_priesaga];
        
        
%% Parametrai: keičiami ir fiksuoti

kintam_pavad=parinktys.modelio_kintamieji(:,1);
% if ismember(modelis,{'ritminukas24str' 'ritminukas25str'})
%     kintam_i=find(ismember(kintam_pavad,{'Sparas' 'HRbasal' 'Drsa' 'Krsa' 'Trsa' 'Kcvlm' 'Dcvlm' 'Arvlm_sp' 'Arvlm_mx' 'Ks' 'Tmsna' 'Pk' 'Kb' 'Peq' 'Kab' 'Bmax'}));
%     parinktys.modelio_kintamieji=parinktys.modelio_kintamieji(kintam_i,:);
%     kintam_pavad=parinktys.modelio_kintamieji(:,1);
% end
%{ Galbūt tik RSA?
kita.beprasmiai_fiksuoti_kintamieji={};
kintam_i=ismember(kintam_pavad,{'Kb' 'Bmax'}); % jei bent vieno reikmė 0 ir visi išjungti – baro išjungtas
if any(cell2mat(parinktys.modelio_kintamieji(kintam_i,2)) == 0) && ~any(cell2mat(parinktys.modelio_kintamieji(kintam_i,end)))
    % baro išjungtas
    beprasmiai_fiksuoti_kintamieji1={'Pk' 'Kb' 'Peq' 'Kab' 'Bmax'};
    kita.beprasmiai_fiksuoti_kintamieji=[kita.beprasmiai_fiksuoti_kintamieji beprasmiai_fiksuoti_kintamieji1];
    fprintf('Barorecepcija išjungta, šie kintamieji neturės poveikio:\n %s\n', sprintf('%s ',beprasmiai_fiksuoti_kintamieji1{:}))
end
kintam_i=ismember(kintam_pavad,{'Kcvlm' 'Arvlm_sp' 'Arvlm_mx' 'Ks'}); % jei bent vieno reikmė 0 ir visi išjungti – simpatinis išjungtas
if any(cell2mat(parinktys.modelio_kintamieji(kintam_i,2)) == 0) && ~any(cell2mat(parinktys.modelio_kintamieji(kintam_i,end)))
    % Išjungti simpatiniai. BET jei aktyviai naudosime Ssmpt - tai jis gali duoti aktyvumą ir įspėjimas negalios!
    beprasmiai_fiksuoti_kintamieji1={'Kcvlm' 'Dcvlm' 'Arvlm_sp' 'Arvlm_mx' 'Ks' 'Tmsna'};
    kita.beprasmiai_fiksuoti_kintamieji=[kita.beprasmiai_fiksuoti_kintamieji beprasmiai_fiksuoti_kintamieji1];
    fprintf('Simpatinis poveikis širdžiai išjungtas, šie kintamieji neturės poveikio:\n %s\n', sprintf('%s ',beprasmiai_fiksuoti_kintamieji1{:}))
end
%}
    
% for i=1:numel(kintam_pavad)
%     %assignin('base',kintam_pavad{i},parinktys.modelio_kintamieji{i,2});
%     x0.(kintam_pavad{i})=parinktys.modelio_kintamieji{i,2};
% end

% Laikotarpio/trukmės patikslinimas, jei turim Rt – R laikus
if ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'}) && isfield(fizio_datasets,'Rt')
    if ~isfield(parinktys,'trukme') || isempty(parinktys.trukme)
        parinktys.trukme=[fizio_datasets.Rt.Time(2) fizio_datasets.Rt.Time(end)];
    elseif length(parinktys.trukme) == 1
        parinktys.trukme=[fizio_datasets.Rt.Time(2) parinktys.trukme];
    else
        laikas_nuo=fizio_datasets.Rt.Time(find(fizio_datasets.Rt.Time>parinktys.trukme(1),1));
        parinktys.trukme=[laikas_nuo parinktys.trukme(2)];
    end
end

% Atsižvelgimas į AMŽIŲ
if isfield(parinktys,'apskaiciuotas_HRbasal') && parinktys.apskaiciuotas_HRbasal && ...
  ~isempty(amzius) && ~isnan(amzius) && ...
  ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
    % HRbasal = 118,1 – 0,57 × amžius; SD ~= 8 (Jose ir Collison, 1970) (Žemaitytė, 1997, p. 43).
    % HRbasal = 118 – 0,55 × amžius; vyrams (Jose ir Collison, 1970)
    % HPbasal = 119 – 0,61 × amžius; moterims (Jose ir Collison, 1970)
    HRbasal=118.1-0.57*amzius;
    fprintf('Parinktas %.0f m. amžiaus žmogaus vidinis širdies ritmas yra %.2f ±8 k/min.\n', amzius, HRbasal);
    HRbasal_varid=find(ismember(parinktys.modelio_kintamieji(:,1),'HRbasal'));
    parinktys.modelio_kintamieji(HRbasal_varid,[2:4])=num2cell(HRbasal+[0 -8 8]); %#ok
end

%keiciami_param_pradiniai=[Ks,Kp, HRbasal, Presp,Krsa, Kcvlm, R];
%keiciami_param_pradiniai=[x0.Ks,x0.Kp, x0.HRbasal, x0.Presp,x0.Krsa, x0.Kcvlm, x0.R,x0.r,x0.C,x0.L];
%keiciamu_kint_sarasas={'Ks','Kp', 'HRbasal', 'Presp','Krsa', 'Kcvlm','R','r','C','L'};
%keiciamu_kint_sarasas={'HRbasal', 'Presp','Krsa', 'Kcvlm', 'Krvlm', 'Ks', 'Tmsna', 'Kv', 'R'};
%keiciamu_kint_sarasas={'Krvlm', 'Tmsna', 'Kv', 'Kb', 'Pk', 'Pb', 'R'};
%[~,ktvti]=ismember(keiciamu_kint_sarasas,kintam_pavad);
ktvti=find(cell2mat(parinktys.modelio_kintamieji(:,end)));
keiciamu_param_vardai=parinktys.modelio_kintamieji(ktvti,1)';
keiciamu_param_prad_reiksmes=[parinktys.modelio_kintamieji{ktvti,2}];
lb=[parinktys.modelio_kintamieji{ktvti,3}]; % lb=[0,  0, 80  -0.4, 0.01, 0.05, 0.4]; % apatinės atitinkamų kintamųjų ribos
ub=[parinktys.modelio_kintamieji{ktvti,4}]; % ub=[1,  1, 110,   0, 0.4,  0.6,  1.2]; % viršutinės atitinkamų kintamųjų ribos

% Fiksuoti kintamieji
if ismember(upper(parinktys.veiksena),{'SIMUL'})
    fiksuoti_param.SIMUL=1;
else
    fiksuoti_param.SIMUL=0;
end
if isfield(parinktys,'R_greta') && ~isempty(parinktys.R_greta)
    fiksuoti_param.R_greta=double(parinktys.R_greta);
else
    fiksuoti_param.R_greta=0;
end
if isfield(parinktys,'R_tikras') && ~isempty(parinktys.R_tikras)
    fiksuoti_param.R_tikras=double(parinktys.R_tikras);
else
    fiksuoti_param.R_tikras=1;
end
if ~ismember('Ssmpt',parinktys.modelio_kintamieji(ktvti,1)')
    fiksuoti_param.Ssmpt=0;
end
if strcmp(modelis,'ritminukas21')
    fiksuoti_param.Ts=0.3;
else
    fiksuoti_param.Tbf=0.3;
end
[fxvti]=find(~ismember(kintam_pavad,keiciamu_param_vardai));
for fi=fxvti'
    fiksuoti_param.(kintam_pavad{fi})=parinktys.modelio_kintamieji{fi,2};
end

% jei įmanoma, panaudoti pakartotinai
if ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'}) || ...
  (isfield(parinktys,'ikelti_senus_kaip_pradinius') && parinktys.ikelti_senus_kaip_pradinius)
   
    if exist('seni','var') && isstruct(seni) && ...
            isfield(seni,'keiciamu_param_vardai') && iscellstr(seni.keiciamu_param_vardai) && ...
            isfield(seni,'optimalus_param') && isnumeric(seni.optimalus_param) && ...
            length(seni.keiciamu_param_vardai) == length(seni.optimalus_param)
        
        % parinktys.ikelti_senus_kaip_pradinius:
        % 1 = '...>opt' : 'tik optimizavimui'
        % 2 = 'opt>...' : 'tik optimizuotus' 
        % 3 = 'visi'    : 'visus senus į visus naujus'
        
        % seni optimalūs > ...
        if ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
            disp('Kaip pirminiai parametrai imami anksčiau išsaugotieji:')
            disp(' optimalūs > optimalūs')
        end
        
        atvejis20230127=isfield(seni,'parinktys') && isstruct(seni.parinktys)&& isfield(seni.parinktys,'laikas') && isequal(seni.parinktys.laikas(1:min(10,end)),'2023-01-27') && isfield(seni.parinktys,'modelis') && ismember(seni.parinktys.modelis,{'ritminukas24supaprastintasSAstraipsniui' 'ritminukas25str'});
        if atvejis20230127
            i=find(ismember(seni.keiciamu_param_vardai,'Drsa'));
             if ~isempty(i)
                 seni.optimalus_param(i)=1/seni.optimalus_param(i);
             end
             i=find(ismember(seni.keiciamu_param_vardai,'Dcvlm'));
             if ~isempty(i)
                 seni.optimalus_param(i)=1/seni.optimalus_param(i);
             end
        end
        
        % seni optimalūs > naujai keičiami
        if isequal(keiciamu_param_vardai,seni.keiciamu_param_vardai)
            keiciamu_param_prad_reiksmes=seni.optimalus_param;
        else
            [~,ankst_ktvti]=ismember(keiciamu_param_vardai,seni.keiciamu_param_vardai);
            for i=find(ankst_ktvti)
                keiciamu_param_prad_reiksmes(i)=seni.optimalus_param(ankst_ktvti(i));
            end
        end
        
        % seni optimalūs > fiksuoti
        if parinktys.ikelti_senus_kaip_pradinius > 1 % 2 arba 3
            if ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
                disp(' optimalūs > fiksuoti ')
            end
            fiksuoti_param_flds=fields(fiksuoti_param);
            [ankst_fxvti]=find(ismember(seni.keiciamu_param_vardai,fiksuoti_param_flds));
            for i=ankst_fxvti
                fiksuoti_param.(seni.keiciamu_param_vardai{i})=seni.optimalus_param(i);
            end
        end
        
        % seni fiksuoti > ...
        fiksuoti_param_flds_seni=setdiff(fieldnames(seni.fiksuoti_param),{'SIMUL' 'R_greta' 'R_tikras'});
        if atvejis20230127
            if ismember('Drsa',fiksuoti_param_flds_seni)
                seni.fiksuoti_param.Drsa=1/seni.fiksuoti_param.Drsa;
            end
            if ismember('Dcvlm',fiksuoti_param_flds_seni)
                seni.fiksuoti_param.Dcvlm=1/seni.fiksuoti_param.Dcvlm;
            end
        end
        
        % seni fiksuoti > naujai keičiami
        if parinktys.ikelti_senus_kaip_pradinius ~= 2 % 1='...>opt' arba 3='visi'
            if ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
                disp(' fiksuoti  > optimalūs')
            end
            [~,ankst_ktvti2]=ismember(keiciamu_param_vardai,fiksuoti_param_flds_seni);
            for i=find(ankst_ktvti2)
                keiciamu_param_prad_reiksmes(i)=seni.fiksuoti_param.(fiksuoti_param_flds_seni{ankst_ktvti2(i)});
            end
        end
        
        % seni fiksuoti > nauji fiksuoti
        if parinktys.ikelti_senus_kaip_pradinius > 2 % 3='visi'
            if ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
                disp(' fiksuoti  > fiksuoti ')
            end
            [ankst_fxvti2]=find(ismember(fiksuoti_param_flds_seni,fiksuoti_param_flds));
            for i=ankst_fxvti2'
                fiksuoti_param.(fiksuoti_param_flds_seni{i})=seni.fiksuoti_param.(fiksuoti_param_flds_seni{i});
            end
        end
        
        % nenaudojami kintamieji nuskaitymo veiksenoje pakeičiami į NaN
        if ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
            i=find(ismember(keiciamu_param_vardai,kita.beprasmiai_fiksuoti_kintamieji));
            keiciamu_param_prad_reiksmes(i)=NaN; %#ok
        end
        
        % Amžius
        if (ismember('HRbasal',seni.keiciamu_param_vardai) || ...
                (ismember('HRbasal',fiksuoti_param_flds_seni) && parinktys.ikelti_senus_kaip_pradinius ~= 2 ))...
        && isfield(parinktys,'apskaiciuotas_HRbasal') && parinktys.apskaiciuotas_HRbasal && ...
           ~isempty(amzius) && ~isnan(amzius)
       
            wb=warning('backtrace','off');
            warning('Prašėte apskaičiuoti širdies ritmą pagal amžių, bet įkelti seni parametrai, tarp kurių jau buvo HRbasal.')
            warning(wb);
            parinktys.apskaiciuotas_HRbasal=0;
        end
        
    end
else
    parinktys.ikelti_senus_kaip_pradinius=0;
end
%clear r_modelio_1prasukimas

%% Veiksenos patikslinimas ir pats darbas

if ~isfield(parinktys,'veiksena') || isempty(parinktys.veiksena) || strcmpi(parinktys.veiksena,'auto')
    if exist(rezu_mat_rinkmena,'file') || isempty(keiciamu_param_prad_reiksmes)
        parinktys.veiksena='1';
    elseif ispc || ismac
        parinktys.veiksena='optimizavimas_lygiagretus'; % 'optimizavimas' 'optimizavimas_lygiagretus'
    else % Linux
        parinktys.veiksena='optimizavimas';
    end
    fprintf('Automatiškai parinkta veiksena: %s\n', parinktys.veiksena)
else
    fprintf('Jūsų pasirinkta veiksena: %s\n', parinktys.veiksena)
end
if ismember(parinktys.veiksena,{'optimizavimas' 'optimizavimas_lygiagretus'}) && ...
   isempty(keiciamu_param_prad_reiksmes)
    warning('Pasirinkite veikseną optimizuoti pametrus, bet nepasirinkote keičiamų parametrų.')
    parinktys.veiksena='1';
end

if ismember(parinktys.veiksena,{'optimizavimas' 'optimizavimas_lygiagretus'})
    
    % Paieškos algoritmas
    if ~isfield(parinktys,'paieskos_algoritmas'   ) || isempty(parinktys.paieskos_algoritmas) || ~exist(parinktys.paieskos_algoritmas,'file')
        parinktys.paieskos_algoritmas='auto';
        fprintf('Pasirinktas paieškos algoritmas: %s\n', parinktys.paieskos_algoritmas);
    end
    if strcmpi(parinktys.paieskos_algoritmas,'auto')
        % Papildomos euristikos
        %keiciamu_param_prad_reiksmes=euristikos_ir_pavieniams(keiciamu_param_prad_reiksmes,lb,ub,keiciamu_param_vardai,fiksuoti_param,fizio_datasets,parinktys, kita);
        
        % "Auto" algoritmo pakeitimas į konkretų
        if exist('seni','var') && isstruct(seni) && isfield(seni,'paklaidos_ivertis') && seni.paklaidos_ivertis<10
            if exist('patternsearch','file')
                paieskos_algoritmas='patternsearch'; % Global Optimization Toolbox
            elseif exist('fmincon','file')
                paieskos_algoritmas='fmincon'; % Optimization Toolbox
            else
                error('Nepavyksta parinkti algoritmo parametrų paieškai ir optimizavimui...')
            end
        elseif exist('particleswarm','file')
            paieskos_algoritmas='particleswarm'; % Global Optimization Toolbox, nuo R2014b
        elseif exist('ga','file')
            paieskos_algoritmas='ga'; % Global Optimization Toolbox
        elseif exist('surrogateopt','file')
            paieskos_algoritmas='surrogateopt'; % Global Optimization Toolbox nuo MATLAB R2018b
        elseif exist('patternsearch','file')
            paieskos_algoritmas='patternsearch'; % Global Optimization Toolbox
        elseif exist('fmincon','file')
            paieskos_algoritmas='fmincon'; % Optimization Toolbox
        else
            error('Nepavyksta parinkti algoritmo parametrų paieškai ir optimizavimui...')
        end
        %paieskos_algoritmas='auto'; % vis tiek tyčia palikti auto - tik testavimui
    else
        paieskos_algoritmas=parinktys.paieskos_algoritmas;
    end
    fprintf('Naudojamas paieškos algoritmas: %s\n', paieskos_algoritmas);
    
    % Parametrai
    disp('Fiksuoti parametrai:')
    disp(rmfield(fiksuoti_param,[kita.beprasmiai_fiksuoti_kintamieji {'SIMUL' 'Ssmpt' 'Tbf'}]))
    %disp(fiksuoti_param)
    disp('Keičiami parametrai:')
    if isfield(parinktys,'issamesne_iteraciju_info') && parinktys.issamesne_iteraciju_info
        fprintf(' %8s', keiciamu_param_vardai{:}); fprintf('\n')
    else
        %fprintf('    %s\n', keiciamu_param_vardai{:})
        fprintf(' %s', keiciamu_param_vardai{:}); fprintf('\n')
    end
end

switch lower(parinktys.veiksena)
    case {'-' 'tik_nuskaityti'} % nebaigtas - testavimui
        if exist('seni','var') && isstruct(seni) && isfield(seni,'paklaidos_ivertis') % #FIXME: ir pilnai įkeliami ankstesni parametrai
            if ~isfield(seni,'parinktys') || ~isstruct(seni.parinktys) || ~isfield(seni.parinktys,'trukme')
                seni.parinktys.trukme=[NaN NaN];
            end
            if ~isfield(seni,'paklaida_sr')
                seni.paklaida_sr=NaN;
            end
            if ~isfield(seni,'paklaida_bp')
                seni.paklaida_bp=NaN;
            end
            if ~isfield(seni,'bauda')
                seni.bauda=NaN;
            end
            if ~isfield(seni,'SDNN')
                if isfield(seni,'Rt') && isfield(seni,'parinktys') && isstruct(seni.parinktys) && ...
                   isfield(seni.parinktys,'trukme') && length(seni.parinktys.trukme) == 2
                    ignoruojamas_laikotarpis_vertinant=30;
                    vertinamas_laikotarpis=[floor(seni.parinktys.trukme(1)+min(diff(seni.parinktys.trukme)/2,ignoruojamas_laikotarpis_vertinant)) seni.parinktys.trukme(2)] ;
                    seni.SDNN=std(diff(seni.Rt(seni.Rt>=vertinamas_laikotarpis(1) & seni.Rt <= vertinamas_laikotarpis(2)))*1000); % milisendėmis
                else
                    seni.SDNN=NaN;
                end
            end
            if ~isfield(seni,'prasukimuN')
                seni.prasukimuN=NaN;
            end
            if ~isfield(seni,'MSNA_poslinkis') % #FIXME: nuo MSNA galima pereiti prie tik SNA
                seni.MSNA_poslinkis=NaN;
            end
            keiciamu_param_prad_reiksmes=optimaliu_param_korekcija(keiciamu_param_prad_reiksmes,keiciamu_param_vardai);
            rz=[seni.parinktys.trukme,seni.paklaidos_ivertis,seni.paklaida_sr,seni.paklaida_bp,seni.bauda,seni.SDNN,seni.prasukimuN,seni.MSNA_poslinkis,keiciamu_param_prad_reiksmes];
            vardas2=rinkmena; % iš tiesų tai ne paveikslo pavadinimas; kadangi paveiklo nekuria, grąžina rinkmeną
            busena=0;
        else
            warning('Senų rezultatų nerasta...')
        end
        return
    case {'1'}
        % Vienkatinis prasukimas su duota kombinacija
        if isfield(parinktys,'trukme2')
            kita.trukme2=parinktys.trukme2;
        end
        kita.su_grafikais=kita.rodyti_grafikus || parinktys.saugoti_grafikus;
        kita.issamios_klaidos=1;
        kita.issamesne_iteraciju_info=1;
        kita.FixedStep=0.001;
        %kita.FixedStep=0.002;
        fiksuoti_ir_kint_param=cell2struct([struct2cell(fiksuoti_param);num2cell(keiciamu_param_prad_reiksmes(:))],[fieldnames(fiksuoti_param);keiciamu_param_vardai(:)]);
        disp('Parametrai:')
        %disp(rmfield(fiksuoti_ir_kint_param,'SIMUL'))
        disp(rmfield(fiksuoti_ir_kint_param,[kita.beprasmiai_fiksuoti_kintamieji {'SIMUL' 'Ssmpt' 'Tbf'}]))
        %disp(fiksuoti_ir_kint_param)
        disp('-----------')
        [paklaidos_ivertis,paklaida_sr,paklaida_bp,bauda,Rt,Rtm,SDNN,MSNA_poslinkis,RRI_laiku_prasislinkimas]=r_modelio_1prasukimas([], {}, fiksuoti_ir_kint_param, fizio_datasets, parinktys.trukme, kita);
        optimalus_param=keiciamu_param_prad_reiksmes;
        optimalus_param=optimaliu_param_korekcija(optimalus_param,keiciamu_param_vardai);
        rz=[parinktys.trukme,paklaidos_ivertis,paklaida_sr,paklaida_bp,bauda,SDNN,1,MSNA_poslinkis,optimalus_param];
        busena=0;
    case {'tinklelis'}
        % #TODO: Prasukimas pirminis su apibrėžtu kintamųjų reikšmių tinkleliu
    case {'optimizavimas' 'optimizavimas_lygiagretus'}
        % Optimizavimas
        TryUseParallel=strcmpi(parinktys.veiksena,'optimizavimas_lygiagretus');
        kita.su_grafikais=~TryUseParallel && (kita.rodyti_grafikus || parinktys.saugoti_grafikus);
        %if isunix && ~ismac % Linux?
           %kita.FixedStep=0.002;
           %kita.FixedStep=0.001;
           %kita.su_grafikais=1;
        %else
           kita.FixedStep=0.001;
        %end
        [optimalus_param,paklaidos_ivertis, prasukimuN]=r_modelio_param_optim(keiciamu_param_prad_reiksmes,lb,ub,keiciamu_param_vardai,fiksuoti_param,fizio_datasets,parinktys.trukme,paieskos_algoritmas,TryUseParallel,kita); %#ok
        optimalus_param=optimaliu_param_korekcija(optimalus_param,keiciamu_param_vardai);
        
        % tik atkartojimas geriausio varianto vizualizavimui
        %{
        baigti_anksciau=findobj('type','uicontrol', 'style','checkbox', 'String','Baigti anksčiau', 'Value', 1, 'Visible',1);
        if ~isempty(baigti_anksciau)
            baigti_anksciau_val=baigti_anksciau.Value;
            baigti_anksciau.Enable=0;
            baigti_anksciau.Value=0;
            baigti_anksciau.UserData=[];
        end
        %}
        fiksuoti_ir_kint_param=cell2struct([struct2cell(fiksuoti_param);num2cell(optimalus_param(:))],[fieldnames(fiksuoti_param);keiciamu_param_vardai(:)]);
        disp('Geriausio keičiamų parametrų derinio atkartojimas patikslinant:')
        disp(cell2struct(num2cell(optimalus_param(:)),keiciamu_param_vardai(:)))
        disp('-----------')
        kita.issamesne_iteraciju_info=1;
        kita.issamios_klaidos=1;
        kita.FixedStep=0.001;
        kita.su_grafikais=kita.rodyti_grafikus || parinktys.saugoti_grafikus;
        if isfield(parinktys,'trukme2')
            kita.trukme2=parinktys.trukme2;
        end
        [paklaidos_ivertis,paklaida_sr,paklaida_bp,bauda,Rt,Rtm,SDNN,MSNA_poslinkis,RRI_laiku_prasislinkimas]=r_modelio_1prasukimas([], {}, fiksuoti_ir_kint_param, fizio_datasets, parinktys.trukme, kita);
        %{
        if ~isempty(baigti_anksciau)
            baigti_anksciau.Value=baigti_anksciau_val;
            baigti_anksciau.Enable=1;
        end
        %}
        rz=[parinktys.trukme,paklaidos_ivertis,paklaida_sr,paklaida_bp,bauda,SDNN,prasukimuN,MSNA_poslinkis,optimalus_param];
    case {'ikelti_i_workspace' 'simul'}
        SimIn=r_vars2simstruct(modelis,keiciamu_param_vardai,keiciamu_param_prad_reiksmes,fiksuoti_param,fizio_datasets,parinktys.trukme);
        % Savarankiškam darbui 
        assignin('base','SimIn',SimIn);
        %for i=1:length(SimIn.Variables)
        %    assignin('base' , SimIn.Variables(i).Name, SimIn.Variables(i).Value);
        %end
        if ismember(upper(parinktys.veiksena),{'SIMUL'})
            if ~bdIsLoaded(modelis)
                open_system(modelis);
            end
            SimOut=sim(SimIn);
            assignin('base', 'SimOut', SimOut);
            busena=0;
        end
        return
end

%% Paveikslai
ar_pav_irasytas=0;
if isfield(kita,'su_grafikais') && kita.su_grafikais
    % FIXME: paveikslas turėtų būti unikalus. 
    % Tai tam tikrą atsitiktinę seką paduoti į r_modelio_1prasukimas, kuri turėtų atsirasti paveikslo savybėse (UserData? bet jis konfliktuoti gali su scroolplot atsarginiu...)
    % Bet tas turėtų išlikti vėliau galimybė ant seno Fig lango piešti naujus paveikslus
    f=findobj('type','figure','Tag','modelio_paklaida_gyvai');
    if length(f) > 1
        %a=findobj('type','axes','Tag','modelio_paklaida_gyvai');
        %f=a.Parent;
        warning('Netikėtai radome daugiau nei vieną paklaidų langą!')
    elseif ~isempty(f)
        f.Name=vardas;
        if parinktys.saugoti_grafikus && paklaidos_ivertis < 999999
            paveikslo_kelias=fullfile(pwd,[vardas2 '.png']);
            %print(f,[vardas2 '.png'],'-noui','-dpng','-r300'); % PNG saugoti be papildomų grafinių elementų
            hMygtukas=findobj(f,'Type','uicontrol','style','pushbutton');
            set(hMygtukas,'Visible',0)
            print(f,paveikslo_kelias,'-dpng','-r300'); 
            set(hMygtukas,'Visible',1)
            fprintf('Paveikslas įrašytas į \n %s\n',paveikslo_kelias);
            ar_pav_irasytas=1;
        end
        
        % dideliems paveikslams pridėti slinkimą
        if ( isfield(parinktys,'trukme2') && ( (length(parinktys.trukme2) == 2 && diff(parinktys.trukme2) >= 300) || (length(parinktys.trukme2) == 1 && parinktys.trukme2 >= 600) ) ) || ...
                ( ~isfield(parinktys,'trukme2') && (  length(parinktys.trukme ) == 2 && diff(parinktys.trukme ) >= 300 ) )
           
            try 
                % apačioje jau yra informacinis tekstas - toje vietoje dėsim slinkimą
                ParamInfoTXT=findobj(f,'Type','uicontrol','style','text','Tag','ParamInfoTXT');
                set(ParamInfoTXT,'Visible',0);
                % ašių susiejimas
                axs=findobj(f,'type','axes');
                linkaxes(axs,'x');
                % ašies slinkimo perdavimui parinkimas pagal padėtį
                ax_Ys=arrayfun(@(ax) ax.Position(2), axs); % y
                [~,ai]=min(ax_Ys); % apatinė
                axp=get(axs(ai),'Position');
                % slinktis
                sca=scrollplot3(axs(ai));
                % net jei grafikas prieš buvo paslėptas, scrollplot jį įjungia, tad slėpti vėl, jei reikia
                %set(f,'Visible',kita.rodyti_grafikus);
                % ašių padėčių atstatymai/pataisymai
                set(axs(ai),'Position',axp);
                set(get(axs(ai),'XLabel'),'Position',[0.5,-0.15,0]);
                %sca.Position=[sca.Position(1) 0.03 sca.Position([3 4])];
                sca.Position=[sca.Position(1) 0.025 sca.Position([3 4])];
                % Tačiau paslėpti ir išjungti, jei yra informacija
                if ~isempty(ParamInfoTXT)
                    fp={'WindowButtonDownFcn' 'WindowButtonUpFcn' 'WindowButtonMotionFcn' 'WindowScrollWheelFcn' 'WindowKeyPressFcn' 'WindowKeyReleaseFcn'};
                    f.UserData=get(f,fp);
                    fp2=[fp; {'' '' '' '' '' ''}];
                    set(f,fp2{:});
                    set(findobj(sca),'Visible',0);
                    set(ParamInfoTXT,'Visible',1);
                    clear fp
                end
                clear ParamInfoTXT
            catch err
                Pranesk_apie_klaida(err,[],[],0);
            end
            if parinktys.saugoti_grafikus && paklaidos_ivertis < 999999
                % saugoti tik didžiausius įrašus, nes dideliuose paveiksluose sunku ką įžiūrėti
                set(f,'Visible',1,'Tag',vardas2); % tik laikinai rodyti, kad atidarius įrašytąjį paveikslą jis būtų matomas
                try
                    savefig(f,[vardas2 '.fig'],'compact'); % FIG saugoti su papildomais grafiniais elementais
                catch err
                    Pranesk_apie_klaida(err,[],[],0);
                end
                set(f,'Tag','modelio_paklaida_gyvai');
            end
        end
        set(f,'Visible',kita.rodyti_grafikus);
        drawnow;
    end
end

%% Įrašymas 
% numatytuoju atveju – saugoti parametrus
if ~isfield(parinktys,'saugoti_parametrus') || parinktys.saugoti_parametrus
    tikrai_irasyti=0;
    if isempty(rezu_mat_rinkmena)
        % nieko neždaryti
    elseif exist(rezu_mat_rinkmena,'file')
        if exist('seni','var') && isfield(seni,'paklaidos_ivertis')
            wb=warning('backtrace','off');
            ws=warning("on");
            if paklaidos_ivertis < seni.paklaidos_ivertis
                warning('Rinkmena jau yra, bet BUS perrašyta,\n nes paklaida sumažėjo nuo %f iki %f:\n %s', seni.paklaidos_ivertis, paklaidos_ivertis, rezu_mat_rinkmena);
                tikrai_irasyti=1;
                try
                    rezu_mat_rinkmena_atsarg=regexprep(rezu_mat_rinkmena, '.mat$','_.mat');
                    if exist(rezu_mat_rinkmena_atsarg,'file')
                        try
                            movefile(rezu_mat_rinkmena_atsarg,regexprep(rezu_mat_rinkmena, '.mat$','__.mat'),'f');
                        catch
                        end
                    end
                    movefile(rezu_mat_rinkmena,rezu_mat_rinkmena_atsarg,'f');
                catch
                end
            elseif isequal(paklaidos_ivertis,seni.paklaidos_ivertis)
                busena=0;
                warning('Rinkmena jau yra ir NEBUS perrašyta,\n nes sena paklaida %f yra tokia pati kaip nauja.\n', paklaidos_ivertis);
            else
                busena=-1;
                warning('Rinkmena jau yra ir NEBUS perrašyta,\n nes sena paklaida %f mažesnė nei nauja %f.\n', seni.paklaidos_ivertis, paklaidos_ivertis);
            end
            warning(ws);
            if isfield(parinktys,'paklaidos_sudedamosios') && ~isempty(parinktys.paklaidos_sudedamosios) && ...
               isfield(seni,'parinktys') && isfield(seni.parinktys,'paklaidos_sudedamosios') && ~isempty(seni.parinktys.paklaidos_sudedamosios) && ...
              ~isequal(parinktys.paklaidos_sudedamosios,seni.parinktys.paklaidos_sudedamosios)
                warning('Skyrėsi senų ir naujai apskaičiuotų paklaidų metodika.\n Senų:  %s\n Naujų: %s', ...
                    sprintf('%s, ',parinktys.paklaidos_sudedamosios{:}),...
                    sprintf('%s, ',seni.parinktys.paklaidos_sudedamosios{:}));
            end
            warning(wb);
        end
    elseif paklaidos_ivertis < 999999
        % nurodytoje vietoje rezultatų MAT dar nebuvo, paklaida ne kosminis skaičius
        tikrai_irasyti=1;
    else
        % nurodytoje vietoje rezultatų MAT dar nebuvo, paklaida yra beveik ar tikrai begalybė
        error('Nepavyko parinkti parametrų derinio, nėra ką saugoti.')
    end
    
    irasomi_kintamieji={'modelis','parinktys',... % 'fizio_datasets',
        'keiciamu_param_prad_reiksmes','keiciamu_param_vardai','fiksuoti_param','optimalus_param',...
        'paklaidos_ivertis','paklaida_sr','paklaida_bp','bauda','Rt','Rtm','MSNA_poslinkis'};
    % Taisymui, jei kartais nebereiktų 'fizio_datasets', nors buvo įtrauktas:
    % for f=filter_filenames('./*.mat;./*/*.mat;./*/*/*.mat;./*/*/*/*.mat'); if ~isempty(f); f=f{1}; f_MAT_kintamieji = who('-file', f); if ismember('fizio_datasets',f_MAT_kintamieji); disp(f); s=load(f); s=rmfield(s,'fizio_datasets'); save(f,'-struct','s'); end; end; end; disp(' ');
    if exist('Rt','var') && ~isempty(Rt)
        irasomi_kintamieji=[irasomi_kintamieji {'Rt'}];
    end
    if exist('Rtm','var') && ~isempty(Rtm)
        irasomi_kintamieji=[irasomi_kintamieji {'Rtm'}];
    end
    if exist('RRI_laiku_prasislinkimas','var') && ~isempty(RRI_laiku_prasislinkimas)
        irasomi_kintamieji=[irasomi_kintamieji {'RRI_laiku_prasislinkimas'}];
    end
    if exist('SDNN','var') && ~isempty(SDNN)
        irasomi_kintamieji=[irasomi_kintamieji {'SDNN'}];
    end
        
    if ar_pav_irasytas
        % rezu_mat_rinkmena2=fullfile(fileparts(rezu_mat_rinkmena),[vardas2 '.mat']);
        rezu_mat_rinkmena2=fullfile(pwd,[vardas2 '.mat']);
        save(rezu_mat_rinkmena2,irasomi_kintamieji{:});
        fprintf('Rezultatai sėkmingai įrašyti į \n %s\n',rezu_mat_rinkmena2);
    end
    if tikrai_irasyti
        if ~exist(fileparts(rezu_mat_rinkmena),'dir')
            mkdir(fileparts(rezu_mat_rinkmena))
        end
        save(rezu_mat_rinkmena,irasomi_kintamieji{:});
        fprintf('Rezultatai sėkmingai įrašyti į \n %s\n',rezu_mat_rinkmena);
        busena=1;
    end
end

toc


function keiciamu_param_prad_reiksmes2=euristikos_ir_pavieniams(keiciamu_param_prad_reiksmes,lb,ub,keiciamu_param_vardai,fiksuoti_param,fizio_datasets,parinktys, kita)
paieskos_algoritmas='patternsearch';
TryUseParallel=strcmpi(parinktys.veiksena,'optimizavimas_lygiagretus');
keiciamu_param_prad_reiksmes2=keiciamu_param_prad_reiksmes;
for raktas={'Krsa' 'Bmax' 'Sparas'}
    nariai=ismember(keiciamu_param_vardai,raktas);
   
    if any(nariai)
        fprintf('Bandoma euristika dėl pradinės „%s“ reikšmės...\n', raktas{1})
        keiciamu_param_prad_reiksmes_tmp=keiciamu_param_prad_reiksmes2(~nariai);
        keiciamu_param_vardai_tmp=keiciamu_param_vardai(~nariai);
        fiksuoti_ir_kint_param_tmp=cell2struct([struct2cell(fiksuoti_param);num2cell(keiciamu_param_prad_reiksmes_tmp(:))],[fieldnames(fiksuoti_param);keiciamu_param_vardai_tmp(:)]);
        kita_tmp=kita;
        switch raktas{1}
            case {'Krsa'}
                fiksuoti_ir_kint_param_tmp.Sparas=0.5;
                fiksuoti_ir_kint_param_tmp.Arvlm_sp=0;
                fiksuoti_ir_kint_param_tmp.Bmax=0;
                kita_tmp.pakl_veiksena='rms-m';
            case {'Bmax'}
                fiksuoti_ir_kint_param_tmp.Kcvlm=0;
                fiksuoti_ir_kint_param_tmp.Arvlm_sp=0;
                kita_tmp.pakl_veiksena='rms-m';
            case {'Sparas'}
                % nieko
        end
        kita_tmp.su_grafikais=kita.rodyti_grafikus || parinktys.saugoti_grafikus;
        kita_tmp.issamios_klaidos=0;
        kita_tmp.paklaidos_sudedamosios={'SR'};
        %kita_tmp.issamesne_iteraciju_info=0;
        kita_tmp.FixedStep=0.002;
        try narioi=find(nariai);
            keiciamu_param_prad_reiksmes2(narioi)=r_modelio_param_optim(keiciamu_param_prad_reiksmes2(narioi),lb(nariai),ub(nariai),raktas,fiksuoti_ir_kint_param_tmp,fizio_datasets,parinktys.trukme, paieskos_algoritmas,TryUseParallel,kita_tmp);
            fprintf(' %s: %8.4f > %8.4f\n', raktas{1}, keiciamu_param_prad_reiksmes(narioi), keiciamu_param_prad_reiksmes2(narioi))
        catch
        end
        %clear keiciamu_param_prad_reiksmes_tmp keiciamu_param_vardai_tmp fiksuoti_ir_kint_param_tmp kita_tmp
    end
end


function optimalus_param=optimaliu_param_korekcija(optimalus_param,keiciamu_param_vardai)
% v23
if all(ismember({'Kne1' 'Kne2'},keiciamu_param_vardai))
    i=find(ismember(keiciamu_param_vardai,{'Kne1' 'Kne2'}));
    if optimalus_param(i(1)) > optimalus_param(i(2))
        optimalus_param(i)=optimalus_param(i([2 1])); % sukeisti vietomis reikšmes
    end
end
% v24
if all(ismember({'Dne1' 'Dne2'},keiciamu_param_vardai))
    i=find(ismember(keiciamu_param_vardai,{'Dne1' 'Dne2'}));
    if optimalus_param(i(1)) > optimalus_param(i(2))
        optimalus_param(i)=optimalus_param(i([2 1])); % sukeisti vietomis reikšmes
    end
end
