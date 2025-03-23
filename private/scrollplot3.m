function  scrollHandles = scrollplot3(varargin)
% Priedas, išplečiantis scrollplot2 galimybes:
% - įgalina judėti klaviatūros rodyklių klavišais
% - įgalina judėti pelės ratuku
% - įgalina keisti mastelį laikant Vald(Ctrl) klavišą ir sukant ratuką 
%
% (C) 2019 Mindaugas Baranauskas
%
% Atnaujinta 2019-05-03, 2022-01-30
%

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

ax=[];
if ~isempty(varargin) && isobject(varargin{1})
    ax=ancestor(varargin{1},'axes','toplevel');
end
if isempty(ax)
    ax=gca;
end
figh=get(ax,'Parent');

scrollHandles = scrollplot2(varargin{:});

% supaprastinti dideles kreives slankikliuose
for shi=1:length(scrollHandles)
    sh=scrollHandles(shi);
    chs=get(sh,'Children');
    for chi=1:length(chs)
        ch=chs(chi);
        fls=fields(get(ch));
        if ismember('YData',fls) && ismember('XData',fls)
            YData=get(ch,'YData'); YData_N=length(YData);
            XData=get(ch,'XData'); XData_N=length(XData);
            if YData_N == XData_N && YData_N > 10000
                YData_N_1=10^(floor(log10(YData_N))-3);
                YData_N_2=floor(YData_N/YData_N_1);
                XData=reshape(XData(1:YData_N_1*YData_N_2),YData_N_1,YData_N_2); XData=[min(XData,[],1,'omitnan')' mean(XData,1,'omitnan')']'; set(ch,'XData', XData(:));
                YData=reshape(YData(1:YData_N_1*YData_N_2),YData_N_1,YData_N_2); YData=[min(YData,[],1,'omitnan')' max(YData,[],1,'omitnan')']'; set(ch,'YData', YData(:));
            end
        end
    end
end

set(figh, 'WindowKeyPressFcn',    {@reaguoti_i_klavisus,figh,ax,scrollHandles});
set(figh, 'WindowScrollWheelFcn', {@reaguoti_i_peles_ratuka, ax,scrollHandles});



function reaguoti_i_klavisus(~, ~, figh, ax, scrollHandles)

ck=get(figh,'CurrentKey');
%modifiers = get(gcf,'currentModifier');
try
    switch ck
        case {'uparrow' 'downarrow'}
            lim_dbr=get(ax,'YLim');
            lim_plt=(lim_dbr(2)-lim_dbr(1));
            lim_max=get(scrollHandles(end),'YLim');
            if lim_plt > diff(lim_max)
                lim_max=[lim_dbr(1)-lim_plt*0.2 lim_dbr(2)+lim_plt*0.2];
            end
        case {'leftarrow' 'rightarrow' 'pageup' 'pagedown' 'home' 'end' 'subtract' 'hyphen'  'add'}
            lim_dbr=get(ax,'XLim');
            lim_plt=(lim_dbr(2)-lim_dbr(1));
            lim_max=get(scrollHandles(1),'XLim');
            if lim_plt > diff(lim_max)
                lim_max=[lim_dbr(1)-lim_plt*0.2 lim_dbr(2)+lim_plt*0.2];
            end
    end
    
    switch ck
        %     case 'escape'
        %     case 'enter'
        %     case 'space'
        %     case 'delete'
        %     case 'backspace'
        case 'uparrow'
            %disp('^');
            lim_nj=min(lim_dbr(2) + lim_plt * 0.2, lim_max(2) + lim_plt * 0.2);
            lim_nj=[lim_nj - lim_plt lim_nj];
        case 'downarrow'
            %disp('v');
            lim_nj=max(lim_dbr(1) - lim_plt * 0.2, lim_max(1) - lim_plt * 0.2);
            lim_nj=[lim_nj lim_plt + lim_nj];
        case 'leftarrow'
            %disp('<');
            lim_nj=max(lim_dbr(1) - lim_plt * 0.2, lim_max(1) - lim_plt * 0.2);
            lim_nj=[lim_nj lim_plt + lim_nj];
        case 'rightarrow'
            %disp('>');
            lim_nj=min(lim_dbr(2) + lim_plt * 0.2, lim_max(2) + lim_plt * 0.2);
            lim_nj=[lim_nj - lim_plt lim_nj];
        case 'pageup'
            %disp('<');
            lim_nj=max(lim_dbr(1) - lim_plt * 1.0, lim_max(1) - lim_plt * 0.2);
            lim_nj=[lim_nj lim_plt + lim_nj];
        case 'pagedown'
            %disp('>');
            lim_nj=min(lim_dbr(2) + lim_plt * 1.0, lim_max(2) + lim_plt * 0.2);
            lim_nj=[lim_nj - lim_plt lim_nj];
        case 'home'
            lim_nj=lim_max(1) - lim_plt * 0.2;
            lim_nj=[lim_nj lim_plt + lim_nj];
        case 'end'
            lim_nj=lim_max(2) + lim_plt * 0.2;
            lim_nj=[lim_nj - lim_plt lim_nj];
        case {'subtract','hyphen'}
            lim_nj1=max(lim_dbr(1) - lim_plt * 0.125, lim_max(1) - lim_plt * 0.2);
            lim_nj2=min(lim_dbr(2) + lim_plt * 0.125, lim_max(2) + lim_plt * 0.2);
            lim_nj=[lim_nj1 lim_nj2];
        case 'add'
            lim_nj1=lim_dbr(1) + lim_plt * 0.1;
            lim_nj2=lim_dbr(2) - lim_plt * 0.1;
            lim_nj=[lim_nj1 lim_nj2];
        otherwise
            %disp(ck);
    end
    
    
    switch ck
        case {'uparrow' 'downarrow'}
            set(ax,'YLim',lim_nj);
        case {'leftarrow' 'rightarrow' 'pageup' 'pagedown' 'home' 'end' 'subtract' 'hyphen'  'add'}
            set(ax,'XLim',lim_nj);
    end
    
    
