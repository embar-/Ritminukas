function RITMINUKAS_GUI
% RITMINUKAS_GUI
% Grafinė sąsaja fiziologiniams duomenims apdoroti bei įvertinti
% urmu panaudojant širdies ritmo modelį
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

% koduotės tikrinimas
teksto_kodas='ąčęėįšųūž'+0; % lietuviškųjų mažųjų raidžių kodai
if ~isequal(teksto_kodas, [261 269 281 279 303 353 371 363 382]) % unikodo lietuviškos mažosios raidės
    try
        sena_koduote=feature('DefaultCharacterSet');
        if     isequal(teksto_kodas, [196 8230 196 168 196 8482 196 8212 196 198 197 65533 197 179 197 171 197 190]) % UTF-8 <> windows-1257
            nauja_koduote='UTF-8';
        elseif isequal(teksto_kodas, [196 8230 196 141 196 8482 196 8212 196 175 197 161 197 179 197 171 197 190]) % UTF-8 <> windows-1252
            nauja_koduote='UTF-8';
        elseif isequal(teksto_kodas, [224 232 230 235 225 240 248 251 254]) % windows-1257 <> windows-1252
            nauja_koduote='windows-1257';
        elseif isequal(teksto_kodas, [65533 65533 65533 65533 65533 65533 65533 65533 65533]) % windows-1257 <> UTF-8
            nauja_koduote='windows-1257';
        elseif length(teksto_kodas) == 9
            nauja_koduote='windows-1257';
        elseif ~strcmpi(feature('DefaultCharacterSet'),'UTF-8') && ispc
            nauja_koduote='UTF-8';
        else
            nauja_koduote='UTF-8';
            %fprintf('[']\n');
            %fprintf('%d ', teksto_kodas);
            %fprintf(''' '']\n');
        end
        if isequal(sena_koduote,nauja_koduote)
            warning('\n MATLAB atmintyje (cache) likusio %s kodas yra su kita koduote nei naudojamas kodavimas.', mfilename);
            fprintf('\n Atmintyje %s atsinaujins kai paleisite: \n \n clear(''%s'') \n', mfilename, which(mfilename));
        else
            warning('\n %s: %s -> %s. \n\n PALEISKITE %s NAUJAI! \n\n Jei ateityje norite seno kodavimo, vykdykite: \n feature(''DefaultCharacterSet'',''%s'');\n\n', r_lokaliz('Kodavimas pakeistas'), sena_koduote, nauja_koduote, mfilename, sena_koduote);
        end
        mID = fopen(which(mfilename),'a');
        if mID >= 0
            fprintf(mID,'\n');
        end
        fclose(mID);
        feature('DefaultCharacterSet',nauja_koduote);
        clear(which(mfilename))
        return;
    catch %err
        %rethrow(err)
    end
end

if isunix && ~ismac
    gui_stiliaus_keitimas
end

fgs=findobj('type','figure','Tag',mfilename);
if isempty(fgs)
    kelias=fileparts(which(mfilename));
    addpath(kelias);
    if exist(fullfile(kelias,'external'),'dir') == 7
        addpath(fullfile(kelias,'external'));
        if exist(fullfile(kelias,'load_acq_20110222','external'),'dir') == 7
            addpath(fullfile(kelias,'load_acq_20110222','external'));
        end
    end
    priklausomybiu_tikrinimas(0);
    % Jei nėra lango, sukurti
    gui_sukurimas
else
    % Jei jau yra langas, įspėti
    perspejimas=sprintf('Vienu metu patariama dirbti tik viename „%s“ grafiniame lange tam, kad nesusipjautų vykdant skaičiavimus', mfilename);
    warning(perspejimas); %#ok
    figure(fgs);
    warndlg(perspejimas,mfilename,'modal');
end

function [v,m]=versija
v='v2023-03-20';
m='ritminukas25str';

function priklausomybes=priklausomybiu_sarasas
% MATLAB
[priklausomybes.programos.rinkmenos,priklausomybes.programos.Toolbox] = matlab.codetools.requiredFilesAndProducts(mfilename);
priklausomybes.programos.rinkmenos=priklausomybes.programos.rinkmenos';
% Simulink model
[~,m]=versija;
[priklausomybes.modelio.vardai, priklausomybes.modelio.aplankai] = dependencies.toolboxDependencyAnalysis({m});

function priklausomybiu_tikrinimas(veiksena)
if nargin < 1
    veiksena=0;
end
switch veiksena
    case 0
        butini = {'MATLAB' 'Simulink' ...
            'Signal Processing Toolbox' 'Statistics and Machine Learning Toolbox' ...
            'Curve Fitting Toolbox' 'Global Optimization Toolbox'};
        nebutini={'Parallel Computing Toolbox'};
    case 1
        priklausomybes=priklausomybiu_sarasas;
        butini = {priklausomybes.programos.Toolbox( [priklausomybes.programos.Toolbox.Certain]).Name};
        nebutini={priklausomybes.programos.Toolbox(~[priklausomybes.programos.Toolbox.Certain]).Name};
end
mat_v=ver;
trukstami_butini = setdiff( butini, {mat_v.Name});
trukstami_nebutini=setdiff(nebutini,{mat_v.Name});

if ~isempty(trukstami_butini)
    toolboxai1=sprintf(' - %s\n', trukstami_butini{:});
    warn_msg=sprintf('Ritminukas naudoja, tačiau sistemoje nerasta:\n%s',toolboxai1);
else
    warn_msg='';
end
if ~isempty(trukstami_nebutini)
    toolboxai2=sprintf(' - %s\n', trukstami_nebutini{:});
    warn_msg=[warn_msg sprintf('Ritminukas rekomenduoja, tačiau sistemoje nerasta:\n%s',toolboxai2)];
end
if ~isempty(warn_msg)
    warning(warn_msg);
end

function gui_sukurimas
% Sukurk lango GUI elementus

% Pats langas
%set(0,'Units','pixels'); ekrano_dydis=get(0,'ScreenSize');
fig=figure('Name', ['Ritminukas ' versija ], 'NumberTitle','off', 'Units','pixels','Tag',mfilename); % mfilename
fig.Position=[fig.Position([1 2]) - [850 615] + fig.Position([3 4]) 850 615 ];

%% Rinkmenų parinkimas ir išvedimas
% Katalogo parinkimas duomenų įkėlimui
h.pnl_ikelimas=uipanel(fig, 'Title','Apdorotinų duomenų pagrindinis katalogas', 'Units','pixels', 'Position',[5 fig.Position(4)-55 490 50 ] );
h.katal1_txt=uicontrol(h.pnl_ikelimas, 'Style','edit', 'Units','pixels', 'HorizontalAlignment','Left', 'Position', [10 10 h.pnl_ikelimas.Position(3)-75 20], 'String',pwd);
h.katal1_v = uicontrol(h.pnl_ikelimas, 'Style','pushbutton', 'Units','pixels', 'HorizontalAlignment','Center', 'String','v',   'Position', [h.pnl_ikelimas.Position(3)-65 10 20 20 ]);
h.katal1_dlg=uicontrol(h.pnl_ikelimas, 'Style','pushbutton', 'Units','pixels', 'HorizontalAlignment','Center', 'String','...', 'Position', [h.pnl_ikelimas.Position(3)-45 10 30 20 ]);

% Katalogo parinkimas rezultatų išsaugojimui
h.pnl_saugojimas=uipanel(fig, 'Title','Rezultatų katalogas', 'Units','pixels', 'Position',[5 60 490 75 ] );
h.katal2_txt=uicontrol(h.pnl_saugojimas, 'Style','edit', 'Units','pixels', 'HorizontalAlignment','Left', 'Position', [10 35 h.pnl_saugojimas.Position(3)-75 20]);
h.katal2_v = uicontrol(h.pnl_saugojimas, 'Style','pushbutton', 'Units','pixels', 'HorizontalAlignment','Center', 'String','v',   'Position', [h.pnl_saugojimas.Position(3)-65 h.katal2_txt.Position(2) 20 20 ]);
h.katal2_dlg=uicontrol(h.pnl_saugojimas, 'Style','pushbutton', 'Units','pixels', 'HorizontalAlignment','Center', 'String','...', 'Position', [h.pnl_saugojimas.Position(3)-45 h.katal2_txt.Position(2) 30 20 ]);
h.checkbox_islaikyti_katalogu_struktura=uicontrol(h.pnl_saugojimas,'style','checkbox', 'Units','pixels', 'HorizontalAlignment','Left', 'Position',[10 0 340 30], ...
    'String','Poaplankiai atitinka įvedamų duomenų poaplankius', 'Visible','on','Value',1);
h.checkbox_islaikyti_katalogu_struktura_1pakat=uicontrol(h.pnl_saugojimas,'style','checkbox', 'Units','pixels', 'HorizontalAlignment','Left', ...
    'Position',[sum(h.checkbox_islaikyti_katalogu_struktura.Position([1 3])) 0 150 30], ...
    'String','1 poaplankio gylio', 'Visible','on','Value',1);
%h.checkbox_katalogu_struktura_smegenims_4rinkmenos=uicontrol(pnl_saugojimas,'style','checkbox', 'Units','pixels', 'HorizontalAlignment','Left', 'Position',[10 0 400 30], ...
%    'String','Rezultatams vienas poaplankis, pavadinimai [D|K]_[VS|HK] ', 'Visible','on','Value',0);

% Rinkmenų parinkimas
h.pnl_rinkmenos=uipanel(fig, 'Title','Apdorotinos rinkmenos', 'Units','pixels', 'Position',[500 5 350 fig.Position(4)-10] ); % [500 60 300 540]
h.pnl_atranka=uipanel(h.pnl_rinkmenos, 'Title','Atranka', 'Units','pixels', 'Position',[5 5 h.pnl_rinkmenos.Position(3)-10 70] );
h.rinkm=uicontrol(h.pnl_rinkmenos, 'style','listbox', 'Units','pixels', ...
    'Position',[5 h.pnl_atranka.Position(4)+5 h.pnl_rinkmenos.Position(3)-10 h.pnl_rinkmenos.Position(4)-h.pnl_atranka.Position(4)-25]);
h.rinkm_txt_rod=uicontrol(h.pnl_atranka, 'style','text', 'Units','pixels', 'FontUnits','pixels', 'FontSize', 12, 'HorizontalAlignment','Right', 'Position',[5 30 60 20], 'String','Rodyti:');
h.rinkm_txt_zym=uicontrol(h.pnl_atranka, 'style','text', 'Units','pixels', 'FontUnits','pixels', 'FontSize', 12, 'HorizontalAlignment','Right', 'Position',[5  5 60 20], 'String','Pažymėti:');
h.rinkm_fltr1=uicontrol(h.pnl_atranka, 'style','edit', 'Units','pixels', 'FontUnits','pixels', 'FontSize', 12, 'HorizontalAlignment','Center', 'Position',[70 33 170 20]);
h.rinkm_fltr1.String='*.mat;*.edf;./*/*.mat;*.edf;./*/*/*.mat;*.edf'; % '*.mat;./*/*.mat';
%h.rinkm_fltr1.String=['*.rf'       ';.' filesep '*' filesep '*.rf'        ';.' filesep '*' filesep '*' filesep '*.rf' ];
%h.rinkm_fltr1.String=[h.rinkm_fltr1.String ';' strrep(h.rinkm_fltr1.String,'.rf','.mat')];
%h.rinkm_fltr1.String=['*.rf'      ';.' filesep '*' filesep '*' filesep '*.rf' ];
h.rinkm_fltr2=uicontrol(h.pnl_atranka, 'style','edit', 'Units','pixels', 'FontUnits','pixels', 'FontSize', 12, 'HorizontalAlignment','Center', 'Position',[70  8 170 20], 'String','*');
h.rinkm_atnaujint=uicontrol(h.pnl_atranka, 'style','PushButton', 'Units','pixels', 'HorizontalAlignment','Center', 'Position',[250 17 80 30], 'String','Atnaujinti');

% Vykdymas
h.vykdyti=uicontrol(fig,'style','PushButton', 'Units','pixels', 'HorizontalAlignment','Center', 'Position',[15 15 100 30], 'String','VYKDYTI', 'FontWeight','Bold'); %, 'BackgroundColor',[0 0.75 0.75]
h.checkbox_baigti_anksciau=uicontrol(fig,'style','checkbox', 'Units','pixels', 'HorizontalAlignment','Left', 'Position',[150 15 150 30], 'String','Baigti anksčiau', 'Visible','off','Tag','Baigti anksciau');
h.checkbox_baigti_su_garsu=uicontrol(fig,'style','checkbox', 'Units','pixels', 'HorizontalAlignment','Left', 'Position',[300 15 200 30], 'String','Baigti su garsu', 'Visible','on','Tag','Visada veiksnus');


%% Skydelių perjungimas
h.tb1 = uicontrol(fig, 'style','togglebutton', 'Units','pixels','Position',[  5 fig.Position(4)-90 160 30 ], ...
    'String', 'Eiga','Tag','Visada veiksnus');
h.tb2 = uicontrol(fig, 'style','togglebutton', 'Units','pixels','Position',[170 fig.Position(4)-90 160 30 ], ...
    'String', 'Modelio parametrai', 'Tag','Visada veiksnus');
h.tb3 = uicontrol(fig, 'style','togglebutton', 'Units','pixels','Position',[335 fig.Position(4)-90 150 30 ], ...
   'String', '...','Tag','Visada veiksnus', 'Visible',0);


%% "Pre" parinktys
pnl_eiga=uipanel(fig, 'Title','', 'Units','pixels', 'Position',[5 140 490 fig.Position(4)-230 ] );
gui_eilutes_y=@(gui_eilute) pnl_eiga.Position(4)-25*gui_eilute;
gui_eil=1;

% Modelis
h.modelis_txt=uicontrol(pnl_eiga, 'style','text', 'HorizontalAlignment','left', 'String','Modelio versija:', 'Position', [10 gui_eilutes_y(gui_eil)-4 120 20]);
h.modelis=uicontrol(pnl_eiga,'style','popupmenu', 'Units','pixels', ...
     'Position', [sum(h.modelis_txt.Position([1 3])) gui_eilutes_y(gui_eil) 160 20]);
%h.modelis_v = uicontrol(pnl_eiga, 'Style','pushbutton', 'Units','pixels', 'HorizontalAlignment','Center', 'String','^',   'Position', [sum(h.modelis.Position([1 3])) gui_eilutes_y(gui_eil) 20 20 ]);

% Veiksena
gui_eil=gui_eil+1;
h.veiksena_txt=uicontrol(pnl_eiga, 'style','text', 'HorizontalAlignment','left', 'String','Veiksena:', 'Position', [10 gui_eilutes_y(gui_eil)-4 80 20]);
h.veiksena=uicontrol(pnl_eiga,'style','popupmenu', 'Units','pixels', ...
     'String',   {'(auto)' 'Tik nuskaityti senus rezultatus' 'Vienas tikslus' 'Derinio paieška optimizavimui' 'Derinio paieška op. lygiagr.' 'Rankinė' 'Tik simuliacija'}, ... %  'Parametrų tinklelio tikrinimas'
     'UserData', {'auto' 'tik_nuskaityti' '1' 'optimizavimas' 'optimizavimas_lygiagretus' 'ikelti_i_workspace' 'SIMUL'}, ... %  'tinklelis'
     'Value',1, ... 
     'Position', [sum(h.veiksena_txt.Position([1 3])) gui_eilutes_y(gui_eil) 200 20]);
% h.lygiagretus_skaiciavimas_checkbox=uicontrol(pnl_pre,'style','checkbox', 'Units','pixels', 'Position', [300 gui_eilutes_y(gui_eil) 100 20], 'Value', 1, ...
%     'String','Bandyti lygiagretus skaič.',...
%     'TooltipString','<html>Nurodykite modeliavimo trukmę ar laiko intervalą empirinių duomenų įkėlimui.</html>');
h.paieskos_algoritmas=uicontrol(pnl_eiga,'style','popupmenu', 'Units','pixels', ...
     'String',   {'(auto)' 'Pattern search' 'Surrogate optimization' 'Particle swarm opt.' 'Genetic algorithm' 'Nonlinear programming' 'MultiStart' 'GlobalSearch'}, ... %  'Parametrų tinklelio tikrinimas'
     'UserData', {'auto' 'patternsearch' 'surrogateopt' 'particleswarm' 'ga' 'fmincon' 'MultiStart' 'GlobalSearch'}, ... %  'tinklelis'
     'Value',1, ... 
     'Position', [sum(h.veiksena.Position([1 3]))+10 gui_eilutes_y(gui_eil) 150 20]);

% Trukmė / laikotarpis pagrindinis kalibravimui
gui_eil=gui_eil+1;
h.trukme_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [10 gui_eilutes_y(gui_eil) 340 20], 'Value', 1, ...
    'String','Ribota trukmė / laiko intervalas kalibravimui (po 30s)',...
    'TooltipString','<html>Nurodykite modeliavimo trukmę (jei modeliuojama nuo pradžios)<br> arba laiko intervalą (pradžią ir pabaigą) sekundėmis.<br>Kalibravimas tik pagal sumodeliuotą signalą po 30-tos modeliavimo sekundės.</html>');
h.trukme_edit=uicontrol(pnl_eiga,'style','edit', 'Units','pixels', ...
    'String','600', 'TooltipString','Trukmė arba laiko intervalas',...
    'Position', [sum(h.trukme_checkbox.Position([1 3])) h.trukme_checkbox.Position(2) 100 20]);
uicontrol(pnl_eiga, 'style','text', 'HorizontalAlignment','left', 'String','s', 'TooltipString','sekundės',...
    'Position', [sum(h.trukme_edit.Position([1 3]))+5 h.trukme_edit.Position(2)-4 100 20]);

% Trukmė / laikotarpis papildomai
gui_eil=gui_eil+1;
h.trukme2_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [10 gui_eilutes_y(gui_eil) 340 20], 'Value', 1, ...
    'String','Kita modeliuojama/rodoma trukmė/intervalas', ... %'Visible', 'off',...
    'TooltipString','<html>Nurodykite modeliavimo trukmę ar laiko intervalą empirinių duomenų įkėlimui.</html>');
h.trukme2_edit=uicontrol(pnl_eiga,'style','edit', 'Units','pixels', ... % 'Visible', 'off',...
    'String','0 900', 'TooltipString','Trukmė arba laiko intervalas',...
    'Position', [sum(h.trukme2_checkbox.Position([1 3])) h.trukme2_checkbox.Position(2) 100 20]);
uicontrol(pnl_eiga, 'style','text', 'HorizontalAlignment','left', 'String','s', 'TooltipString','sekundės',...
    'Position', [sum(h.trukme2_edit.Position([1 3]))+5 h.trukme2_edit.Position(2)-4 100 20]);

% Žymekliai
gui_eil=gui_eil+1;
h.zymekliai_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [10 gui_eilutes_y(gui_eil) 340 20], 'Value', 0, ...
    'String','Laiko žymeliai grafikams:',...
    'TooltipString','');
h.zymekliai_edit=uicontrol(pnl_eiga,'style','edit', 'Units','pixels', ...
    'String','600 780', 'TooltipString','',...
    'Position', [sum(h.zymekliai_checkbox.Position([1 3])) h.zymekliai_checkbox.Position(2) 100 20]);
uicontrol(pnl_eiga, 'style','text', 'HorizontalAlignment','left', 'String','s', 'TooltipString','sekundės',...
    'Position', [sum(h.zymekliai_edit.Position([1 3]))+5 h.zymekliai_edit.Position(2)-4 100 20]);

% naudoti senus parametrus?
gui_eil=gui_eil+1;
h.ikelti_senus_kaip_pradinius_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [10 gui_eilutes_y(gui_eil) 290 20], 'Value', 1, ...
    'String','Bandyti senus parametrus kaip pradinius:',...
    'TooltipString','');
h.ikelti_senus_kaip_pradinius_popupmenu=uicontrol(pnl_eiga,'style','popupmenu', 'Units','pixels', ...
     'Value',1, ... 
     'String',   {'tik optimizavimui' 'tik optimizuotus' 'visus'}, ...
     ... 'UserData', {'...>opt' 'opt>...' 'visi'}, ... 
     'Position', [sum(h.ikelti_senus_kaip_pradinius_checkbox.Position([1 3])) h.ikelti_senus_kaip_pradinius_checkbox.Position(2) 150 20]);

% Arterinio kraujo spaudimo signalo perdavimas 
gui_eil=gui_eil+1;
h.ABP_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [10 gui_eilutes_y(gui_eil) 450 20], 'Value', 1, ...
    'String','Tikro kraujo spaudimo signalo perdavimas (jei įmanoma)',...
    'TooltipString','');

% R tikrasis perduodamas į CO?
gui_eil=gui_eil+1;
h.R_tikras_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [30 gui_eilutes_y(gui_eil) 450 20], 'Value', 1, ...
    'String','R tikrojo perdavimas dėl kraujo srauto, kraujo spaudimo modeliavimo',...
    'TooltipString','Parinktis turi prasmę, jei kraujo spaudimo signalo nėra. Jei perduodamas tikrasis kraujo spaudimas – ši parinktis neturi reikšmės.');

% R sugretinimas (modeliuojant kaip ankstesnįjį R imti ne modeliuotąjį, o tikrąjį R laiką)?
gui_eil=gui_eil+1;
h.R_greta_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [50 gui_eilutes_y(gui_eil) 450 20], ...
    'Value', 1, 'String','R sugretinimas – naujai modeliuojamų R atskaita bus tikrų R laikas',...
    'TooltipString','Modeliuojant kaip ankstesnįjį R imti ne modeliuotąjį, o tikrąjį R laiką – leis vertinti, kiek koreguoti slenkstį iki tikrojo R atsiradimo');

% Paklaidos
gui_eil=gui_eil+1;
h.paklaidos_sudedamosios_txt=uicontrol(pnl_eiga, 'style','text', 'HorizontalAlignment','left', 'String','Paklaidos pagal:', 'Position', [10 gui_eilutes_y(gui_eil)-4 120 20]);
h.paklaidos_sudedamosios=uicontrol(pnl_eiga,'style','popupmenu', 'Units','pixels', ...
     'String',   {'(auto)' 'širdies ritmą' 'R-R intervalus' 'RRI/10' 'ŠR ir KS' 'RRI ir KS' 'RRI/10 ir KS' 'kraujo spaudimą'}, ...
     'UserData', {{'auto'} {'SR'} {'RRIms'} {'RRI/10'} {'SR' 'KS'} {'RRIms' 'KS'} {'RRI/10' 'KS'} {'KS'}}, ... 
     'Value',3, ... 
     'Position', [sum(h.paklaidos_sudedamosios_txt.Position([1 3])) gui_eilutes_y(gui_eil) 160 20]);
h.paklaidos_bauda_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [sum(h.paklaidos_sudedamosios.Position([1 3]))+10 gui_eilutes_y(gui_eil) 400 20], 'Value', 1, ...
    'String','su baudomis',...
    'TooltipString','');

% iteracijų informaciją rodyti išsamiau optimizavimo eigoje?
gui_eil=gui_eil+1;
h.issamesne_iteraciju_info_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [10 gui_eilutes_y(gui_eil) 450 20], ...
    'Value', ~ispc, 'UserData',~ispc, ...
    'String','Rodyti išsamesnę iteracijų informaciją optimizuojant (atsiliepia greitaveikai)',...
    'TooltipString','Rekomenduojama išjungti lygiagretiems skaičiavimams dėl greitaveikos');

% rodyti GRAFIKUS?
gui_eil=gui_eil+1;
h.rodyti_grafikus_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [10 gui_eilutes_y(gui_eil) 140 20], ...
    'Value', ~(ispc && strcmpi(win_vol_lbl,'0406-A308')), 'String','Rodyti grafikus', 'TooltipString','');
% saugoti GRAFIKUS?
gui_eil=gui_eil+1;
h.saugoti_grafikus_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [30 gui_eilutes_y(gui_eil) 200 20], ... % [150 gui_eilutes_y(gui_eil) 200 20]
    'Value', 1, 'String','Saugoti grafikus', 'TooltipString','');

% SAUGOTI PARAMETRUS?
gui_eil=gui_eil+1;
h.saugoti_parametrus_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [10 gui_eilutes_y(gui_eil) 240 20], 'Value', 1, ...
    'String','Įrašyti personal. param. ir kt. į MAT',...
    'TooltipString','');
% saugoti parametrus POAPLANKYJE pagal trukmę/laikotarpį?
gui_eil=gui_eil+1;
h.saugoti_parametrus_poaplankyje_checkbox=uicontrol(pnl_eiga,'style','checkbox', 'Units','pixels', 'Position', [30 gui_eilutes_y(gui_eil) 100 20], 'Value', 1, ... % [250 gui_eilutes_y(gui_eil) 100 20]
    'String','poaplankyje',...
    'TooltipString','');
h.saugoti_parametrus_poaplankyje_edit=uicontrol(pnl_eiga,'style','edit', 'Units','pixels', ...
    'String','%d %T', 'TooltipString','%d - data, %T - laikotarpis',...
    'Position', [sum(h.saugoti_parametrus_poaplankyje_checkbox.Position([1 3])) h.saugoti_parametrus_poaplankyje_checkbox.Position(2) 100 20]);


%% Antras skydelis
pnl_modelio_param=uipanel(fig, 'Title','', 'Units','pixels', 'Position',[5 140 490 fig.Position(4)-230 ]);
gui_eil=0.2;

%uicontrol(pnl_apdorojimas, 'style','text', 'HorizontalAlignment','center', 'Units','pixels', 'Position', [5 gui_eilutes_y(gui_eil) 480 20], 'String', 'Modelio parametrai')
%gui_eil=gui_eil+1;

table1_paaiskinimas={'Modelio parametrai:' 
    ' '
    '<SMEGENŲ IR SINUSIO MAZGO>' 
    'HRbasal - vidinis (savitasis) širdies ritmas (k/min)' 
    'Sparas - parasimpatinis tonusas nuo aukšt. smegenų (s.v.)'
    'Drsa - kvėpuojamosios aritmijos (RSA) perdavimo funkcijos narys vardiklyje' 
    'Krsa - kvėpuojamosios aritmijos (RSA) koef.' 
    'Trsa - kvėpuojamosios aritmijos (RSA) delsa'
    'Arvlm_sp - RVML spontaninis simpatinis aktyvumas (s.v.)' 
    'Arvlm_mx - RVML didžiausias aktyvumas išėjime (s.v.)' 
    'Kcvlm - CVLM koef. parasimpatiniam aktyvumui slopina simpatinį (perdavimo f-jos skaitiklis)' 
    'Dcvlm - CVLM koef. parasimpatiniam aktyvumui slopina simpatinį (perdavimo f-jos vardiklis)' 
    'Ks - Simpatinio aktyvumo daugiklis ties sinusiniu mazgu' 
    %{
    'Tmsna - MSNA (muscle sympathetic nerve activity) uždelsimo laikas (s)'
    ' '
    '<KRAUJAGYSLIŲ>' 
    'Kv - Kraujagyslių tonuso daugiklis' 
    'Dne1 - noradrenalino poveikio greičio (?) koef. (MSNA>TPR transf. f-jos vardiklyje)' % Knadr, Kne1
    'Dne2 - noradrenalino poveikio greičio (?) koef. (MSNA>TPR transf. f-jos vardiklyje)' % Kne2
    ' '
    '<CARDIAC OUTPUT generavimui kairiajame skilvelyje ir WINDKESSEL:>' 
    'Presp - neigiamo kraujo spaudimo įkvepiant daugiklis' 
    'Imax - didžiausias kraujo išstūmimo greitis [peak blood flow velocity] (ml/s)' 
    ... % '<WINDKESSEL>' 
    'r - [aortic characteristic impedance] (ml mm s Hg–1)' 
    'R - [resting/initial total peripheral resistance (TRP)] (mm Hg s ml–1)' 
    'C - [total arterial compliance] (ml mm Hg–1)'
    'L - [total inertia of the arterial system]' 
    %}
    ' '
    '<BARORECEPCIJA>' 
    'Pk - kraujo spaudimo išvestinės koef.' 
    'Kb - kraujo spaudimo ir jo išvestinės sumos koef.' 
    'Peq - sigmoidės pusiausvyros taškas' 
    'Kab - koef. susijęs su sigmoidės nuožulnumu' 
    'Bmax - didžiausias galimas baro aktyvumas'
    };

% Kintamasis, Pradinė reikšmė, Apatinė riba, Viršutinė riba, Žingsnis pirmam ciklui
table1_cont1={...
    'HRbasal' 100    80   110    1    1; ... % Savitasis širdies ritmas
    'Sparas'   0.1    0     1    0.1  1; ... % Parasimpatinis tonusas nuo aukšt. smegenų
    'Drsa'     0.7    0.4   2.5  0.15 1; ... % kvėpuojamosios aritmijos (RSA) perdavimo funkcijos narys vardiklyje
    'Krsa'     0.5    0     2    0.15 1; ... % kvėpuojamosios aritmijos (RSA) koef. 
    'Trsa'     0      0     1    0.15 1; ... % kvėpuojamosios aritmijos (RSA) delsa
    ... 'Ssmpt'       0      0     0    0    0; ... % Simpatinis tonusas nuo aukšt. smegenų
    'Arvlm_sp' 0.8    0     5    0.3  1; ... % RVML koef.: spontaninis simpatinis aktyvumas
    'Arvlm_mx' 0.05   0.001 0.5  0.02 1; ... % RVML koef.:  maksimalus simpatinis aktyvumas
    'Kcvlm'    5      0    30    0.5  1; ... % CVLM koef. [TF skaitiklyje]: parasimpatinis slopina simpatinį
    'Dcvlm'    0.5    0.1   1    0.5  1; ... % CVLM poveikio greičio (?) koef. [TF vardiklyje]: parasimpatinis slopina simpatinį
    'Ks'       3      0    10    0.8  1; ... % Simpatinio aktyvumo koeficientas
    };
%{
table1_cont2={ ... 
    'Tmsna'    0      0.5   0.6  0.1  0; ... % MSNA (muscle sympathetic nerve activity) uždelsimo laikas % 0.55
    'Dne1'     2    0.01   100   0.3  0; ... % Noradrenalizo poveikio greičio koef. (denominator)
    'Dne2'     3    0.01   100   0.3  0; ... % Noradrenalizo poveikio greičio koef. (denominator)
    'Kv'       7     -9    30    2    0; ... % Kraujagyslių tonuso koef. 
    'Presp'   -0.5   -1     0    0.05 0; ... % Neigiamas kraujo spaudimas įkvepiant; inspiration induces negative intrapleural pressure, thus lower cardiac output
    ... % Hlaváč ir Holčík, 2004; cit.pg. Hauser ir kt., 2012:
    'Imax' 500  400   650     50   0; ... % Peak blood flow velocity, ml/s
    'r' 0.056   0.036  0.076  0.1  0; ... % aortic characteristic impedance, ml mm s Hg–1;
    'R' 0.79    0.4    2      0.3  0; ... % initial total peripheral resistance (TRP) – will change within model – mm Hg s ml–1
    'C' 1.22    0.9    2      0.2  0; ... % total arterial compliance, ml mm Hg–1
    'L' 0.0051  0.002  0.05   0.2  0; ... % total inertia of the arterial system
    };
%}
table1_cont3={... % Barorecepcija
    'Pk'       0.5  0     5    2   1; ...
    'Kb'       0.5  0.01 10  0.5   1; ...
    ... % ikvepimas is Khoo ir Ursino
    'Peq'     92    80  100   10   1; ...
    'Kab'     11.758 1   50    1   1; ... 
    'Bmax'     1     0    5    0.5 1; ...
    };

%{
    ... % ikvepimas is Randall ir kt 2019
    'Pb'      70    0   150   20   1; ...
    % 
    'Bi1'      6     0.1 100   10  0; ...
    'Bi2'      0     0   100   10  0; ...
    'Bo1'      5     0   100   10  0; ...
    ... % Kuris baro modelis, sveikasis skaičius
    'BM'       3     1    3    1   0; ...   
    'Tb'       0.01  0    0.5  0.1 0; ...
    'Tc'       0.01  0    0.5  0.1 0; ...
%}

%table1_cont=[table1_cont1; table1_cont2; table1_cont3];
table1_cont=[table1_cont1; table1_cont3];
lg=logical(cell2mat(table1_cont(:,end)));
for i=1:length(lg); table1_cont{i,end}=lg(i); end
table1_stulp={'Pradinė' 'Apatinė' 'Viršutinė' 'Žingsnis' 'Kintamas'};
table1_ColumnFormat={'numeric', 'numeric', 'numeric', 'numeric', 'logical'};
table1_naudotini_stulp=[1:3 5];
h.table1=uitable(pnl_modelio_param, ...
    'Data',table1_cont(:,table1_naudotini_stulp+1), ...
    'UserData', table1_cont(:,table1_naudotini_stulp+1), ...
    'RowName',table1_cont(:,1), ...
    'ColumnName',table1_stulp(table1_naudotini_stulp), ...
    'ColumnFormat',  table1_ColumnFormat(table1_naudotini_stulp), ...
    'ColumnEditable',true, ...
    'ColumnWidth',{95}, 'Units','pixels', 'OuterPosition',[5 60-5 480 pnl_modelio_param.Position(4)-60]);
set(h.tb2,'TooltipString', sprintf('%s\n', table1_paaiskinimas{:}));

%h.ikelti_param=uicontrol(pnl_apdorojimas, 'style','PushButton', 'Units','pixels', 'HorizontalAlignment','Center', ...
%    'Position',[100 5 80 30], 'String','Įkelti į WS');
h.apskaiciuotas_HRbasal_checkbox=uicontrol(pnl_modelio_param,'style','checkbox', 'Units','pixels', 'Position', [10 5 400 20], ...
    'Value', 1, 'UserData', 1, ...
    'String','Pirminį HRbasal nustatyti pagal amžių (jei žinomas)',...
    'TooltipString','HRbasal = 118,1 – 0,57 × amžius; SD ~= 8 (Jose ir Collison, 1970)');
h.amzius_txt1=uicontrol(pnl_modelio_param, 'style','text', 'HorizontalAlignment','left', 'String','HRbasal pagal amžių', 'Position', [10 25-4 140 20]);
h.amzius_edit=uicontrol(pnl_modelio_param,'style','edit', 'Units','pixels', ...
    'String','30', 'TooltipString','HRbasal = 118,1 – 0,57 × amžius; SD ~= 8 (Jose ir Collison, 1970)',...
    'Position', [140 25 50 20]);
h.amzius_txt2=uicontrol(pnl_modelio_param, 'style','text', 'HorizontalAlignment','left', 'String','=', 'TooltipString','HRbasal = 118,1 – 0,57 × amžius; SD ~= 8 (Jose ir Collison, 1970)','Position', [200 25-4 200 20]);
h.amzius_mygt=uicontrol(pnl_modelio_param, 'Style','pushbutton', 'Units','pixels', 'HorizontalAlignment','Center', 'String','Nustatyti',   'Position', [375 25 100 20]);


%% Trečias skydelis
pnl_grafikas=uipanel(fig, 'Title','', 'Units','pixels', 'Position',[5 140 490 fig.Position(4)-230 ] );
%gui_eil=1;
h.a=axes('Parent',pnl_grafikas,'Tag','');



%% Callback

% Kontekstiniai meniu
h.table1.UIContextMenu = uicontextmenu(fig);
uimenu(h.table1.UIContextMenu,'Label','Žymėti viską', ...
    'Callback',{@gui_LentelesKintamujuZymejimas,h.table1, '1'});
uimenu(h.table1.UIContextMenu,'Label','Nežymėti nieko', ...
    'Callback',{@gui_LentelesKintamujuZymejimas,h.table1,'0'});
%uimenu(h.table1.UIContextMenu,'Label','Žymėti susijusius su kraujo spaudimu', ...
%    'Callback',{@gui_LentelesKintamujuZymejimas,h.table1,'+abp'});
%uimenu(h.table1.UIContextMenu,'Label','Nežymėti susijusių su kraujo spaudimu', ...
%    'Callback',{@gui_LentelesKintamujuZymejimas,h.table1,'-abp'});
uimenu(h.table1.UIContextMenu,'Label','Nuskaityti numatytąsias reikšmes iš naujo', ...
    'Callback',{@gui_modelio_keitimas,h.modelis,h.table1,h.tb2,h.ABP_checkbox},'Separator','on');
uimenu(h.table1.UIContextMenu,'Label','Nustatyti įkeltąsias reikšmes iš naujo', ...
    'Callback',{@gui_atstatykLentelesDuomenis,h.table1});
uimenu(h.table1.UIContextMenu,'Label','Įkelti iš MATLAB workspace struktūros', ...
    'Callback',{@gui_ikelkDuomenisLentelenIsWSStruct,h.table1});
uimenu(h.table1.UIContextMenu,'Label','Įkelti į MATLAB workspace simuliacijai', ...
    'Callback',{@gui_ikelkLentelesDuomenisBaseWorkspace,h.table1,{'vars'}},'Separator','on');
% Rinkmenų sąraše
h.rinkm.UIContextMenu = uicontextmenu(fig);
uimenu(h.rinkm.UIContextMenu,'Label','Kopijuoti pasirinktų sąrašą', ...
    'Callback',{@gui_kopijuoti_rinkmenu_sarasa,h.rinkm},'Tag','Visada veiksnus');
uimenu(h.rinkm.UIContextMenu,'Label','Kopijuoti pasirinktų sąrašą su keliu', ...
    'Callback',{@gui_kopijuoti_rinkmenu_sarasa_su_keliu,h.rinkm,h.katal1_txt},'Tag','Visada veiksnus');
uimenu(h.rinkm.UIContextMenu,'Label','Peržiūrėti signalą', ...
    'Callback',{@gui_perziureti_signalus,h.rinkm,h.katal1_txt},'Separator','on');
uimenu(h.rinkm.UIContextMenu,'Label','Redaguoti R laikus', ...
    'Callback',{@gui_RRI_perziura,h.rinkm,h.katal1_txt},'Separator','on');
uimenu(h.rinkm.UIContextMenu,'Label','Įkelti į modelio parametrų lentelę', ...
    'Callback',{@gui_ikelkDuomenisLentelenIsRinkmenos,h.rinkm,h.katal1_txt,h.table1},'Separator','on');
h.rinkm_ikelt_ws=uimenu(h.rinkm.UIContextMenu,'Label','Įkelti į MATLAB workspace simuliacijai');
uimenu(h.rinkm_ikelt_ws,'Label','viename SinIn', ...
    'Callback',{@gui_ikelkRinkmenosDuomenisBaseWorkspace,h,{'SimIn'}});
uimenu(h.rinkm_ikelt_ws,'Label','visi kintamieji atskirai', ...
    'Callback',{@gui_ikelkRinkmenosDuomenisBaseWorkspace,h,{'vars'}});
uimenu(h.rinkm.UIContextMenu,'Label','Įkelti į MATLAB workspace paprastai', ...
    'Callback',{@gui_ikelkRinkmenosDuomenisBaseWorkspace,h,{'paprastai'}});
uimenu(h.rinkm.UIContextMenu,'Label','Ištrinti', 'Separator','on', ...
    'Callback',{@gui_istrinti_pasirinktas_rinkmenas,h.rinkm,h.katal1_txt,h.rinkm_fltr1,h.rinkm_fltr2});
uimenu(h.rinkm.UIContextMenu,'Label','Perkelti/pervadinti', ...
    'Callback',{@gui_perkelti_pasirinktas_rinkmenas,h.rinkm,h.katal1_txt,h.rinkm_fltr1,h.rinkm_fltr2});

% Katalogams
h.katal1_txt.UIContextMenu = uicontextmenu(fig);
uimenu(h.katal1_txt.UIContextMenu,'Label','Kopijuoti','Callback','clipboard(''copy'',get(gco,''String''));','Tag','Visada veiksnus')
%uimenu(h.katal1_txt.UIContextMenu,'Label','Padėti','Callback',...
%    'set(gco,''String'',strrep(strrep(clipboard(''paste''),10,''''),13,''''));f=get(gco,''Callback'');feval(f{1},[],f{:})') % be strrep 10 ir 13 sugadintų GUI, jei įterpiamos kelios teksto eilutės
uimenu(h.katal1_txt.UIContextMenu,'Label','Atverti','Callback',{@gui_atverti_aplanka_os,h.katal1_txt},'Tag','Visada veiksnus')
h.katal2_txt.UIContextMenu = uicontextmenu(fig);
uimenu(h.katal2_txt.UIContextMenu,'Label','Kopijuoti','Callback','clipboard(''copy'',get(gco,''String''));','Tag','Visada veiksnus')
%uimenu(h.katal2_txt.UIContextMenu,'Label','Padėti','Callback',...
%    'set(gco,''String'',strrep(strrep(clipboard(''paste''),10,''''),13,''''));f=get(gco,''Callback'');feval(f)') % be strrep 10 ir 13 sugadintų GUI, jei įterpiamos kelios teksto eilutės
uimenu(h.katal2_txt.UIContextMenu,'Label','Atverti','Callback',{@gui_atverti_aplanka_os,h.katal2_txt},'Tag','Visada veiksnus')
h.rinkm_fltr1.UIContextMenu = uicontextmenu(fig);
uimenu(h.rinkm_fltr1.UIContextMenu,'Label','Kopijuoti','Callback','clipboard(''copy'',get(gco,''String''));','Tag','Visada veiksnus')
h.rinkm_fltr2.UIContextMenu = uicontextmenu(fig);
uimenu(h.rinkm_fltr2.UIContextMenu,'Label','Kopijuoti','Callback','clipboard(''copy'',get(gco,''String''));','Tag','Visada veiksnus')

h.modelis.UIContextMenu = uicontextmenu(fig);
uimenu(h.modelis.UIContextMenu,'Label','Atnaujinti modelių sąrašą', 'Callback',{@gui_atnaujinti_modeliu_sarasa,h.modelis});
uimenu(h.modelis.UIContextMenu,'Label','Atverti pasirinktą modelį', 'Callback',{@gui_atverti_modeli,h.modelis});
h.modelis.Callback={@gui_modelio_keitimas,h.modelis,h.table1,h.tb2,h.ABP_checkbox};

h.trukme_checkbox.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.trukme_edit};
h.trukme2_checkbox.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.trukme2_edit};
h.zymekliai_checkbox.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.zymekliai_edit};
h.ikelti_senus_kaip_pradinius_checkbox.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.ikelti_senus_kaip_pradinius_popupmenu};
h.ABP_checkbox.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.R_tikras_checkbox, 0.5};
h.R_tikras_checkbox.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.R_greta_checkbox};
h.saugoti_parametrus_checkbox.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.saugoti_parametrus_poaplankyje_checkbox};
h.saugoti_parametrus_poaplankyje_checkbox.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.saugoti_parametrus_poaplankyje_edit};
%h.ikelti_param.Callback={@gui_ikelkLentelesDuomenisBaseWorkspace,h.table1,{'vars'}};
h.amzius_edit.Callback={@gui_HRbasal_pagal_amziu_edit, h.amzius_edit, h.amzius_txt2};
h.amzius_mygt.Callback={@gui_HRbasal_pagal_amziu_set, h.table1, h.amzius_txt2};

% Meniu lango viršuje
h.kalba=uimenu(fig,'Text','Language / Kalba');
h.apie=uimenu(fig,'Text','Apie');
h.apie_ritminuka=uimenu(h.apie,'Text','Apie Ritminuką','Callback',{@gui_apie_ritminuka});
uimenu(h.kalba,'Text','LT','Callback',{@gui_kalbos_keitimas,h,{'lt';'LT';''}});
uimenu(h.kalba,'Text','EN','Callback',{@gui_kalbos_keitimas,h,{'en';'US';''}});


% Bendrieji
fig.CloseRequestFcn={@gui_bandymas_uzdaryti_langa,h};
set([h.katal1_txt h.rinkm_fltr1 h.rinkm_fltr2 h.rinkm_atnaujint], 'Callback', {@gui_atnaujink_rodomas_rinkmenas,h.rinkm,h.katal1_txt,h.rinkm_fltr1,h.rinkm_fltr2});
h.katal1_dlg.Callback={@gui_katal1_parinkimas_narsykleje, h.katal1_txt, h.rinkm, h.rinkm_fltr1, h.rinkm_fltr2};
h.katal2_dlg.Callback={@gui_katal2_parinkimas_narsykleje, h.katal2_txt};
h.katal2_txt.Callback={@gui_katal2_parinkimas_tekstinis};
h.katal2_v.Callback={@gui_kelio_parinkimas,h.katal2_txt,'saugojimui'};
h.katal1_v.Callback={@gui_kelio_parinkimas,h.katal1_txt,'atverimui'};
h.vykdyti.Callback={@gui_VYKDYMAS, h};
h.checkbox_islaikyti_katalogu_struktura.Callback={@gui_nuo_checkbox_priklausomas_aktyvumas, h.checkbox_islaikyti_katalogu_struktura_1pakat};
h.veiksena.Callback={@gui_veiksenos_keitimas, h};

% Skydelių perjungimas
h.tb1.Callback={@gui_skydelio_perjungimas,pnl_eiga,[h.tb2 h.tb3],[pnl_modelio_param pnl_grafikas]};
h.tb2.Callback={@gui_skydelio_perjungimas,pnl_modelio_param,[h.tb1 h.tb3],[pnl_eiga pnl_grafikas]};
h.tb3.Callback={@gui_skydelio_perjungimas,pnl_grafikas,[h.tb1 h.tb2],[pnl_eiga pnl_modelio_param]};

% Simulink modeliai
gui_atnaujinti_modeliu_sarasa([],[],h.modelis);
gui_modelio_keitimas([],[],h.modelis,h.table1,h.tb2,h.ABP_checkbox);
% Kalba
gui_kalbos_keitimas_dialoguose(h); 
gui_HRbasal_pagal_amziu_edit([],[],h.amzius_edit,h.amzius_txt2);

%% Baigiamieji darbai
%if isunix
    %{
    MANO_KATALOGAI={...
       sprintf('/run/media/%s/Atsargai 2,55TiB/KTU/Pradiniai/', strrep(Tikras_Kelias('~'),'/home/',''))   ...
       };
    AR_YRA_MANO_KATALOGAS=find(cellfun(@(v) exist(v,'dir'), MANO_KATALOGAI) == 7);
    if ~isempty(AR_YRA_MANO_KATALOGAS) 
        h.katal1_txt.String=MANO_KATALOGAI{AR_YRA_MANO_KATALOGAS(1)}; % tik testavimams; užkomentuoti
        tmpdir=fullfile(tempdir,'ritminukas',datestr(now,'yyyy-mm-dd') );
        if ~exist(tmpdir,'dir'); try mkdir(tmpdir); catch; end; end
        h.katal2_txt.String=tmpdir; % tik testavimams; užkomentuoti
        %h.rinkm_fltr1.String='./*.rf;/*.bin;./*/*.rf;./*/*.bin;./*/*/*.rf;./*/*/*.bin';
        %h.retinimas_edit.String='1';
    end
    %}
try
    seni_keliai_a=ikelk_kelius('atverimui');
    h.katal1_txt.String=seni_keliai_a{end};
    seni_keliai_s=ikelk_kelius('saugojimui');
    h.katal2_txt.String=seni_keliai_s{end};
catch
end
%end


fig.MenuBar='none'; 
fig.Interruptible=0;
fig.Units='normalized'; % keičiamo dydžio
set([fig; findall(fig, 'Type','uipanel'); findall(fig, 'Type','uicontrol'); findall(fig, 'Type','uitable') ],'Units','normalized') 
set([pnl_modelio_param pnl_grafikas],'Visible','off');
gui_veiksenos_keitimas([],[],h);
gui_katal2_parinkimas_tekstinis(h.katal2_txt,[]);
gui_skydelio_perjungimas(h.tb1,[],pnl_eiga,[h.tb2 h.tb3],[pnl_modelio_param pnl_grafikas]);
try
    if isempty(h.rinkm_fltr1.String)
        h.rinkm_fltr1.String='*.*;./*/*.*';
    end
    gui_atnaujink_rodomas_rinkmenas([], [], h.rinkm, h.katal1_txt, h.rinkm_fltr1, h.rinkm_fltr2);
catch err
    Pranesk_apie_klaida(err,'Poaplankiai','',0);
    h.rinkm_fltr1.String='*.*'; 
    gui_atnaujink_rodomas_rinkmenas([], [], h.rinkm, h.katal1_txt, h.rinkm_fltr1, h.rinkm_fltr2);
end

function gui_kalbos_keitimas(~,~,h,new_locale)
% įsiminti lentelės turinį prieš keitimus
lenteles_turinys1=h.table1.Data;
lenteles_turinys2=h.table1.UserData;
% kalbos nuostatų keitimas ir įsiminimas ateičiai
gui_kalbos_keitimas_nuostatose([],[],new_locale)
% išvalymas
evalin('base','clear r_lokaliz');
% užrašų keitimas
gui_kalbos_keitimas_dialoguose(h);
gui_modelio_keitimas([],[],h.modelis,h.table1,h.tb2,h.ABP_checkbox); % dėl paaiškinimo
% atstatyti lentelės turinį, kurį galėjo pakeisti modelio atnaujinimas
h.table1.Data=lenteles_turinys1;
h.table1.UserData=lenteles_turinys2;

function gui_kalbos_keitimas_nuostatose(~,~,new_locale)
konf_file=fullfile(tempdir,'.ritminukas_gui.knf');
try load(konf_file,'Ritminukas','-mat');
%     lnt=[{'getLanguage' 'getCountry' 'getVariant'}; Ritminukas.nuostatos.lokale' ];
%     LC_current_locale=struct(lnt{:});
catch
%     LC_current_locale=struct('getLanguage','--','getCountry','','getVariant','');
end
Ritminukas.nuostatos.lokale=new_locale;
if exist(konf_file,'file')
    save(konf_file,'Ritminukas','-append','-mat');
else
    save(konf_file,'Ritminukas','-mat');
end

function gui_kalbos_keitimas_dialoguose(h)
h.apie.Text=r_lokaliz('Apie');
%h.apie.Text=r_lokaliz('Pagalba');
h.apie_ritminuka.Text=r_lokaliz('Apie Ritminukas');
h.pnl_ikelimas.Title=r_lokaliz('Apdorotinu duomenu pagrindinis katalogas');
h.pnl_saugojimas.Title=r_lokaliz('Rezultatu katalogas');
h.checkbox_islaikyti_katalogu_struktura.String=r_lokaliz('Poaplankiai atitinka ivedamų duomenu poaplankius');
h.checkbox_islaikyti_katalogu_struktura_1pakat.String=r_lokaliz('1 poaplankio gylio');
h.pnl_rinkmenos.Title=r_lokaliz('Apdorotinos rinkmenos');
h.pnl_atranka.Title=r_lokaliz('Atranka');
h.rinkm_txt_rod.String=r_lokaliz('Rodyti:');
h.rinkm_txt_zym.String=r_lokaliz('Pazymeti:');
h.rinkm_atnaujint.String=r_lokaliz('Atnaujinti');
h.vykdyti.String=r_lokaliz('VYKDYTI');
h.checkbox_baigti_anksciau.String=r_lokaliz('Baigti anksciau');
h.checkbox_baigti_su_garsu.String=r_lokaliz('Baigti su garsu');
h.tb1.String=r_lokaliz('Eigos parametrai');
h.tb2.String=r_lokaliz('Modelio parametrai');
%h.tb3.String=r_lokaliz('...');
h.modelis_txt.String=r_lokaliz('Modelio versija:');
h.veiksena_txt.String=r_lokaliz('Veiksena:');
h.veiksena.String={...
    '(auto)' ...
    r_lokaliz('ModelioVeiksena:tik_nuskaityti') ...
    r_lokaliz('ModelioVeiksena:1') ...
    r_lokaliz('ModelioVeiksena:optimizavimas') ...
    r_lokaliz('ModelioVeiksena:optimizavimas_lygiagretus') ...
    r_lokaliz('ModelioVeiksena:ikelti_i_workspace') ...
    r_lokaliz('ModelioVeiksena:SIMUL')};
h.trukme_checkbox.String=r_lokaliz('Ribotas laikas kalibravimui:');
h.trukme2_checkbox.String=r_lokaliz('Kitas laikas modeliavimui bei rodymui:');
h.zymekliai_checkbox.String=r_lokaliz('Laiko zymekliai grafikams:');
h.ikelti_senus_kaip_pradinius_checkbox.String=r_lokaliz('Bandyti senus parametrus kaip pradinius:');
h.ikelti_senus_kaip_pradinius_popupmenu.String={ ...
    r_lokaliz('IkeltiSenusParam:...>opt') r_lokaliz('IkeltiSenusParam:opt>...') r_lokaliz('IkeltiSenusParam:...>...')};
h.ABP_checkbox.String=r_lokaliz('Tikro kraujo spaudimo signalo perdavimas');
h.R_tikras_checkbox.String=r_lokaliz('R tikrojo perdavimas del kraujo spaudimo modeliavimo');
h.R_greta_checkbox.String=r_lokaliz('R sugretinimas – tikro R laikas kaip atskaita modeliuojamiems R');
h.paklaidos_sudedamosios_txt.String=r_lokaliz('Paklaidos pagal:');
h.paklaidos_sudedamosios.String={ ...
    r_lokaliz('PaklaidosPg:auto') ...
    r_lokaliz('PaklaidosPg:SR') ...
    r_lokaliz('PaklaidosPg:RRIms') ...
    r_lokaliz('PaklaidosPg:RRI/10') ...
    r_lokaliz('PaklaidosPg:SRirKS') ...
    r_lokaliz('PaklaidosPg:RRIirKS') ...
    r_lokaliz('PaklaidosPg:RRI/10irKS') ...
    r_lokaliz('PaklaidosPg:KS') };
h.paklaidos_bauda_checkbox.String=r_lokaliz('su baudomis');
h.issamesne_iteraciju_info_checkbox.String=r_lokaliz('Rodyti iteraciju info optimizuojant');
h.rodyti_grafikus_checkbox.String=r_lokaliz('Rodyti grafikus');
h.saugoti_grafikus_checkbox.String=r_lokaliz('Saugoti grafikus');
h.saugoti_parametrus_checkbox.String=r_lokaliz('Saugoti personal. param. ir kt. i MAT');
h.saugoti_parametrus_poaplankyje_checkbox.String=r_lokaliz('poaplankyje');
h.table1.ColumnName={...
    r_lokaliz('ParamReiksme:Pradine') ...
    r_lokaliz('ParamReiksme:Apatine') ... 
    r_lokaliz('ParamReiksme:Virsutine') ... 
    r_lokaliz('Param:Kintamas')};
h.amzius_txt1.String=r_lokaliz('HRbasal pagal amziu');
h.amzius_mygt.String=r_lokaliz('Nustatyti');
h.apskaiciuotas_HRbasal_checkbox.String=r_lokaliz('Pirminis HRbasal pagal amziu');

function gui_HRbasal_pagal_amziu_edit(~,~,h_amzius_edit,h_amzius_txt2)
amzius=str2double(h_amzius_edit.String);
HRbasal = 118.1-0.57*amzius; % HRbasal = 118,1 – 0,57 × amžius; SD ~= 8 (Jose ir Collison, 1970)
h_amzius_txt2.String=['= ' num2str(HRbasal) ' ' r_lokaliz('k/min') '; SD ~= 8 '  r_lokaliz('k/min') ];
h_amzius_txt2.UserData=[0 -8 8] + HRbasal;

function gui_HRbasal_pagal_amziu_set(~,~,h_table1,h_amzius_txt2)
data=h_amzius_txt2.UserData;
if length(data) < 3
    return
end
for i=find(ismember(h_table1.RowName,'HRbasal'))
    h_table1.Data(i,1:length(data))=num2cell(data);
end

function handles_tikri=atrink_tikrus_handles(handles)
handles_c = struct2cell(handles);
handles_tikri_id=arrayfun(@(i)isobject(handles_c{i}), 1:numel(handles_c), 'UniformOutput', 1);
handles_tikri=handles_c(handles_tikri_id); 
handles_tikri=[handles_tikri{:}];


function seni_keliai=ikelk_kelius(atverimui_ar_saugojimui)
% atverimui_ar_saugojimui yra 'atverimui' arba 'saugojimui'
MAT=fullfile(tempdir,'.ritminukas_gui.knf');
seni_keliai={};
if exist(MAT,'file') ~= 2
    return
end
matObj = matfile(MAT);
raktas=['keliai_' atverimui_ar_saugojimui];
if ~ismember({raktas},who(matObj))
    return
end
load(MAT,raktas,'-MAT');
seni_keliai=eval(raktas);

function irasyk_kelius(papildomas_kelias,atverimui_ar_saugojimui)
if isempty(papildomas_kelias)
    return
end
MAT=fullfile(tempdir,'.ritminukas_gui.knf');
[seni_keliai]=ikelk_kelius(atverimui_ar_saugojimui);
if ~isempty(seni_keliai) && strcmp(papildomas_kelias,seni_keliai{end})
    return
end
if size(seni_keliai,2) > 1
    seni_keliai=seni_keliai';
end
keliai=[unique(setdiff(seni_keliai,{papildomas_kelias})) ; {papildomas_kelias}]; %#ok
raktas=['keliai_' atverimui_ar_saugojimui];
eval([raktas '=keliai;']);
if exist(MAT,'file') == 2
    save(MAT,raktas,'-append');
else
    save(MAT,raktas);
end

function gui_apie_ritminuka(~,~)
msg=sprintf([...
    'Ritminukas ' versija '\n\n' ...
    r_lokaliz('RitminukasInfo:sistema') '\n\n' ... 
    r_lokaliz('RitminukasInfo:modelis') '\n\n' ... 
    r_lokaliz('RitminukasInfo:09.3.3-LMT-K-712') '\n\n' ...
    '(c) 2020-2023 Mindaugas Baranauskas <' [109 46 98 97 114 97 110 97 117 115 107 97 115 64 107 116 117 46 108 116] '>\n' ...
    '(c) 2020-2023 Kauno technologijos universitetas']);
msgbox(msg,r_lokaliz('Apie Ritminukas'),'help');

function gui_atnaujink_rodomas_rinkmenas(~, ~, h_rinkm, h_katal1_txt, h_rinkm_fltr1, h_rinkm_fltr2)
if isempty(h_rinkm_fltr1.String)
    h_rinkm_fltr1.String='*.edf;*.mat';
end
if isempty(h_rinkm_fltr2.String)
    h_rinkm_fltr2.String='*';
end
h_katal1_txt.String=Tikras_Kelias(h_katal1_txt.String);
h_katal1_txt.TooltipString=h_katal1_txt.String;
if ~isequal(h_katal1_txt.BackgroundColor,[1 1 1]) || ~isequal(h_rinkm_fltr1.BackgroundColor,[1 1 1]) || ~isequal(h_rinkm_fltr2.BackgroundColor,[1 1 1])
    set([h_rinkm_fltr1 h_rinkm_fltr2 h_katal1_txt], 'BackgroundColor', [1 1 1]); % baltas įvedimo langelio fonas
    if isequal(get(h_katal1_txt,'UserData'),{h_rinkm_fltr1.String h_rinkm_fltr2.String h_katal1_txt.String})
        % jei įvedimo laukeliuose duomenys nesikeičia, tada neperstatinėti ranka išrinktų rinkmenų žymėjimo
        return
    end
end
h_rinkm.UserData={};

Kelias_dabar=pwd;
cd(h_katal1_txt.String);
fltr1=h_rinkm_fltr1.String;
%fltr1=strrep(fltr1,'/','\');
%if ispc
%    fltr1=strrep(fltr1,'\','\\');
%end
FAILAI0=filter_filenames(fltr1);
FAILAI1=filter_filenames(lower(fltr1));
FAILAI2=filter_filenames(upper(fltr1));
FAILAI=unique([FAILAI0 FAILAI1 FAILAI2]);
if isempty(FAILAI)
    h_rinkm.String={};
    h_rinkm.Max=0;
    h_rinkm.Value=[];
    h_rinkm.SelectionHighlight='off';
    if ~isempty(strfind(lower(fltr1),'.edf')) && isempty(strfind(lower(fltr1),'.mat')) %#ok "contains" galima naudoti, bet tik nuo MATLAB R2016b
        fltr1_alt=strrep(lower(fltr1),'.edf','.mat');
        FAILAI_alt=filter_filenames(fltr1_alt);
        if ~isempty(FAILAI_alt)
            b=questdlg('Nerasta EDF rinkmenų, bet yra MAT. Rodyti MAT?','Rodyti *.MAT vietoj *.EDF?');
            if ~isempty(b) && strcmp(b,'Yes')
                FAILAI=FAILAI_alt;
                h_rinkm_fltr1.String=fltr1_alt;
            end
        end
    end
    if ~isempty(strfind(lower(fltr1),'.mat')) && isempty(strfind(lower(fltr1),'.edf')) %#ok "contains" galima naudoti, bet tik nuo MATLAB R2016b
        fltr1_alt=strrep(lower(fltr1),'.mat','.edf');
        FAILAI_alt=filter_filenames(fltr1_alt);
        if ~isempty(FAILAI_alt)
            b=questdlg('Nerasta MAT rinkmenų, bet yra EDF. Rodyti EDF?','Rodyti *.EDF vietoj *.MAT?');
            if ~isempty(b) && strcmp(b,'Yes')
                FAILAI=FAILAI_alt;
                h_rinkm_fltr1.String=fltr1_alt;
            end
        end
    end
end
cd(Kelias_dabar);
FAILU_tekstas = FAILAI;
h_rinkm.String=FAILU_tekstas;
h_rinkm.UserData=FAILAI;

if isempty(FAILAI)
    %FAILAI(1).name='';
    h_rinkm.Max=0;
    h_rinkm.Value=[];
    h_rinkm.ListboxTop=0;
    h_rinkm.SelectionHighlight='off';
else
    if strcmp(h_rinkm_fltr2.Style,'edit') 
        %FAILAI_filtruoti=dir(get(handles.edit_failu_filtras2,'String'));
        %FAILAI_filtruoti_={FAILAI_filtruoti.name};
        %FAILAI_filtruoti_=atrinkti_teksta(FAILAI,h_rinkm_fltr2.String);
        tekstai_be_html=regexprep(FAILU_tekstas,'<[^>]*>','');
        FAILAI_filtruoti_=atrinkti_teksta(tekstai_be_html, h_rinkm_fltr2.String );
        Pasirinkti_failu_indeksai=find(ismember(tekstai_be_html,intersect(FAILAI_filtruoti_,tekstai_be_html)));
    else
        FAILAI_filtruoti_=FAILU_tekstas;
        %try
        %    FAILAI_filtruoti_= <SENAS PARINKTŲ SĄRAŠAS>;
        %catch err
        %    Pranesk_apie_klaida(err, 'Apdorotų duomenų pasirinkimas', '')
        %end
        Pasirinkti_failu_indeksai=find(ismember(FAILU_tekstas,intersect(FAILAI_filtruoti_,FAILU_tekstas)));
    end
    h_rinkm.Max=length(FAILU_tekstas);
    if and(isempty(Pasirinkti_failu_indeksai),length(FAILU_tekstas)==1)
        h_rinkm.Value=1;
        h_rinkm.ListboxTop=1;
        %h_rinkm.SelectionHighlight='off';
    else
        h_rinkm.Value=Pasirinkti_failu_indeksai;
        if ~isempty(Pasirinkti_failu_indeksai) && Pasirinkti_failu_indeksai(1) > 1
            h_rinkm.ListboxTop=Pasirinkti_failu_indeksai(1)-1;
        else
            h_rinkm.ListboxTop=1;
        end
    end
    h_rinkm.SelectionHighlight='on';
end
set(h_katal1_txt,'UserData',{h_rinkm_fltr1.String h_rinkm_fltr2.String h_katal1_txt.String});

function gui_atverti_aplanka_os(~, ~, handle)
% Katalogą atverti operacinės sistemos failų naršyklėje
% http://stackoverflow.com/questions/16808965/how-to-open-a-directory-in-the-default-file-manager-from-matlab

Dir=Tikras_Kelias(get(handle,'String'));
h=statusbar2015(lokaliz('Palaukite!'));
statusbar2015(0.5,h);

if ispc % Windows PC
    evalc(['!explorer "' Dir '"']);
elseif isunix % Unix or derivative
    if ismac % Mac
        evalc(['!open "' Dir '"']);
    else % Linux
        fMs = {...
            'xdg-open'   % most generic one
            %'gvfs-open'  % successor of gnome-open
            %'gnome-open' % older gnome-based systems
            %'kde-open'   % older KDE systems
           };
        for ii=1:length(fMs)
            C = evalc(['! LD_LIBRARY_PATH=/usr/lib64:/usr/lib ' fMs{ii} ' "'  Dir '"' ]);
            if isempty(C); break; end
        end
    end
else
    warning('Unrecognized operating system.');
end
if ishandle(h); delete(h); end

function gui_atnaujinti_modeliu_sarasa(~,~,h_modelis)
mfilename_katal=fileparts(which(mfilename));
matomi_modeliai=filter_filenames(fullfile(mfilename_katal,['ritminukas' '*.slx']));
matomi_modeliai=regexprep(matomi_modeliai,strrep(['^' mfilename_katal filesep ],'\','\\'),'');
matomi_modeliai=regexprep(matomi_modeliai,'.slx','');
matomi_modeliai=matomi_modeliai(cellfun(@isempty, regexp(matomi_modeliai,'^\w+$','match'))==0);
if isempty(matomi_modeliai)
    warning('Nerasta MATLAB Simulink modelių, pavadinimu „ritminukas*.slx“!')
    matomi_modeliai={'NERASTA!!!'};
end
if ~isempty(h_modelis.UserData) && ismember(h_modelis.UserData{h_modelis.Value},matomi_modeliai)
    pageidaujamas_modelis=h_modelis.UserData{h_modelis.Value};
else
    [~,pageidaujamas_modelis]=versija;
end
pageidaujamo_modelio_id=find(ismember(matomi_modeliai,pageidaujamas_modelis));
if isempty(pageidaujamo_modelio_id)
    pageidaujamo_modelio_id=1;
end
set(h_modelis,...
    'String',   regexprep(matomi_modeliai,'^ritminukas',''), ...
    'UserData', matomi_modeliai, ...
    'Value',pageidaujamo_modelio_id);

function gui_atverti_modeli(~,~,h_modelis)
modelis=h_modelis.UserData{h_modelis.Value};
% Tikrinti, gal jau atverta:
%openedModels = find_system('SearchDepth', 0);
%if bdIsLoaded(modelis)
%    fprintf('Modelis „%s“ jau įkeltas.\n', modelis);
%else
    %load_system(modelis) % tik įkelti, bet nerodyti lango
    open_system(modelis)
%end


function gui_ikelkLentelesDuomenisBaseWorkspace(~, ~, h_table1,veiksenos)
if nargin < 4
    veiksenos={'vars'};
end
param_vardai=h_table1.RowName;
param_reiksm=h_table1.Data(:,1);
if ismember('vars',veiksenos)
    % Į workspace  - kiekvieną atskirą kintamąjį
    for i=1:length(param_vardai)
        assignin('base' , param_vardai{i}, param_reiksm{i});
    end
    % #FIXME: dinamiškai atsižvelgti į naudotojo pasirinktą versiją
    % Paslėpti fiksuoti kintamieji:
    %if evalin('base','~exist(''Ss'',''var'')') % iki v23
    %    assignin('base' , 'Ss', 0);
    %end
    if evalin('base','~exist(''Ssmpt'',''var'')') % nuo v24
        assignin('base' , 'Ssmpt', 0);
    end
    %if evalin('base','~exist(''Ts'',''var'')') % iki v21
    %    assignin('base' , 'Ts', 0.3);
    %end
    if evalin('base','~exist(''Tbf'',''var'')') % nuo v22
        assignin('base' , 'Tbf', 0.3);
    end
    
    % Netikri fiziologiniai signalai – tiesės:
    if evalin('base','~exist(''Rt'',''var'')') || evalin('base','~isequal(''Rt'',[0 0])')
        assignin('base' , 'Rt', [0 0]);
        assignin('base' , 'SIMUL', 1);
    else
        assignin('base' , 'SIMUL', 0);
    end
    if evalin('base','~exist(''kvepavimas'',''var'')')
        assignin('base' , 'kvepavimas', [0 0.5]);
    end
    if evalin('base','~exist(''abp'',''var'')')
        assignin('base' , 'abp', [0 0]);
    end
    
    % FIXME: priskirti pagal GUI
    assignin('base' , 'R_greta', 0);
    assignin('base' , 'R_tikras', 1);
    
end
if ismember('SimIn',veiksenos)
    if evalin('base','exist(''SimIn'',''var'')')
        disp('Norėdami paleisti modelį, įvykdykite:')
        disp('SimOut=sim(SimIn);')
    end
end


function gui_ikelkRinkmenosDuomenisBaseWorkspace(ho, ~, handles,veiksenos)
if nargin < 4
    veiksenos={'SimIn' 'vars'};
end
rinkm0=handles.rinkm.Value;
if isempty(rinkm0)
    return
end
if ismember({'paprastai'},veiksenos)
    [~,rinkmenos_su_keliu]=gui_pasirinktieji_duomenys(handles.rinkm,handles.katal1_txt);
    try evalin('base',['load(''' rinkmenos_su_keliu{1} ''')']);
        fprintf('Sėkmingai įkelta iš:\n %s\n',rinkmenos_su_keliu{1});
    catch err
        warning(err.message);
    end
    if length(veiksenos) < 2
        return
    end
end
%handles.rinkm.Value=rinkm0(1);
setappdata(handles.veiksena,'veiksena','ikelti_i_workspace');
%fg=findobj('type','figure','Tag',mfilename);
fg=ancestor(handles.rinkm,'figure','toplevel');
set(fg,'pointer','watch'); drawnow;
gui_VYKDYMAS(ho, [], handles);
setappdata(handles.veiksena,'veiksena',[]);
Ar_turim_SimIn=evalin('base','exist(''SimIn'',''var'')');
if ~Ar_turim_SimIn
    warning('Nepavyko įkelti kintamųjų modeliui...')
    handles.rinkm.Value=rinkm0;
    set(fg,'pointer','arrow'); drawnow;
    return
end
if ismember('vars',veiksenos)
    try SimIn=evalin('base','SimIn;');
        if exist('SimIn','var')
            % Į workspace  - kiekvieną atskirą kintamąjį
            for i=1:length(SimIn.Variables)
                assignin('base' , SimIn.Variables(i).Name, SimIn.Variables(i).Value);
            end
            % Į lentelę
            %SimInVN={SimIn.Variables.Name};
            %[i,j]=ismember(SimInVN,handles.table1.RowName);
            %handles.table1.Data(j(i),1)={SimIn.Variables(i).Value};
        end
    catch
    end
end
if ~ismember('SimIn',veiksenos)
    evalin('base','clear(''SimIn'');');
elseif evalin('base','exist(''SimIn'',''var'')')
        disp('Norėdami paleisti modelį, įvykdykite:')
        disp('SimOut=sim(SimIn);')
end
handles.rinkm.Value=rinkm0;
set(fg,'pointer','arrow'); drawnow;

function gui_atstatykLentelesDuomenis(~, ~, h_table1)
%fprintf('\nSena modelio parametrų lentelė:\n')
%disp(cell2table(h_table1.Data,'RowNames',h_table1.RowName,'VariableNames',{'Pradinė' 'Apatinė' 'Viršutinė' 'Kintamas'}))
h_table1.Data=h_table1.UserData;
%fprintf('\nNauja modelio parametrų lentelė:\n')
%disp(cell2table(h_table1.Data,'RowNames',h_table1.RowName,'VariableNames',{'Pradinė' 'Apatinė' 'Viršutinė' 'Kintamas'}))
%struct2txt(cell2struct(h_table1.Data,h_table1.RowName))


function gui_ikelkDuomenisLentelenIsWSStruct(~, ~, h_table1)
vars=evalin('base','who');
strcts={};
for i=1:length(vars)
    if evalin('base',['isstruct(' vars{i} ')'])
        flds=evalin('base',['fieldnames(' vars{i} ')']);
        if any(ismember(flds, h_table1.RowName))
            strcts=[strcts; vars{i}]; %#ok
        end
    end
end
if isempty(strcts)
    disp('Nerasta struktūrų, galimai tinkamų įkėlimui į lentelę. Sukurkite struktūrą su laukais, kurie atitiktų parametrų pavadinimus.');
    return
elseif length(strcts) == 1 && ismember('ans',strcts) 
    %strct=strcts{1};
    strct='ans'; % išsaugotuose FIG mygtukas įrašo būtent į "ans"
else % Klausti
    i=find(ismember(strcts,'ans'));
    ats=listdlg('PromptString','Pasirinkite struktūrą įkėlimui:',...
        'ListString',strcts,...
        'SelectionMode','single',...
        ... 'ListSize',[450 500],...
        'InitialValue',i);
    if isempty(ats)
        return
    end
    strct=strcts{ats};
end
fprintf('Įkeliama iš struktūros „%s“:', strct)
strct_params=evalin('base',strct);
for i=find(ismember(h_table1.RowName,fieldnames(strct_params)))'
    f=h_table1.RowName{i};
    v=strct_params.(f);
    if isnumeric(v)
        h_table1.Data{i,1}=v;
        fprintf(' %s', f);
    end
end
fprintf('\n');


function gui_ikelkDuomenisLentelenIsRinkmenos(~, ~, h_rinkm, h_katal1_txt, h_table1)
[~,rinkmenos_su_keliu]=gui_pasirinktieji_duomenys(h_rinkm,h_katal1_txt);
ikelta=0;
if isempty(rinkmenos_su_keliu)
    return
end
try
    katalogas_su_rinkmena=rinkmenos_su_keliu{1};
    MAT_kintamieji = who('-file', katalogas_su_rinkmena);
    if ismember({'parinktys'},MAT_kintamieji)
        load(katalogas_su_rinkmena,'parinktys'); % senos parinktys
        senos_parinktys=parinktys; clear parinktys
    else
        senos_parinktys=struct();
    end
    if isfield(senos_parinktys,'v')
        sena_ritminuko_versija=senos_parinktys.v;
    else
        sena_ritminuko_versija='';
    end
    if isfield(senos_parinktys,'modelis')
        sena_modelio_versija=str2double(regexprep(senos_parinktys.modelis,'^ritminukas(\d*).*','$1'));
    else
        sena_modelio_versija=0;
    end
    atvejis20230127=isempty(sena_ritminuko_versija) && ismember(sena_modelio_versija,[24 25]) && ismember(senos_parinktys.modelis,{'ritminukas24supaprastintasSAstraipsniui' 'ritminukas25str'}) && isfield(senos_parinktys,'laikas') && isequal(senos_parinktys.laikas(1:min(10,end)),'2023-01-27');
    if all(ismember({'optimalus_param' 'keiciamu_param_vardai'},MAT_kintamieji))
        load(katalogas_su_rinkmena,'optimalus_param','keiciamu_param_vardai')
        if atvejis20230127 % 2023-01-27 blusa
             i=find(ismember(keiciamu_param_vardai,'Drsa'));
             if ~isempty(i)
                 optimalus_param(i)=1/optimalus_param(i);
             end
             i=find(ismember(keiciamu_param_vardai,'Dcvlm'));
             if ~isempty(i)
                 optimalus_param(i)=1/optimalus_param(i);
             end
        end
        keiciamu_param_vardai=keiciamu_param_vardu_sukeitimas(keiciamu_param_vardai);
        [i,j]=ismember(keiciamu_param_vardai,h_table1.RowName);
        h_table1.Data(j(i),1)=num2cell(optimalus_param(i));
        ikelta=1;
    elseif all(ismember({'keiciamu_param_prad_reiksmes' 'keiciamu_param_vardai'},MAT_kintamieji))
        load(katalogas_su_rinkmena,'keiciamu_param_prad_reiksmes','keiciamu_param_vardai')
        keiciamu_param_vardai=keiciamu_param_vardu_sukeitimas(keiciamu_param_vardai);
        [i,j]=ismember(keiciamu_param_vardai,h_table1.RowName);
        h_table1.Data(j(i),1)=num2cell(keiciamu_param_prad_reiksmes(i));
        ikelta=1;
    end
    if all(ismember({'fiksuoti_param'},MAT_kintamieji))
        load(katalogas_su_rinkmena,'fiksuoti_param')
        % #FIXME: dinamiškai atsižvelgti į naudotojo pasirinktą versiją
        if ismember({'Krvlm'},fields(fiksuoti_param)) % iki v20?
            fiksuoti_param.Arvlm_sp=fiksuoti_param.Krvlm;
        end
        if ismember({'Kne1'},fields(fiksuoti_param)) % iki v23
            fiksuoti_param.Dne1=fiksuoti_param.Kne1;
        end
        if ismember({'Kne2'},fields(fiksuoti_param)) % iki v23
            fiksuoti_param.Dne2=fiksuoti_param.Kne2;
        end
        if ismember({'Sp'},fields(fiksuoti_param)) % iki v23
            fiksuoti_param.Sparas=fiksuoti_param.Sp;
        end
        if atvejis20230127 % 2023-01-27 blusa
            if ismember('Drsa',fields(fiksuoti_param)) 
                fiksuoti_param.Drsa=1/fiksuoti_param.Drsa;
            end
            if ismember('Dcvlm',fields(fiksuoti_param)) 
                fiksuoti_param.Dcvlm=1/fiksuoti_param.Dcvlm;
            end
        end
        fiksuoti_param_flds=fields(fiksuoti_param);
        [i,j]=ismember(fiksuoti_param_flds,h_table1.RowName);
        for fi=find(i')
            h_table1.Data{j(fi),1}=fiksuoti_param.(fiksuoti_param_flds{fi});
        end
        ikelta=1;
    end
    if ikelta
        h_table1.UserData=h_table1.Data;
        fprintf('Parametrai sėkmingai įkelti į lentelę iš:\n %s\n',katalogas_su_rinkmena)
    else
        fprintf('Nepavyko rasti parametrų įkėlimui į lentelę iš:\n %s\n',katalogas_su_rinkmena)
    end
catch err
    Pranesk_apie_klaida(err,[],[],0); 
end

function keiciamu_param_vardai=keiciamu_param_vardu_sukeitimas(keiciamu_param_vardai)
% #FIXME: dinamiškai atsižvelgti į naudotojo pasirinktą versiją

%      iki v20?   iki v23
Seni={'Krvlm'    'Kne1' 'Kne2' 'Sp'};
Nauj={'Arvlm_sp' 'Dne1' 'Dne2' 'Sparas'};
for i=1:length(Seni)
    senas_i=find(ismember(keiciamu_param_vardai,Seni(i)));
    if ~isempty(senas_i)
        keiciamu_param_vardai{senas_i}=Nauj{i};
    end
end


function gui_istrinti_pasirinktas_rinkmenas(~,~,h_rinkm,h_katal1_txt, h_rinkm_fltr1, h_rinkm_fltr2)
[~,rinkmenos_su_keliu]=gui_pasirinktieji_duomenys(h_rinkm,h_katal1_txt);
txt=sprintf('%s\n',rinkmenos_su_keliu{:});
a=questdlg(sprintf('Ar tikrai norite ištrinti šias rinkmenas?\n%s',txt),'Ištrinti?','Taip','Ne','Ne');
bent_vienas_pavyko=0;
if isequal(a,'Taip')
    for i=1:length(rinkmenos_su_keliu)
        try delete(rinkmenos_su_keliu{i}); bent_vienas_pavyko=1; catch err; Pranesk_apie_klaida(err,'','',0); end
    end
end
if bent_vienas_pavyko
    gui_atnaujink_rodomas_rinkmenas([], [], h_rinkm, h_katal1_txt, h_rinkm_fltr1, h_rinkm_fltr2);
end

function gui_perkelti_pasirinktas_rinkmenas(~,~,h_rinkm,h_katal1_txt, h_rinkm_fltr1, h_rinkm_fltr2)
[~,rinkmenos_su_keliu]=gui_pasirinktieji_duomenys(h_rinkm,h_katal1_txt);
nauji=inputdlg(rinkmenos_su_keliu,'Pervadinimas / perkėlimas',1,rinkmenos_su_keliu,struct('Resize','on'));
if isempty(nauji)
    return;
end
bent_vienas_pavyko=0;
for i=1:length(rinkmenos_su_keliu)
    s=rinkmenos_su_keliu{i};
    n=nauji{i};
    if ~strcmp(s,n)
        try movefile(s,n); bent_vienas_pavyko=1;
        catch err; Pranesk_apie_klaida(err,'','',0);
        end
    end
end
if bent_vienas_pavyko
    gui_atnaujink_rodomas_rinkmenas([], [], h_rinkm, h_katal1_txt, h_rinkm_fltr1, h_rinkm_fltr2);
end


function gui_katal1_parinkimas_narsykleje(~,~,h_katal1_txt, h_rinkm, h_rinkm_fltr1, h_rinkm_fltr2)
kelias1=Tikras_Kelias(h_katal1_txt.String);
kelias2=uigetdir(kelias1,'Pasirinkite katalogą su apdorotinomis rinkmenomis');
if isequal(kelias1,kelias2)
    return % niekas nesikeis
end
if ~ischar(kelias2)
     % Naudotojui atšaukus veiksmą, grąžinamas ne kelias (kaip tekstas), o skaičius (0)
     if isequal(kelias1,h_katal1_txt.String)
         return % niekas nesikeis
     else
         kelias2=kelias1; % tikriausiai pirmasis kelias nebegaliojantis, teks atnaujinti
     end
end
h_katal1_txt.String=kelias2;
gui_atnaujink_rodomas_rinkmenas([], [], h_rinkm, h_katal1_txt, h_rinkm_fltr1, h_rinkm_fltr2);


function gui_katal2_parinkimas_narsykleje(~,~,h_katal2_txt)
kelias1=Tikras_Kelias(h_katal2_txt.String);
kelias2=uigetdir(kelias1,'Pasirinkite katalogą rezultatų išvedimui');
if ~ischar(kelias2)
    % Naudotojui atšaukus veiksmą, grąžinamas ne kelias (kaip tekstas), o skaičius (0)
    return % niekas nesikeis
end
h_katal2_txt.String=kelias2;
gui_katal2_parinkimas_tekstinis(h_katal2_txt,[])

function gui_katal2_parinkimas_tekstinis(h_katal2_txt,~)
kelias=h_katal2_txt.String;
kelias=strrep(kelias,'%d',datestr(now,'yyyy-mm-dd'));
if ~isempty(kelias) && ~exist(kelias,'dir')
    button = questdlg([' ' kelias ' ' ] , ...
        'Katalogas nerastas', ...
        'Atsisakyti', 'Sukurti', 'Sukurti');
    if and(~isempty(kelias),strcmp(button,'Sukurti'))
        try
            mkdir(kelias);
        catch err
            warning(err.message);
            kelias=h_katal2_txt.TooltipString;
        end
    else
        kelias=h_katal2_txt.TooltipString;
    end
end
kelias=Tikras_Kelias(kelias);
h_katal2_txt.String=kelias;
h_katal2_txt.TooltipString=kelias;
h_katal2_txt.BackgroundColor='w';

function gui_kelio_parinkimas(~,~,h_txt,atverimui_ar_saugojimui)
dabartinis_kelias=Tikras_Kelias(h_txt.String);
seni_keliai=ikelk_kelius(atverimui_ar_saugojimui);
if size(seni_keliai,1) > 1
    seni_keliai=seni_keliai';
end
poaplankiai_dir=dir(dabartinis_kelias);
poaplankiai=setdiff({poaplankiai_dir([poaplankiai_dir.isdir]).name},{'.' '..'});
poaplankiai=cellfun(@(p) fullfile(dabartinis_kelias,p),poaplankiai,'UniformOutput',0);
keliai=[{pwd dabartinis_kelias} seni_keliai poaplankiai{:}];
switch atverimui_ar_saugojimui
    %case {'atverimui'} % nieko papildomo
    case {'saugojimui'}
        data=datestr(now,'YYYY-MM-DD');
        keliai=[keliai {tempdir fullfile(tempdir,'ritminukas') fullfile(tempdir,'ritminukas',data)}];
end
for k=1:length(keliai)
    keliai{k}=Tikras_Kelias(keliai{k});
end
keliai=unique(keliai);
i=find(ismember(keliai,dabartinis_kelias));
ats=listdlg('PromptString','Pasirinkite kelią:',...
    'ListString',keliai,...
    'SelectionMode','single',...
    'ListSize',[450 500],...
    'InitialValue',i);
if isempty(ats) || strcmp(h_txt.String,keliai{ats})
    return
end
h_txt.String=keliai{ats}; % kelias pasikeitė
f=h_txt.Callback;
if iscell(f)
    feval(f{1},h_txt,[],f{2:end}); % gui_atnaujink_rodomas_rinkmenas
else
    feval(f,h_txt,[]);
end

function gui_LentelesKintamujuZymejimas(~, ~, h_table1, pasirinkimas)
turinys=h_table1.Data;
susije_su_abp={'Tmsna' 'Kv' 'Knadr' 'Kne1' 'Kne2' 'Dne1' 'Dne2' 'Imax' 'Presp' 'r' 'R' 'C' 'L'};
switch pasirinkimas
    case {0 '0' false}
        turinys(:,end)={false};
    case {1 '1' true}
        turinys(:,end)={true};
    case {'-abp'}
        idx=find(ismember(h_table1.RowName,susije_su_abp));
        turinys(idx,end)={false}; %#ok
    case {'+abp'}
        idx=find(ismember(h_table1.RowName,susije_su_abp));
        turinys(idx,end)={true}; %#ok
    otherwise
        warning('Nežinau, ką daryti su pasirinkimu „%s“', pasirinkimas)
end
h_table1.Data=turinys;

function gui_susaldyk(h)
% Valdikliai įšaldomi - padaromi neaktyviais
if isstruct(h)
    h=atrink_tikrus_handles(h);
    %h=struct2array(h);
end
if ~isstruct(h) && length(h) > 1
    hc=h;
else
    try hc=h.Children; catch; hc=[]; end
end
if isempty(hc)
    switch h.Type
        case {'uicontrol'}
            switch h.Style
                case {'text'}
                    % nieko nedaryti
                case {'listbox'}
                    h.Enable='inactive';
                otherwise
                    h.Enable='off';
            end
        case {'uimenu'}
            h.Enable='off';
        case {'uipanel'}
            % nieko
        case {'uitable'}
            h.Enable='inactive';
        otherwise
            if ismember('Enable',fields(h)) % "isfield" netinka, nes grąžina 0 net jei laukas yra
                warning('%s tipas neapdorotas', h.Type)
            end
    end
else
    switch h.Type
        case {'figure'}
            set(h,'pointer','watch');
    end
    for h1=hc'
        gui_susaldyk(h1)
    end
end

function gui_susildyk_salyginius(h)
%gui_susildyk(h); % visus valdiklius
for hc=[...
        h.checkbox_islaikyti_katalogu_struktura ...
        h.trukme_checkbox ...
        h.trukme2_checkbox ...
        h.zymekliai_checkbox ...
        h.ikelti_senus_kaip_pradinius_checkbox ...
        h.R_tikras_checkbox ...
        h.saugoti_parametrus_checkbox ...
        h.saugoti_parametrus_poaplankyje_checkbox ...
        ] 
    cb=hc.Callback;
    if length(cb) >= 2
        feval(cb{1},hc,[],cb{2:end})
    end
end


function gui_susildyk(h)
% Valdikliai "susildomi" - padaromi aktyviais, leidžiame keisti parinktis
if isstruct(h)
    h=atrink_tikrus_handles(h);
    %h=struct2array(h);
end
if ~isstruct(h) && length(h) > 1
    hc=h;
else
    try hc=h.Children; catch; hc=[]; end
end
if isempty(hc)
    try
        switch h.Type
            case {'uicontrol' 'uimenu'}
                h.Enable='on';
            case {'uipanel'}
                % nieko
            case {'uitable'}
                h.Enable='on';
            otherwise
                if ismember('Enable',fields(h)) % "isfield" netinka, nes grąžina 0 net jei laukas yra
                    warning('„%s“ tipas neapdorotas', h.Type)
                end
        end
    catch err
        Pranesk_apie_klaida(err,'gui_susildyk','',1);
    end
else
    switch h.Type
        case {'figure'}
            set(h,'pointer','arrow');
    end
    for h1=hc'
        gui_susildyk(h1)
    end
end

function gui_bandymas_uzdaryti_langa(hFigObject,~,handles)
try
    if ishandle(hFigObject) %~isempty(findobj('-regexp','name',mfilename))
        if isfield(handles, 'checkbox_baigti_anksciau') && ishandle(handles.checkbox_baigti_anksciau) && ...
          strcmpi(handles.checkbox_baigti_anksciau.Visible,'on') && ...
          ~handles.checkbox_baigti_anksciau.Value % && handles.vykdyti.Value
            disp(' '); %disp('Naudotojas priverstinai uždaro langą!');
            handles.checkbox_baigti_anksciau.Value=1;
        elseif isfield(handles, 'rinkm_atnaujint') && ishandle(handles.rinkm_atnaujint) && ...
          strcmp(get(handles.rinkm_atnaujint,'Enable'),'on')
            delete(hFigObject);
        else
            button1 = ... % questdlg(lokaliz('Quit function help') , ...
                questdlg('Jei per klaidą nuspaudėte užvėrimo mygtuką, spauskite „Tęsti kaip buvo“. Jei dėl kažkokių priežasčių programa baigė darbus, bet neleidžia vėl keisti parametrų naujai užduočiai, tai spauskite „Atitirpdyti parinktis“. ', ...
                lokaliz('Quit function'), ...
                lokaliz('Close window'), lokaliz('Allow change options'), lokaliz('Continue as is'), ...
                lokaliz('Continue as is'));
            switch button1
                case lokaliz('Close window')
                    delete(hFigObject);
                    disp('Langą naudotojas užvėrė ');
                case lokaliz('Allow change options')
                    disp('Allow change options');
                    gui_susildyk(hFigObject);
                    gui_veiksenos_keitimas([],[],handles);
                    handles.checkbox_baigti_anksciau.Visible='off';
                    setappdata(handles.veiksena,'veiksena',[]);
                case lokaliz('Continue as is')
                    disp('Tęsiama');
            end
        end
    end
catch err
    %err.message
    Pranesk_apie_klaida(err,mfilename,'GUI langas',0);
end

function gui_kopijuoti_rinkmenu_sarasa(~,~,h_rinkm)
rinkmenos=gui_pasirinktieji_duomenys(h_rinkm);
if length(rinkmenos) == 1
    txt=rinkmenos{1};
else
    txt=sprintf('%s\n',rinkmenos{:});
end
clipboard('copy',txt);

function gui_kopijuoti_rinkmenu_sarasa_su_keliu(~,~,h_rinkm,h_katal1_txt)
[~,rinkmenos_su_keliu]=gui_pasirinktieji_duomenys(h_rinkm,h_katal1_txt);
if length(rinkmenos_su_keliu) == 1
    txt=rinkmenos_su_keliu{1};
else
    txt=sprintf('%s\n',rinkmenos_su_keliu{:});
end
clipboard('copy',txt);

function gui_modelio_keitimas(~,~,h_modelis,h_table1,h_mygtukas,h_ABP_checkbox)
mfilename_katal=fileparts(which(mfilename));
modelis=h_modelis.UserData{h_modelis.Value};
% ABP varnelė
if strcmpi(modelis,'ritminukas25str')
    h_ABP_checkbox.Value=1;
    h_ABP_checkbox.Enable='inactive';
    cb=h_ABP_checkbox.Callback;
    if length(cb) >= 2 && ~ischar(cb)
        feval(cb{1},h_ABP_checkbox,[],cb{2:end});
    end
elseif strcmpi(h_ABP_checkbox.Enable,'inactive')
    h_ABP_checkbox.Enable='on';
end

% Modelio parametrų lentelė
modelio_param_nauji=0;
modelio_param_rinkm=fullfile(mfilename_katal,[modelis '.txt']);
if ~exist(modelio_param_rinkm,'file')
    error('%s modelio parametrų lentelė nerasta.\n Sukurkite %s', modelis, modelio_param_rinkm);
end
try
    fid=fopen(modelio_param_rinkm,'r');
    table1_cont=textscan(fid,'%s%f%f%f%f','CollectOutput',1,'Delimiter',' ','MultipleDelimsAsOne',1,'CommentStyle','%');
    table1_cont=[table1_cont{1,1} num2cell(table1_cont{1,2})];
    lg=logical(cell2mat(table1_cont(:,end)));
    for i=1:length(lg); table1_cont{i,end}=lg(i); end
    table1_naudotini_stulp=1:4; % visi
    set(h_table1, ...
        'Data',     table1_cont(:,table1_naudotini_stulp+1), ...
        'UserData', table1_cont(:,table1_naudotini_stulp+1), ...
        'RowName',  table1_cont(:,1));
    %table1_ColumnFormat={'numeric', 'numeric', 'numeric', 'logical'};
    %h_table1.ColumnName=table1_stulp(table1_naudotini_stulp);
    %h_table1.ColumnFormat=table1_ColumnFormat(table1_naudotini_stulp);
    %h_table1.ColumnEditable=true;
    modelio_param_nauji=1;
catch err
    Pranesk_apie_klaida(err,'','',0);
end
try fclose(fid); catch; end

% Modelio aprašas - komentaras kaip debesėlis
aprasas='';
[~,lokale]=r_lokaliz('');
if modelio_param_nauji && isstruct(lokale) && isfield(lokale,'getLanguage') && ~isempty(lokale.getLanguage)
    modelio_apras_rinkm=fullfile(mfilename_katal,[modelis '.' upper(lokale.getLanguage) '.txt']);
    if exist(modelio_apras_rinkm,'file')
        try
            aprasas = fileread(modelio_apras_rinkm);
        catch err
            Pranesk_apie_klaida(err,'','',0);
        end
    elseif ~isequal(upper(lokale.getLanguage),'EN')
        modelio_apras_rinkm=fullfile(mfilename_katal,[modelis '.EN.txt']);
        if exist(modelio_apras_rinkm,'file')
            try
                aprasas = fileread(modelio_apras_rinkm);
            catch
            end
        end
    end
end
set(h_mygtukas,'TooltipString',aprasas);

function gui_nuo_checkbox_priklausomas_aktyvumas(h_valdantis,~,h_priklausomi, varargin)
if nargin > 3
    priklausomybe=varargin{1}; % 1 - normali; 0 - apversti
else
    priklausomybe=1; % 1 - normali
end
papildoma_salyga=0;
if nargin > 4
    h_salygojantis=varargin{2};
    for hs=h_salygojantis
        if ~h_salygojantis.Value
            papildoma_salyga=1;
        end
    end
end
for hc=h_priklausomi
    if ~strcmpi(h_valdantis.Enable,'off') && isequal(h_valdantis.Value,priklausomybe) && ~papildoma_salyga
        hc.Enable='on';
    elseif ~strcmpi(h_valdantis.Enable,'off') && h_valdantis.Value && priklausomybe == 0.5 && ~papildoma_salyga
        hc.Enable='inactive';
        hc.Value=1;
    elseif ~strcmpi(h_valdantis.Enable,'off') && ~h_valdantis.Value && priklausomybe == 0.5 && ~papildoma_salyga
        hc.Enable='on';
    else
        hc.Enable='off';
    end
    cb=hc.Callback;
    if length(cb) >= 2 && ~ischar(cb)
        feval(cb{1},hc,[],cb{2:end});
    end
end

function [rinkmenos,rinkmenos_su_keliu]=gui_pasirinktieji_duomenys(h_rinkm,h_katal1_txt)
rinkmenos={}; rinkmenos_su_keliu={};
rinkmenu_id_gui_sarase=h_rinkm.Value;
if isempty(rinkmenu_id_gui_sarase) || isempty(h_rinkm.String) || isempty(h_rinkm.UserData)
    return
end
rinkmenos=h_rinkm.UserData(rinkmenu_id_gui_sarase);
if nargout < 2
    return
end
duomenu_katalogas=h_katal1_txt.String;
for i=1:length(rinkmenos)
    try
        [~,~,rinkmenos_su_keliu1]=rinkmenos_tikslinimas(duomenu_katalogas,rinkmenos{i});
        rinkmenos_su_keliu{i}=rinkmenos_su_keliu1; %#ok
    catch err
        Pranesk_apie_klaida(err,[],[],0);
    end
end

function gui_perziureti_signalus(~, ~, h_rinkm, h_katal1_txt)
[~,rinkmenos_su_keliu]=gui_pasirinktieji_duomenys(h_rinkm,h_katal1_txt);
if isempty(rinkmenos_su_keliu)
    return
end
%fg=findobj('type','figure','Tag',mfilename);
fg=ancestor(h_rinkm,'figure','toplevel');
set(fg,'pointer','watch'); drawnow;
try
    katalogas_su_rinkmena=rinkmenos_su_keliu{1};
    [~,rinkmena,galune]=fileparts(katalogas_su_rinkmena);
    visakita=[];
    switch lower(galune)
        case {'.mat'}
            MAT_kintamieji = who('-file', katalogas_su_rinkmena);
            
            if ismember('fizio_datasets',MAT_kintamieji)
                load(katalogas_su_rinkmena,'fizio_datasets');
            else
                try
                    [fizio_datasets,~,visakita]=r_ikelk_fizio_signalus(katalogas_su_rinkmena);
                catch
                    if ismember('R_laikai_taisyti',MAT_kintamieji)
                        load(katalogas_su_rinkmena,'R_laikai_taisyti');
                        fizio_datasets.Rt=timeseries(R_laikai_taisyti, R_laikai_taisyti, 'Name', 'R laikai, s');
                    else
                        fizio_datasets=struct();
                    end
                end
            end
            if any(ismember({'Rtm' 'paklaidos_ivertis'},MAT_kintamieji)) || ...
                    all(ismember({'modelis' 'keiciamu_param_vardai' 'optimalus_param' 'fiksuoti_param'},MAT_kintamieji))
                
                if isempty(visakita)
                    visakita=load(katalogas_su_rinkmena);
                else
                    seni=load(katalogas_su_rinkmena);
                    if isfield(seni,'Rtm')
                        visakita.Rtm=seni.Rtm;
                    end
                    if isfield(seni,'Rt')
                        visakita.Rt=seni.Rt;
                    end
                    if isfield(seni,'parinktys')
                        visakita.parinktys=seni.parinktys;
                    end
                    if isfield(seni,'paklaidos_ivertis')
                        visakita.parinktys=seni.paklaidos_ivertis;
                    end
                    clear seni
                end
            end
        otherwise
            [fizio_datasets,~,visakita]=r_ikelk_fizio_signalus(katalogas_su_rinkmena);
    end
    if isstruct(fizio_datasets) && ~any(ismember({'Rt' 'ritmas'},fieldnames(fizio_datasets)))
        warning('Nerasta širdies ritmo arba EKG R laikų duomenų rinkmenoje:\n %s', katalogas_su_rinkmena)
        set(fg,'pointer','arrow'); drawnow;
        return
    end
    
    % FIXME: downsample greitesniam piešimui bei slinkimui 
    
    f=figure('Name',rinkmena, 'NumberTitle',0,'Units','normalized');
    f.Visible=0;
    a=axes('Parent',f);
    subttltxt='';
    %yyaxis(a,'left'); 
    
    % tikras ŠR
    if isfield(fizio_datasets,'Rt') && isa(fizio_datasets.Rt,'timeseries') 
        % tikras ŠR, atitinka R_laikai_taisyti
        visakita.Rt=unique(fizio_datasets.Rt.Time);
    end
    if isfield(visakita,'Rt') % tikras ŠR
        SR_tkr=60./diff(visakita.Rt);
        stairs(a,visakita.Rt(2:end),SR_tkr,'k.-');
    elseif isfield(fizio_datasets,'ritmas') && isa(fizio_datasets.ritmas,'timeseries')
        % Senasis būdas, kuris neatitinka R_laikai_taisyti kintamojo: paslinkta per 1! 
        visakita.Rt=unique(fizio_datasets.ritmas.Time);
        stairs(a,fizio_datasets.ritmas.Time(2:end),fizio_datasets.ritmas.Data(1:end-1),'k.-');
    end
    % modeliuotas ŠR
    if isfield(visakita,'Rtm') 
        hold(a,'on');
        if isfield(visakita,'parinktys') && isfield(visakita.parinktys,'R_greta') && ...
          ~isempty(visakita.parinktys.R_greta) && visakita.parinktys.R_greta && ...
           isfield(visakita.parinktys,'trukme') && length(visakita.parinktys.trukme) == 2
           modeliuojamas_laikotarpis=[visakita.parinktys.trukme(1) max(visakita.parinktys.trukme(2),visakita.Rtm(end)) ];
            [~,visakita.Rtm,~,SR_mdl]=R_sugretinimas(visakita.Rt,visakita.Rtm,modeliuojamas_laikotarpis);
            subttltxt=[subttltxt ' [' r_lokaliz('R gretinimas') '] '];
        else
            SR_mdl=60./diff(visakita.Rtm);
        end
        stairs(a,visakita.Rtm(2:end),SR_mdl,'r.-');
        if diff(visakita.Rtm([1 end])) > 300
            rodomas_laikas_nuo=floor(visakita.Rtm(1));
        else
            rodomas_laikas_nuo=floor(mean(visakita.Rtm([1 end]))-150);
        end
        legendai1={r_lokaliz('SR tikras') r_lokaliz('SR virtualus')};
    else
        rodomas_laikas_nuo=0;
        legendai1={r_lokaliz('SR tikras')};
    end
    if isfield(visakita,'paklaidos_ivertis')
        if isfield(visakita,'bauda') && visakita.bauda
            if isfield(visakita,'paklaidos_sudedamosios') 
                if ismember({'RRI'},visakita.paklaidos_sudedamosios)
                    % senosios versijos iki 2023-02-09 dalindavo RRI iš 10; naujesnėse versijose tam yra atskiri raktai 'RRIms' ir 'RRI/10'
                    visakita.bauda=visakita.bauda*10;
                    visakita.paklaidos_ivertis=visakita.paklaidos_ivertis*10;
                end
                if ismember({'bauda'},visakita.paklaidos_sudedamosios)
                    subttltxt=[sprintf([' (' r_lokaliz('is ju %g baudos') ')'], visakita.bauda) subttltxt];
                else
                    subttltxt=[sprintf([' (' r_lokaliz('%g bauda neisk.') ')'], visakita.bauda) subttltxt];
                end
            else
                subttltxt=[sprintf([' (' r_lokaliz('%g baudos') ')'], visakita.bauda) subttltxt];
            end
        end
        subttltxt=[sprintf('%s: %f', r_lokaliz('Paklaida'), visakita.paklaidos_ivertis) subttltxt];
    end
    %a.YColor='r';
    ylabel(a, r_lokaliz('Sirdies ritmas, k/min'))
    %yyaxis(a,'left');
    title(a,rinkmena,'Interpreter','none');
    if ~isempty(subttltxt)
        subtitle(a,subttltxt,'Interpreter','none');
    end
    a.YLim=a.YLim; % fiksuos Y ribas - kad nevažinėtų slenkant
    if      (ismember('abp',fieldnames(fizio_datasets)) && ~isempty(fizio_datasets.abp)) || ...
            (ismember('DBP_real',fieldnames(fizio_datasets)) && ~isempty(fizio_datasets.DBP_real)) || ...
            (ismember('SBP_real',fieldnames(fizio_datasets)) && ~isempty(fizio_datasets.SBP_real))
        f.OuterPosition=[0 0.05 1 0.95];
        xl=findobj(a,'String','Laikas, s'); 
        set(xl,'Units','normalized');
        xl_pd=get(xl,'Position');
        subplot(2,1,1,a);
        a.Position=[0.05 a.Position(2) 0.9 a.Position(4)];
        set(xl,'Position',xl_pd);
        a2=axes('Parent',f);
        subplot(2,1,2,a2);
        linkaxes([a a2],'x');
        hold(a2,'on')
        %s=stairs(a2,fizio_datasets.ritmas.Time,fizio_datasets.ritmas.Data,'r'); % nupiesti tik laikinai – kad atsirastų scrollplot slankiklyje
        xlabel(a2,r_lokaliz('Laikas, s'))
        axp=get(a2,'Position');
        scra=scrollplot3(a2,'MinX',rodomas_laikas_nuo,'WindowSizeX',300);
        f.Visible=0;drawnow;
        a2.Position=[0.05 a2.Position(2) 0.9 axp(4)];
        scra.Position=[scra.Position(1) 0.03 scra.Position([3 4])];
        %scra.Position=[scra.Position(1) 0.025 scra.Position([3 4])];
        set(get(a2,'XLabel'),'Position',[0.5,-0.15,0]);
        legendai2={};
        if ismember({'abp'},fieldnames(fizio_datasets)) && isa(fizio_datasets.abp,'timeseries') && length(fizio_datasets.abp.Time) > 2
            ret=max(floor(0.01/diff(fizio_datasets.abp.Time([1 2]))),1);
            plot(a2,fizio_datasets.abp.Time(1:ret:end),fizio_datasets.abp.Data(1:ret:end),'m');
            legendai2=[legendai2 r_lokaliz('momentinis KS') ];
        end
        if ismember({'DBP_real'},fieldnames(fizio_datasets)) && isa(fizio_datasets.DBP_real,'timeseries') && length(fizio_datasets.DBP_real.Time) > 2
            ret=max(floor(0.2/diff(fizio_datasets.DBP_real.Time([1 2]))),1);
            plot(a2,fizio_datasets.DBP_real.Time(1:ret:end),fizio_datasets.DBP_real.Data(1:ret:end),'b');
            legendai2=[legendai2 r_lokaliz('diastolinis KS') ];
        end
        if ismember({'SBP_real'},fieldnames(fizio_datasets)) && isa(fizio_datasets.SBP_real,'timeseries') && length(fizio_datasets.SBP_real.Time) > 2
            ret=max(floor(0.2/diff(fizio_datasets.SBP_real.Time([1 2]))),1);
            plot(a2,fizio_datasets.SBP_real.Time(1:ret:end),fizio_datasets.SBP_real.Data(1:ret:end),'r');
            legendai2=[legendai2 r_lokaliz('sistolinis KS') ];
        end
        legend(a2,legendai2);
        if length(legendai2)~=2
            legend(a2,'off')
        end
        %delete(s);
        ylabel(a2, r_lokaliz('Kraujo spaudimas, mmHg'));
        %a2.YLim=a2.YLim; % fiksuos Y ribas - kad nevažinėtų slenkant
    else
        f.OuterPosition=[0 0.4 1 0.6];
        xlabel(a,'Laikas, s')
        scra=scrollplot3(a,'MinX',rodomas_laikas_nuo,'WindowSizeX',300);
        scra.Position=[scra.Position(1) 0.03 scra.Position([3 4])];
        set(get(a,'XLabel'),'Position',[0.5,-0.15,0]);
        f.Visible=0; drawnow;
        a.Position=[0.05 a.Position(2) 0.9 a.Position(4)];
    end
    scra.XLim=[0 visakita.Rt(end)];
    %scra.Position=[scra.Position(1) scra.Position(2)+0.02 scra.Position(3) scra.Position(4)-0.02];
    if isfield(fizio_datasets,'kvepavimas') && isa(fizio_datasets.kvepavimas,'timeseries') 
        yyaxis(a,'right'); a.YColor='b';
        ret=max(floor(0.1/diff(fizio_datasets.kvepavimas.Time([1 2]))),1);
        plot(a,fizio_datasets.kvepavimas.Time(1:ret:end),fizio_datasets.kvepavimas.Data(1:ret:end),'c');
        ylabel(a,r_lokaliz('Kvepavimas, n.v.'))
        a.YLim=[0 1]-0.5; % fiksuos Y ribas - kad nevažinėtų slenkant
        legendai1=[legendai1 {r_lokaliz('Kvepavimas')}];
    end
    legend(a,legendai1);
    if length(legendai1)<3
        legend(a,'off')
    end
    
    if isfield(visakita,'modelis') && isfield(visakita,'keiciamu_param_vardai') && ...
       isfield(visakita,'optimalus_param') && isfield(visakita,'fiksuoti_param')
        nerodytini_fiksuoti_kintamieji={'SIMUL' 'R_tikras' 'R_greta' 'Ssmpt' 'Tbf'};
        fiksuoti_param=rmfield(visakita.fiksuoti_param,nerodytini_fiksuoti_kintamieji(ismember(nerodytini_fiksuoti_kintamieji,fieldnames(visakita.fiksuoti_param))));
        struct2txt2=@(strc)cellfun(@(flds)sprintf('%s=%.5g; ', flds,strc.(flds)), fieldnames(strc), 'UniformOutput', false);
        modelio_param_strc=cell2struct(num2cell(visakita.optimalus_param(:)),visakita.keiciamu_param_vardai(:));
        modelio_param_clstr=[struct2txt2(modelio_param_strc); {' '}; struct2txt2(fiksuoti_param)]; % struct2txt(visakita.fiksuoti_param)
        % sąrašas apačioje
        infotxt=sprintf('%s', modelio_param_clstr{:});
        hinf=uicontrol(f, 'style','text', 'String',infotxt,'FontSize',6, 'Units','normalized', 'Position', [0.05 0.0 0.95 0.03], 'HorizontalAlignment','left','Tag','ParamInfoTXT');
        hinf.Visible=0;
        % informacijos mygtukas kopijavimui
        infotxt=sprintf('%s\n', ['%' rinkmena], ['%  ' visakita.modelis], '%  modelio parametrai:', ' ', modelio_param_clstr{:});
        infotxt=strrep(infotxt,sprintf('\n \n \n'),sprintf('\n \n')); 
        infostrc=cell2struct([struct2cell(visakita.fiksuoti_param);num2cell(visakita.optimalus_param(:))],[fieldnames(visakita.fiksuoti_param);visakita.keiciamu_param_vardai(:)]);
        infocb=['ans=get(gco,''Tooltip'');  clipboard(''copy'',ans); ' ...
            'ans=findobj(gcf,''Type'',''uicontrol'',''style'',''text'',''Tag'',''ParamInfoTXT''); ' ...
            'try set(ans,''Visible'',1-get(ans,''Visible'')); catch; end; ' ...
            'if exist(''scrollplot2'',''file'') && exist(''scrollplot3'',''file''); ' ...
               'try set(findobj(findobj(gcf,''Type'',''Axes'',''Tag'',''scrollAx'')),''Visible'',1-get(ans,''Visible'')); catch; end; ' ...
               'ans={''WindowButtonDownFcn'' ''WindowButtonUpFcn'' ''WindowButtonMotionFcn'' ''WindowScrollWheelFcn'' ''WindowKeyPressFcn'' ''WindowKeyReleaseFcn''}; ' ...
               'if isempty(get(gcf,''UserData'')); set(gcf,''UserData'',{'''' '''' '''' '''' '''' ''''}); end; ' ...
               'ans=[ans; get(gcf,''UserData'')]; try set(gcf,ans{:},''UserData'',get(gcf,ans(1,:))); catch; end; ' ...
            'end; ans=get(gco,''UserData''); drawnow'];
        uicontrol(f, 'style','pushbutton', 'Units','normalized','Position',[0.01 0.01 0.02 0.04],...
            'String','i','Tooltip',infotxt, 'UserData', infostrc, 'Callback', infocb);
    end
    %{
    if isunix && ~ismac % Linux?
       f.OuterPosition=[0 0 1 1];
    else
        f.OuterPosition=[0 0.05 1 0.95];
    end
    %}
    f.Visible=1;
catch err
    Pranesk_apie_klaida(err,[],[],0);
end
set(fg,'pointer','arrow'); drawnow;

function gui_RRI_perziura(~,~,h_rinkm,h_katal1_txt)
fig=ancestor(h_rinkm,'figure','toplevel');
set(fig,'pointer','watch'); drawnow;
[~,rinkmenos_su_keliu]=gui_pasirinktieji_duomenys(h_rinkm,h_katal1_txt);
for fi=1:length(rinkmenos_su_keliu)
    try
        katalogas_su_rinkmena=rinkmenos_su_keliu{fi};
        [katalogas,vardas]=fileparts(katalogas_su_rinkmena);
        R_laikai_taisyti=[];
        EKG=[];
        katalogas_su_rinkmena_RRIs={ katalogas_su_rinkmena ...
            fullfile(katalogas,[vardas '.rrt']) ...
            fullfile(katalogas,'RRI',[vardas '.rrt']) ...
            fullfile(katalogas,[vardas '_rri.mat']) ...
            fullfile(katalogas,[vardas '_RRI.mat']) ...
            fullfile(katalogas,'RRI',[vardas '_RRI.mat']) };
        
        for ri=1:length(katalogas_su_rinkmena_RRIs)
            katalogas_su_rinkmena_RRI=katalogas_su_rinkmena_RRIs{ri};
            if exist(katalogas_su_rinkmena_RRI,'file')
                try
                    MAT_kintamieji = who('-file', katalogas_su_rinkmena_RRI);
                    if ismember({'R_laikai_taisyti'},MAT_kintamieji)
                        load(katalogas_su_rinkmena_RRI,'-mat','R_laikai_taisyti');
                        fprintf('R laikai įkelti iš\n %s\n', katalogas_su_rinkmena_RRI);
                        if ismember({'EKG'},MAT_kintamieji)
                            load(katalogas_su_rinkmena_RRI,'-mat','EKG');
                        else
                            [~, ~, visakita]=r_ikelk_fizio_signalus(katalogas_su_rinkmena);
                            if ~isempty(visakita) && isstruct(visakita) && isfield(visakita,'EKG')
                                EKG=visakita.EKG;
                            end
                        end
                        if ~isempty(R_laikai_taisyti)
                            break;
                        end
                    end
                catch
                end
            end
        end
        
        if isempty(R_laikai_taisyti)
            r_ikelk_fizio_signalus(katalogas_su_rinkmena); % turėtų susitvarkyti automatiškai
            %{
            [fizio_datasets, ~, visakita]=r_ikelk_fizio_signalus(katalogas_su_rinkmena);
            R_laikai_taisyti=fizio_datasets.Rt.Data;
            %visakita.EKG;
            %}
        else
            R_laikai_taisyti0=R_laikai_taisyti;
            if ~isempty(EKG) && isa(EKG,'timeseries') 
                R_laikai_taisyti=pop_RRI_perziura(R_laikai_taisyti, 1, EKG.Data, EKG.Time);
            else
                R_laikai_taisyti=pop_RRI_perziura(R_laikai_taisyti, 1);
            end
            if ~isempty(R_laikai_taisyti) ...
                    && ~isequal(numel(R_laikai_taisyti),numel(R_laikai_taisyti0)) ...
                    && max(abs(R_laikai_taisyti-R_laikai_taisyti0)) > 0.0005
                RRI_kelias=fileparts(katalogas_su_rinkmena_RRI);
                if ~exist(RRI_kelias,'dir')
                    mkdir(RRI_kelias);
                end
                if exist(katalogas_su_rinkmena_RRI,'file')
                    save(katalogas_su_rinkmena_RRI,'R_laikai_taisyti','-mat','-append');
                else
                    save(katalogas_su_rinkmena_RRI,'R_laikai_taisyti','-mat');
                end
                fprintf('R laikai įrašyti į\n %s\n', katalogas_su_rinkmena_RRI);
            end
        end
    catch err
        Pranesk_apie_klaida(err,[],[],0);
    end
    disp(' ')
end
set(fig,'pointer','arrow'); drawnow;


function gui_skydelio_perjungimas(mygt_valdantis,~,pnl_aktyvuok,mygt_isjunk,pnl_isjunk)
set(mygt_isjunk,    'Value',0, 'FontSize',9,  'FontWeight','normal');
set(mygt_valdantis, 'Value',1, 'FontSize',10, 'FontWeight','bold');
set(pnl_isjunk,'Visible','off');
set(pnl_aktyvuok,'Visible','on');

function gui_stiliaus_keitimas
    
    %lnfs = javax.swing.UIManager.getInstalledLookAndFeels();
    %for idx = 1 : length( lnfs )
    %    disp(char(lnfs(idx).getClassName))
    %end
    old_lnf=javax.swing.UIManager.getLookAndFeel;
    %lnf=old_lnf;
        
    try
        %lnf=javax.swing.plaf.nimbus.NimbusLookAndFeel;
        %lnf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel;
        %lnf=javax.swing.plaf.metal.MetalLookAndFeel; 
        %lnf=com.jgoodies.looks.windows.WindowsLookAndFeel; % Windows only
        lnf=com.jgoodies.looks.plastic.PlasticXPLookAndFeel;
        %lnf=com.jgoodies.looks.plastic.Plastic3DLookAndFeel; % MATLAB online
        %lnf=com.jgoodies.looks.plastic.PlasticLookAndFeel;
        %lnf=de.javasoft.plaf.synthetica.SyntheticaStandardLookAndFeel;
        
        %JTattoo_path=which('JTattoo.jar');
        %if  ~isempty(JTattoo_path)
            %javaclasspath( {fileparts(JTattoo_path), JTattoo_path} );
            %lnf=com.jtattoo.plaf.smart.SmartLookAndFeel;         % Smart
            %lnf=com.jtattoo.plaf.aluminium.AluminiumLookAndFeel; % Aluminium
            %lnf=com.jtattoo.plaf.acryl.AcrylLookAndFeel;         % Acryl
            %lnf=com.jtattoo.plaf.aero.AeroLookAndFeel;           % Aero
            %lnf=com.jtattoo.plaf.bernstein.BernsteinLookAndFeel; % Bernstein
            %lnf=com.jtattoo.plaf.graphite.GraphiteLookAndFeel;   % Graphite
            %lnf=com.jtattoo.plaf.fast.FastLookAndFeel;           % Fast
            %lnf=com.jtattoo.plaf.hifi.HiFiLookAndFeel;           % Hifi
            %lnf=com.jtattoo.plaf.luna.LunaLookAndFeel;           % Luna
            %lnf=com.jtattoo.plaf.mcwin.McWinLookAndFeel;         % McWin
            %lnf=com.jtattoo.plaf.mint.MintLookAndFeel;           % Mint
            %lnf=com.jtattoo.plaf.noire.NoireLookAndFeel;         % Noire
        %end
        
        if ~isequal(old_lnf,lnf)
            drawnow();
            javax.swing.UIManager.setLookAndFeel(lnf);
            drawnow();
        end
        
        % update
        %dt=com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame();
        %javaMethodEDT('updateComponentTreeUI', 'javax.swing.SwingUtilities',dt);
        %drawnow();
    catch err
        Pranesk_apie_klaida(err,'','',0);
    end


function gui_veiksenos_keitimas(~,~,h)
veiksena_sena=getappdata(h.veiksena,'veiksena');
veiksena=h.veiksena.UserData{h.veiksena.Value};
setappdata(h.veiksena,'veiksena',veiksena);
ar_veiksena_pasikeite=~isequal(veiksena,veiksena_sena);
reguliuojamieji=[...
    h.trukme_checkbox h.trukme2_checkbox h.zymekliai_checkbox ...
    h.ikelti_senus_kaip_pradinius_checkbox ...
    h.ABP_checkbox h.R_tikras_checkbox h.R_greta_checkbox ...
    h.paklaidos_sudedamosios h.paklaidos_bauda_checkbox h.issamesne_iteraciju_info_checkbox ...
    h.rodyti_grafikus_checkbox h.saugoti_grafikus_checkbox h.saugoti_parametrus_checkbox ...
    h.apskaiciuotas_HRbasal_checkbox ];
switch lower(veiksena)
    case {'tik_nuskaityti'}
        set(reguliuojamieji,'Enable','off')
        h.apskaiciuotas_HRbasal_checkbox.UserData=h.apskaiciuotas_HRbasal_checkbox.Value;
        h.apskaiciuotas_HRbasal_checkbox.Value=0;
    otherwise
        set(reguliuojamieji,'Enable','on')
        if ar_veiksena_pasikeite
            h.apskaiciuotas_HRbasal_checkbox.Value=h.apskaiciuotas_HRbasal_checkbox.UserData;
        else
            h.apskaiciuotas_HRbasal_checkbox.UserData=h.apskaiciuotas_HRbasal_checkbox.Value;
        end
        
        switch lower(veiksena)
            case {'1'}
                h.issamesne_iteraciju_info_checkbox.UserData=h.issamesne_iteraciju_info_checkbox.Value;
                set([h.issamesne_iteraciju_info_checkbox], 'Value', 1,'Enable','off');
            otherwise
                if h.issamesne_iteraciju_info_checkbox.Value && ar_veiksena_pasikeite
                    h.issamesne_iteraciju_info_checkbox.Value=h.issamesne_iteraciju_info_checkbox.UserData;
                else
                    h.issamesne_iteraciju_info_checkbox.UserData=h.issamesne_iteraciju_info_checkbox.Value;
                end
                h.issamesne_iteraciju_info_checkbox.Enable='on';
        end
end
switch lower(veiksena)
     case {'ikelti_i_workspace' 'simul'}
         set([h.trukme2_checkbox h.zymekliai_checkbox ...
             h.ABP_checkbox h.R_tikras_checkbox h.R_greta_checkbox ...
             h.paklaidos_sudedamosios h.paklaidos_bauda_checkbox h.issamesne_iteraciju_info_checkbox ...
             h.rodyti_grafikus_checkbox h.saugoti_grafikus_checkbox h.saugoti_parametrus_checkbox],...
             'Enable','off')
end
switch lower(veiksena)
    case {'auto' 'optimizavimas' 'optimizavimas_lygiagretus'}
        set(h.paieskos_algoritmas,'Visible','on');
        if strcmpi(veiksena,'optimizavimas_lygiagretus')
            if h.paieskos_algoritmas.Value == 8
                h.paieskos_algoritmas.Value=1;
            end
            h.paieskos_algoritmas.String=h.paieskos_algoritmas.String(1:7);
        else
            h.paieskos_algoritmas.String=[h.paieskos_algoritmas.String(1:7); {'GlobalSearch'}];
        end
    otherwise
        set(h.paieskos_algoritmas,'Visible','off');
end
modelis=h.modelis.UserData{h.modelis.Value};
if strcmpi(modelis,'ritminukas25str')
    h.ABP_checkbox.Value=1;
    h.ABP_checkbox.Enable='inactive';
    cb=h.ABP_checkbox.Callback;
    if length(cb) >= 2 && ~ischar(cb)
        feval(cb{1},h.ABP_checkbox,[],cb{2:end});
    end
elseif strcmpi(h.ABP_checkbox.Enable,'inactive')
    h.ABP_checkbox.Enable='on';
end
gui_susildyk_salyginius(h);

    
function gui_VYKDYMAS(ho,~, handles)
t0=tic;
gui_veiksenos_keitimas([],[],handles);
fig=ancestor(ho,'figure','toplevel');
rinkmenu_id_gui_sarase=handles.rinkm.Value;
if isempty(rinkmenu_id_gui_sarase) || isempty(handles.rinkm.String) || isempty(handles.rinkm.UserData)
    set(handles.rinkm, 'BackgroundColor', 'r');
    drawnow; pause(1); % vienai sekundei sublyksėti
    set(handles.rinkm, 'BackgroundColor', 'w');
    return
end

handles_tikri=atrink_tikrus_handles(handles);
neuzbaigtu_interakciju_mygtukai=findobj(handles_tikri,'flat','BackgroundColor',[1 1 0]); % su geltonu fonu
if ~isempty(neuzbaigtu_interakciju_mygtukai)
    set(neuzbaigtu_interakciju_mygtukai, 'BackgroundColor', 'r'); % raudona
    drawnow; pause(1); % vienai sekundei sublyksėti
    set(neuzbaigtu_interakciju_mygtukai, 'BackgroundColor', 'w');
    drawnow
    return
end

kelias_pradinis=pwd;
apdorotinos_duomenu_rinkmenos=handles.rinkm.UserData(rinkmenu_id_gui_sarase);
neapdorotos_duomenu_rinkmenos=apdorotinos_duomenu_rinkmenos;
duomenu_katalogas=handles.katal1_txt.String;
rezultatu_katalogas=handles.katal2_txt.String;
if strcmp(duomenu_katalogas,rezultatu_katalogas)
    mygt=questdlg('Atsargiai: pasirinkote, kad rezultatai būtų tame pačiame aplanke kaip ir pradiniai duomenys. Ar tikrai norite tęsti?', ...
        'Rezultatų katalogo patvirtinimas', 'Taip','Ne','Ne');
    if ~strcmp(mygt,'Taip')
        return
    end
end
PRADZIOS_LAIKAS=now;
PRADZIOS_LAIKAS_str =datestr(PRADZIOS_LAIKAS, 'yyyy-mm-dd HH:MM:SS');
PRADZIOS_LAIKAS_str_=datestr(PRADZIOS_LAIKAS, 'yyyy-mm-dd_HHMMSS');

vienkartine_veiksena=getappdata(handles.veiksena,'veiksena');
if isempty(vienkartine_veiksena)
    rezultatu_rinkmena=fullfile(rezultatu_katalogas,['Ritminukas_' PRADZIOS_LAIKAS_str_ '_rezultatai.txt']); % numatytuoju atveju
else
    rezultatu_rinkmena=fullfile(tempdir,['Ritminukas_' PRADZIOS_LAIKAS_str_ '_rezultatai.txt']);
end
rezultatu_rinkmenos_id=fopen(rezultatu_rinkmena,'a');
if rezultatu_rinkmenos_id < 0
    set(handles.katal2_txt, 'BackgroundColor', 'r');
    drawnow; pause(1)
    set(handles.katal2_txt, 'BackgroundColor', 'y');
    return
end


if isempty(vienkartine_veiksena)
    diary(fullfile(rezultatu_katalogas,['Ritminukas_' PRADZIOS_LAIKAS_str_ '_eiga.txt']))
end

disp(' ');
disp(' ');
disp('===================================');
disp(['      RITMINUKAS ' versija]);
disp(' ');
disp(['        ' PRADZIOS_LAIKAS_str ]);
disp('===================================');
disp(' ');

% Neleisti spausti mygtukų ir keisti parinkčių
gui_susaldyk(fig);
handles.checkbox_baigti_anksciau.Value=0;
handles.checkbox_baigti_anksciau.Visible='on';
handles.checkbox_baigti_anksciau.Enable='on';
handles.checkbox_baigti_anksciau.UserData=[];
set(findobj(fig,'Tag','Visada veiksnus'),'Enable','on');
set(fig,'pointer','watch'); drawnow;

if isempty(vienkartine_veiksena)
    irasyk_kelius(duomenu_katalogas,'atverimui');
    irasyk_kelius(rezultatu_katalogas,'saugojimui');
else
    apdorotinos_duomenu_rinkmenos=apdorotinos_duomenu_rinkmenos(1);
    rinkmenu_id_gui_sarase=rinkmenu_id_gui_sarase(1);
end

fprintf('\nDirbsima su katalogo\n %s\nduomenų rinkmenomis (%d):\n%s\n',...
    duomenu_katalogas, length(rinkmenu_id_gui_sarase), sprintf(' %s\n',apdorotinos_duomenu_rinkmenos{:}));
fprintf('Rezultatai talpinsimi\n %s\n\n', rezultatu_katalogas);

% bendrieji kintamieji
parinktys=struct();
parinktys.v=versija;
parinktys.modelis=handles.modelis.UserData{handles.modelis.Value};
parinktys.laikas=PRADZIOS_LAIKAS_str_;
if ~isempty(vienkartine_veiksena)
    parinktys.veiksena=vienkartine_veiksena;
    setappdata(handles.veiksena,'veiksena',[]);
else
    parinktys.veiksena=handles.veiksena.UserData{handles.veiksena.Value};
end
if ismember(lower(parinktys.veiksena),{'auto' 'optimizavimas' 'optimizavimas_lygiagretus'})
    parinktys.paieskos_algoritmas=handles.paieskos_algoritmas.UserData{handles.paieskos_algoritmas.Value};
end
if handles.trukme_checkbox.Value
    parinktys.trukme=str2num(handles.trukme_edit.String); %#ok str2double netinka, nes gali būti keli skaičiai langelyje
end
if handles.trukme2_checkbox.Value
    parinktys.trukme2=str2num(handles.trukme2_edit.String); %#ok 
end
if handles.zymekliai_checkbox.Value
    parinktys.zymekliai=str2num(handles.zymekliai_edit.String); %#ok 
end
if handles.ikelti_senus_kaip_pradinius_checkbox.Value
    parinktys.ikelti_senus_kaip_pradinius=handles.ikelti_senus_kaip_pradinius_popupmenu.Value;
end
parinktys.ABP=handles.ABP_checkbox.Value;
if handles.R_tikras_checkbox.Value
    parinktys.R_tikras=1;
    if handles.R_greta_checkbox.Value
        parinktys.R_greta=1;
    else
        parinktys.R_greta=0;
    end
else
    parinktys.R_tikras=0;
end
parinktys.paklaidos_sudedamosios=handles.paklaidos_sudedamosios.UserData{handles.paklaidos_sudedamosios.Value};
if handles.paklaidos_bauda_checkbox.Value
    parinktys.paklaidos_sudedamosios=[parinktys.paklaidos_sudedamosios {'bauda'}];
end
parinktys.issamesne_iteraciju_info=handles.issamesne_iteraciju_info_checkbox.Value;
parinktys.rodyti_grafikus=handles.rodyti_grafikus_checkbox.Value;
parinktys.saugoti_grafikus=handles.saugoti_grafikus_checkbox.Value;
if handles.saugoti_parametrus_checkbox.Value
    parinktys.saugoti_parametrus=1;
    if handles.saugoti_parametrus_poaplankyje_checkbox.Value
        %parinktys.saugoti_parametrus_poaplankyje=1;
        parinktys.saugoti_parametrus_poaplankyje=handles.saugoti_parametrus_poaplankyje_edit.String;
        if handles.trukme_checkbox.Value
            parinktys.saugoti_parametrus_poaplankyje=strrep(parinktys.saugoti_parametrus_poaplankyje,'%T',[strrep(handles.trukme_edit.String,' ','-') 's']);
        else
            parinktys.saugoti_parametrus_poaplankyje=strrep(parinktys.saugoti_parametrus_poaplankyje,'%T','');
        end
        parinktys.saugoti_parametrus_poaplankyje=strrep(parinktys.saugoti_parametrus_poaplankyje,'%d',datestr(PRADZIOS_LAIKAS,'yyyy-mm-dd'));
    end
else
    parinktys.saugoti_parametrus=0;
end
if handles.apskaiciuotas_HRbasal_checkbox.Value
    parinktys.apskaiciuotas_HRbasal=1;
end
parinktys.modelio_kintamieji=[handles.table1.RowName handles.table1.Data];
if ismember(parinktys.modelis,{'ritminukas24str' 'ritminukas25str'})
    kintam_i=find(ismember(parinktys.modelio_kintamieji(:,1),{'Sparas' 'HRbasal' 'Drsa' 'Krsa' 'Trsa' 'Kcvlm' 'Dcvlm' 'Arvlm_sp' 'Arvlm_mx' 'Ks' 'Tmsna' 'Pk' 'Kb' 'Peq' 'Kab' 'Bmax'}));
    parinktys.modelio_kintamieji=parinktys.modelio_kintamieji(kintam_i,:);
end
if ismember(lower(parinktys.veiksena),{'-' 'tik_nuskaityti'})
    parinktys.modelio_kintamieji(:,end)={true};
end

fprintf(rezultatu_rinkmenos_id,'MATLAB %s',version);
try fprintf(rezultatu_rinkmenos_id,', %s',char(java.util.Locale.getDefault())); catch; end
try fprintf(rezultatu_rinkmenos_id,' %s',feature('DefaultCharacterSet')); catch; end
if ispc 
    OS='Windows';
elseif isunix 
    if ismac
        OS='MAC'; 
    else
        OS='Linux'; 
    end
else
    OS='';
end
fprintf(rezultatu_rinkmenos_id,', %s\n', OS);
fprintf(rezultatu_rinkmenos_id,'%s\n', PRADZIOS_LAIKAS_str);
fprintf(rezultatu_rinkmenos_id,'Ritminukas %s\n',versija);
if ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
    % rezultatų suvestinėje vėliau rodyti visus modelio parametrus
    keiciamu_kintamuju_id=1:size(parinktys.modelio_kintamieji,1); 
else
    fprintf(rezultatu_rinkmenos_id,['\t\t' r_lokaliz('Parinktys') ':\n']);
    parinktys_tekstu=struct2txt(parinktys,'\t');
    fprintf(rezultatu_rinkmenos_id,parinktys_tekstu);
    % rezultatų suvestinėje vėliau rodyti tik naudotojo pasirinktus parametrus
    keiciamu_kintamuju_id=find(cell2mat(parinktys.modelio_kintamieji(:,end))); 
end
fprintf(rezultatu_rinkmenos_id,['\nID1\tID2\tID3\t' r_lokaliz('Rezultatu laikas')]);
info={r_lokaliz('Pradzia, s') r_lokaliz('Pabaiga, s') ...
    r_lokaliz('Bendra paklaida') r_lokaliz('SR paklaida') r_lokaliz('KS paklaida') r_lokaliz('Bauda paklaidoje') ...
    r_lokaliz('Tikro SDNN') r_lokaliz('Prasukimai') r_lokaliz('(M)SNA poslinkis, s')};
info=[info parinktys.modelio_kintamieji(keiciamu_kintamuju_id,1)' ];
fprintf(rezultatu_rinkmenos_id,'\t%s', info{:});
fprintf(rezultatu_rinkmenos_id,'\n');

% Parametrų įrašymas į MAT
%{
if ~ismember(lower(parinktys.veiksena),{'ikelti_i_workspace'}) %  '-' 'tik_nuskaityti'
    save(fullfile(rezultatu_katalogas,['Ritminukas_' PRADZIOS_LAIKAS_str_ '_parinktys.mat']),'parinktys');
end
%}

if ismember(parinktys.veiksena,{'auto' '1' 'optimizavimas' 'optimizavimas_lygiagretus' 'SIMUL'})
    fprintf('Naudojamas Simulink modelis:\n %s\n\n',parinktys.modelis)
end
if strcmpi(parinktys.veiksena,'optimizavimas_lygiagretus')
    try
        load_system(parinktys.modelis);
        set_param(parinktys.modelis,'SignalLogging','off');
        set_param(parinktys.modelis,'InstrumentedSignals',[]);
        
        poolobj = gcp('nocreate');
        if isempty(poolobj)
            poolobj=parpool('local'); %#ok
            fprintf('\n')
        end
        
        %set_param(parinktys.modelis,'AccelVerboseBuild','on');
        % Build the Rapid Accelerator target
        %rtp = Simulink.BlockDiagram.buildRapidAcceleratorTarget(parinktys.modelis);
        %disp(rtp);
    catch err
        w=warning('on');
        Pranesk_apie_klaida(err,[],[],0);
        warning(w);
    end
end


% Darbas su kiekviena rinkmena atskirai
sukti_cikla=1;
while sukti_cikla
  % #FIXME: perkelti dėl 'auto' veiksenos esantį WHILE ciklą į FOR vidų (kad suktų tą pačią rinkmeną), o ne veiksenas keistų visoms rinkmenoms bendrai
  for ei=1:length(rinkmenu_id_gui_sarase)
    try
        % Pasiruošimas darbui su viena rinkmena
        rinkmena_gui_sarase=apdorotinos_duomenu_rinkmenos{ei};
        fprintf('Apdorojama #%d/%d (%.2f%%):\n %s\n', ...
            ei, length(rinkmenu_id_gui_sarase),  ...
            ei/length(rinkmenu_id_gui_sarase)*100, ...
            rinkmena_gui_sarase);
        [~,~,katalogas_su_rinkmena]=rinkmenos_tikslinimas(duomenu_katalogas,rinkmena_gui_sarase);
        % vardas pavadinimams, pvz, paveikslų antraštėms
        [santykinis_poaplankis,vardas,~]=fileparts(rinkmena_gui_sarase);
        vardas=regexprep(vardas,'.ritminukas.*$','');
        vardas=regexprep(vardas,'^Aurimod([0-9][0-9])_New','Aurimod$1');
        % vardas identifikavimui rezultatų rinkmenos pirmame stulpelyje
        vardas_rezultatams=rinkmena_gui_sarase;
        %vardas_rezultatams=regexprep(vardas_rezultatams,'.ritminukas.*.mat$','');
        vardas_rezultatams=regexprep(vardas_rezultatams,'.mat$','');
        %vardas_rezultatams=regexprep(vardas_rezultatams,'^Aurimod([0-9][0-9])_New','Aurimod$1');
        
        % Katalogas rezultatams
        if handles.checkbox_islaikyti_katalogu_struktura.Value && ~ismember(lower(parinktys.veiksena), {'-' 'tik_nuskaityti'})
            if handles.checkbox_islaikyti_katalogu_struktura_1pakat.Value
                spi=[0 find(ismember(santykinis_poaplankis,filesep)) length(santykinis_poaplankis)+1];
                sp1=santykinis_poaplankis( (spi(1)+1):spi(2)-1 );
                while ( isempty(sp1) || strcmp(sp1,'.') || strcmp(sp1,'..') ) && length(spi) > 2
                    spi=spi(2:end);
                    sp1=santykinis_poaplankis((spi(1)+1):spi(2)-1);
                end
                rezultatu_kelias=fullfile(rezultatu_katalogas,sp1); % tik vienas poaplankis
%                 if ~isempty(sp1)
%                     vardas_rezultatams=fullfile(sp1,vardas);
%                     vardas=sprintf('%s %s',sp1,vardas);
%                 end
            else
                rezultatu_kelias=fullfile(rezultatu_katalogas,santykinis_poaplankis);
            end
        else
            rezultatu_kelias=rezultatu_katalogas;
        end
        if ~exist(rezultatu_kelias,'dir')
            mkdir(rezultatu_kelias)
        end
        cd(rezultatu_kelias)
        
        %
        % P A G R I N D I N I S   D A R B A S   su viena rinkmena
        % -----------------------------------------------------
        [rz,vardas_rezultatams2,busena]=ritminukas(vardas, katalogas_su_rinkmena, parinktys);
        % -----------------------------------------------------
        %
        
        % Po darbo su viena rinkmena
        for rez_eilut=1:size(rz,1)
            fprintf(rezultatu_rinkmenos_id,'%s',   vardas);
            fprintf(rezultatu_rinkmenos_id,'\t%s', vardas_rezultatams);
            fprintf(rezultatu_rinkmenos_id,'\t%s', vardas_rezultatams2);
            fprintf(rezultatu_rinkmenos_id,'\t%s', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
            fprintf(rezultatu_rinkmenos_id,'\t%f', rz(rez_eilut,:));
            fprintf(rezultatu_rinkmenos_id,'\n');
        end
        
        if length(handles.rinkm.String) > 1 && length(rinkmenu_id_gui_sarase) > 1
            fi=rinkmenu_id_gui_sarase(ei);
            handles.rinkm.Value=setdiff(handles.rinkm.Value,fi);
            handles.rinkm.ListboxTop=fi;
            if ~busena && isfield(parinktys,'paieskos_algoritmas') && ismember(parinktys.paieskos_algoritmas,{'patternsearch' 'fmincon'})
                % pradiniai sutapo su išduotais, išimti iš kartojimo ciklo
                rinkmenu_id_gui_sarase=setdiff(rinkmenu_id_gui_sarase,fi);
            end
        end
        neapdorotos_duomenu_rinkmenos=setdiff(neapdorotos_duomenu_rinkmenos,rinkmena_gui_sarase);
        fprintf('\n');
        
    catch err
        % Pranesk_apie_klaida(err,mfilename,rinkmena_gui_sarase,0); % komandų lange
        Pranesk_apie_klaida(err,mfilename,rinkmena_gui_sarase,1); % GUI
        if ismember(err.identifier,{'MATLAB:nomem' 'MATLAB:save:permissionDenied' 'MATLAB:print:CannotCreateOutputFile'})
            handles.checkbox_baigti_anksciau.Value=1;
        end
        vaiduokliai=findobj('type','figure','Visible','off');
        try delete(vaiduokliai); catch; end
        %busena=-2;
    end
    drawnow;
    if handles.checkbox_baigti_anksciau.Value
        break
    end
  end
  
  % automatiškai keisti veiksenas
  if ispc && ~handles.checkbox_baigti_anksciau.Value && strcmpi(parinktys.veiksena,'optimizavimas_lygiagretus') && handles.paieskos_algoritmas.Value == 1
      dabartinis_alg=find(ismember(handles.paieskos_algoritmas.UserData,parinktys.paieskos_algoritmas));
      %           1 2 3 4 5 6 7 'auto' 'patternsearch' 'surrogateopt' 'particleswarm' 'ga' 'fmincon' 'MultiStart'
      %algoritmai=[4 6 7 5 3 8 2]; % bet 7 MultiStart neatrodo tinkamas...
      %algoritmai=[4 6 2 5 3 8 0]; % auto > particleswarm > ga > surrogateopt > patternsearch > fmincon % bet surrogateopt kažkodėl neveikia lygiagrečiai, nors greitokai susitvarko (nors teoriškai lėtas)
      %algoritmai=[4 6 0 5 2 8 0]; % auto > particleswarm > ga > patternsearch > fmincon % particleswarm nežymiai greitesnis nei ga ir kiek mažiau prasukimų daro
      %algoritmai=[5 6 0 2 4 8 0]; % auto > ga > particleswarm > patternsearch > fmincon % particleswarm nežymiai greitesnis nei ga ir kiek mažiau prasukimų daro
      %algoritmai=[5 8 0 2 4 0 0]; % auto > ga > particleswarm > patternsearch % fmincon atsisakyta, nes nepriima 0: kažkodėl keičia į 1. 
      algoritmai=[4 8 0 2 0 0 0]; % auto > particleswarm > patternsearch % ga atsisakyta, nes pernelyg laipsniškai juda pradinio pateikto varianto...
      kitas_alg=algoritmai(dabartinis_alg); %#ok
      if kitas_alg && kitas_alg<8
          parinktys.paieskos_algoritmas=handles.paieskos_algoritmas.UserData{kitas_alg};
          handles.rinkm.Value=rinkmenu_id_gui_sarase; % vėl žymėti rinkmenas kaip neapdorotas
          parinktys.ikelti_senus_kaip_pradinius=1;
      else
          sukti_cikla=0;
      end
  else
      sukti_cikla=0;
  end
  fprintf('\n- - - - - - - - - - - - - - - - - -\n\n')
end

% Po darbų
toc(t0); % kiek laiko užtruko
fprintf('   Atlikta:  %s\n===================================\n\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
try if ~isempty(rezultatu_rinkmenos_id)
        fclose(rezultatu_rinkmenos_id);
    end
    if isequal(neapdorotos_duomenu_rinkmenos,apdorotinos_duomenu_rinkmenos) || ~isempty(vienkartine_veiksena)
        delete(rezultatu_rinkmena);
    end
catch
end
if exist(fullfile(rezultatu_katalogas,'slprj'),'dir') == 7
    % Pašalinti Simulink podėlį
    try rmdir(fullfile(rezultatu_katalogas,'slprj'),'s') % tėviniame aplanke
    catch
    end
    if exist('rezultatu_kelias','var') && ~strcmp(rezultatu_kelias,rezultatu_katalogas) && ...
       exist(fullfile(rezultatu_kelias,'slprj'),'dir') == 7 % poaplankyje
        try rmdir(fullfile(rezultatu_kelias,'slprj'),'s')
        catch
        end
    end
end
cd(kelias_pradinis);
handles.checkbox_baigti_anksciau.Visible='off';
handles.checkbox_baigti_anksciau.Value=0;
gui_atnaujink_rodomas_rinkmenas([], [], handles.rinkm, handles.katal1_txt, handles.rinkm_fltr1, handles.rinkm_fltr2);
if length(handles.rinkm.String) > 1 && length(rinkmenu_id_gui_sarase) > 1
    handles.rinkm.Value=find(ismember(handles.rinkm.UserData,neapdorotos_duomenu_rinkmenos));
    if ~isempty(handles.rinkm.Value) && handles.rinkm.Value(1) > 1
        handles.rinkm.ListboxTop=handles.rinkm.Value(1)-1;
    end
elseif length(rinkmenu_id_gui_sarase)==1
    handles.rinkm.Value=find(ismember(handles.rinkm.UserData,apdorotinos_duomenu_rinkmenos));
end
try
    poolobj = gcp('nocreate');
    if ~isempty(poolobj)
        delete(poolobj); % stop parpool
    end
catch %err
    %w=warning('on');
    %Pranesk_apie_klaida(err,[],[],0);
    %warning(w);
end
gui_susildyk(fig); % vėl reaguoti į  mygtukus
gui_veiksenos_keitimas([],[],handles);
set(fig,'pointer','arrow'); drawnow;
if handles.checkbox_baigti_su_garsu.Value
    warning off MATLAB:audiovideo:audioplayer:noAudioOutputDevice
    try g=load('gong.mat'); sound(g.y);
    catch
    end
end
diary off;


function VolLbl=win_vol_lbl
% https://www.mathworks.com/matlabcentral/answers/143755-detecting-computer-id-from-matlab#answer_146792
[~, out] = dos('vol');
sc = strsplit(out,'\n');
VolLbl = sc{2}(end-8:end); % '0406-A308'

function txt=lokaliz(txt)
%txt=r_lokaliz(txt);

