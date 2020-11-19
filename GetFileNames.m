function FoundFileNames=GetFileNames(SearchDir,FileType)

% Check inputs
FoundFileNames = string([]);
if(isempty(SearchDir)||isempty(FileType))
    return;
end;

% Convert to strings
SearchDir = string(SearchDir);
FileType = string(FileType);

% Replace the back slash direction
SearchDir = SearchDir.replace('\','/');
    
% Find files
FileNames=dir(SearchDir.char);
for n=1:size(FileNames,1)    
    FullFileName = SearchDir + string('/') + string(FileNames(n).name);    
    if(FileNames(n).isdir)
        if(~strcmp(FileNames(n).name,'.') && ~strcmp(FileNames(n).name,'..'))
            NextLevelFileNames = GetFileNames(FullFileName,FileType);
            if(~isempty(NextLevelFileNames))        
                FoundFileNames = [FoundFileNames ; NextLevelFileNames];
            end;
        end;
    elseif((numel(FileNames(n).name) > numel(FileType.char)) && strcmp(FileNames(n).name((end-numel(FileType.char)+1):end),FileType.char))    
        FoundFileNames(end+1,1) = FullFileName;
    end;
end;