catch %err;
        %Pranesk_apie_klaida(err,mfilename,'',0);
end;


function reaguoti_i_peles_ratuka(~, eventdata, ax, scrollHandles)
modifiers = get(gcf,'currentModifier');
act=hittest;
if ~isempty(findall(act,'-property','Tag'));
    if ismember(get(hittest,'Tag'),{'scrollAx' 'scrollPatch' 'scrollBar'});
        if strcmp(get(hittest,'UserData'),'y')
            asisR='y'; asisN=length(scrollHandles);
        else
            asisR='x'; asisN=1;
        end;
    elseif ismember('alt',modifiers);
        asisR='y'; asisN=length(scrollHandles);
    else
        asisR='x'; asisN=1;
    end;
elseif ismember('alt',modifiers);
    asisR='y'; asisN=length(scrollHandles);
else
    asisR='x'; asisN=1;
end;
try
    lim_dbr=get(ax, [asisR 'lim']);
    lim_max=get(scrollHandles(asisN),[asisR 'lim']);
    lim_plt=(lim_dbr(2)-lim_dbr(1));
    if ismember('control',modifiers) || ismember('alt',modifiers);
        % Laikant Vald(Ctrl) klavisa ir sukant ratuka - keisti X asies masteli
        % Laikant Alt        klavisa ir sukant ratuka - keisti Y asies masteli
        if eventdata.VerticalScrollCount > 0;
            lim_nj1=lim_dbr(1) + lim_plt * 0.1;
            lim_nj2=lim_dbr(2) - lim_plt * 0.1;
            lim_nj=[lim_nj1 lim_nj2];
        else
            lim_nj1=max(lim_dbr(1) - lim_plt * 0.125, lim_max(1) - lim_plt * 0.2);
            lim_nj2=min(lim_dbr(2) + lim_plt * 0.125, lim_max(2) + lim_plt * 0.2);
            lim_nj=[lim_nj1 lim_nj2];
        end;
    else
        % Slinkti
        if eventdata.VerticalScrollCount * (1.5-asisN) > 0 % inversija Y ašiai
            lim_nj=min(lim_dbr(2) + lim_plt * 0.2, lim_max(2) + lim_plt * 0.2);
            lim_nj=[lim_nj - lim_plt lim_nj];
        else
            lim_nj=max(lim_dbr(1) - lim_plt * 0.2, lim_max(1) - lim_plt * 0.2);
            lim_nj=[lim_nj lim_plt + lim_nj];
        end;
    end;
    set(ax,[asisR 'lim'],lim_nj);
catch %err;
    %Pranesk_apie_klaida(err,mfilename,'',0);
end;

