function t=struct2txt(s,tab)
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

if nargin < 2
    tab='\t';
end
t='';
f=fields(s);
d=arrayfun(@(fl) length(fl{1}), f);
d_max=max(d);
for i=1:length(f)
    v1=[subsref(s,struct('type','.','subs',f{i}))];
    switch class(v1)
        case {'char'}
            v1=['''' v1 '''']; %#ok
        case {'single' 'double' 'logical'}
            if length(v1) < 2
                v1=regexprep(num2str(v1),'[ ]+', ' ');
            elseif length(v1) < 3
                v1=[ '[' regexprep(num2str(v1),'[ ]+', ' ') ']' ];
            else
                v1=[ '[' sprintf('%9g ',v1) ']' ];
            end
        case {'struct'}
            v1=[newline struct2txt(v1,[tab sprintf(['%' num2str(d_max) 's'], ' ') '\t'])];
        case {'cell'}
            try
                if iscellstr(v1) %#ok
                    v1=['{ ' sprintf('''%s'' ',v1{:}) '}'];
                elseif size(v1,2)>1 && iscellstr(v1(:,1)) && ~iscellstr(v1(:,2:end)) %#ok
                    v2=struct;
                    for ii=1:size(v1,1)
                        v2.(v1{ii,1})=[cell2mat(v1(ii,2:end-1)) v1{ii,end} ]; % atskirti paskutinį (end) narį nuo perdavimo į cell2mat kartu su kitais, nes jo tipas greičiausiai loginis, o ne skaitinis
                    end
                    v1=[newline struct2txt(v2,[tab sprintf(['%' num2str(d_max) 's'], ' ') '\t'])];
                elseif isstruct(v1{1}) || iscell(v1{1})
                    v2='{';
                    for ii=1:length(v1)
                        v2=[v2 '{' newline struct2txt(v1{ii},[tab sprintf(['%' num2str(d_max) 's'], ' ') '\t']) tab sprintf(['%' num2str(d_max) 's' ], ' ') '\t}' ]; %#ok
                    end
                    v1=[v2 '}'];
                else
                    v1=['{' num2str(cell2mat(v1)) '}'];
                end
            catch
                v1='<cell>';
            end
        otherwise
            v1=['<' class(v1) '>'];
    end
    t1=sprintf([tab '%' num2str(d_max) 's:\t%s\n'], f{i}, v1);
    t=[t t1]; %#ok
end

