close all;
clear all;

% G - Green, P - Red, N - Purple

% Set input directory
InputDir = 'D:\Temp\Maya\CoStain\Images\WT GFP injected';

% Set input file type
InputFileType = 'tif';

% Set show figure
ShowFigure = false;

% Get file list
InputFileList = GetFileNames(InputDir,InputFileType);

% Initialize results struct template
ResultTemplate = struct('Directory',string([]),...
                        'GreenFileName',string([]),...
                        'RedFileName',string([]),...
                        'PurpleFileName',string([]),...
                        'CountGreen',[],...
                        'CountRed',[],...
                        'CountPurple',[],...
                        'CountRedAndGreen',[],...
                        'CountPurpleAndGreen',[],...
                        'CountRedAndPurple',[],...
                        'CountGreenAndRedAndPurple',[],...
                        'AreaPurple',[]);
                    
% Loop over all files
NumberOfResults = 0;
WaitBarHandle = waitbar(0,'Please wait...');
for m=1:numel(InputFileList)
    
    % Get file name
    FullFileName = InputFileList(m);
    
%     if(~FullFileName.contains('D:/Temp/Maya/CoStain/Images/2nd injection(10.16.19)/PR/KO/Cortex'))
%         continue;
%     end;
    
    % Get directory and file name
    FileName = FullFileName.split('/');
    if(numel(FileName) > 1)
        Directory = FileName(1:(end-1)).join('/');
        FileName = FileName(end);
    else
        Directory = string();
    end;
    
    % Check if this is red
    if(~FileName.contains(string('P.') + InputFileType))
        continue;
    end;
    
    % Set file names
    RedFileName = Directory + string('/') + FileName;
    GreenFileName = Directory + string('/') + FileName.extractBefore(string('P.') + string(InputFileType)) + string('G.') + string(InputFileType);
    PurpleFileName = Directory + string('/') + FileName.extractBefore(string('P.') + string(InputFileType)) + string('N.') + string(InputFileType);
    
    % Check if all exist
    if(~exist(RedFileName.char,'file') || ~exist(GreenFileName.char,'file') || ~exist(PurpleFileName.char,'file'))
        continue;
    end;
    
    % Update results array
    NumberOfResults = NumberOfResults + 1;
    if(NumberOfResults == 1)
        Results = ResultTemplate;
    else
        Results(end+1) = ResultTemplate;        
    end;    
    Results(end).Directory = Directory;
    Results(end).RedFileName = RedFileName.extractAfter(Directory + string('/'));
    Results(end).GreenFileName = GreenFileName.extractAfter(Directory + string('/'));
    Results(end).PurpleFileName = PurpleFileName.extractAfter(Directory + string('/'));
    
    % Read images
    GreenImage = single(imread(GreenFileName.char));
    RedImage = single(imread(RedFileName.char));
    PurpleImage = single(imread(PurpleFileName.char));
    
    % Process green image
    GreenImageBinary = ProcessGreenImage(GreenImage, ShowFigure);    
    
    % Process red image
    RedImageBinary = ProcessRedImage(RedImage, ShowFigure);
    
    % Process purple image
    PurpleImageBinary = ProcessPurpleImage(PurpleImage, ShowFigure);
    
    % Count using connected componenets
    GreenCC = bwconncomp(GreenImageBinary);
    RedCC = bwconncomp(RedImageBinary);
    PurpleCC = bwconncomp(PurpleImageBinary);
    RedAndGreenCC = bwconncomp(GreenImageBinary&RedImageBinary);
    PurpleAndGreenCC = bwconncomp(GreenImageBinary&PurpleImageBinary);  
    RedAndPurpleCC = bwconncomp(RedImageBinary&PurpleImageBinary);
    GreenAndRedAndPurpleCC = bwconncomp(GreenImageBinary&RedImageBinary&PurpleImageBinary);    
    CountGreen = GreenCC.NumObjects;
    CountRed = RedCC.NumObjects;
    CountPurple = PurpleCC.NumObjects;
    CountRedAndGreen = RedAndGreenCC.NumObjects;    
    CountPurpleAndGreen = PurpleAndGreenCC.NumObjects;
    CountRedAndPurple = RedAndPurpleCC.NumObjects;
    CountGreenAndRedAndPurple = GreenAndRedAndPurpleCC.NumObjects;
    
    % Area
    PurpleProps = regionprops(PurpleCC,'Area');
    AreaPurple = 0;
    for n=1:numel(PurpleProps)
        AreaPurple = AreaPurple + PurpleProps(n).Area;
    end;    
    
    % Update results
    Results(end).CountGreen = CountGreen;
    Results(end).CountRed = CountRed;
    Results(end).CountPurple = CountPurple;
    Results(end).CountRedAndGreen = CountRedAndGreen;
    Results(end).CountPurpleAndGreen = CountPurpleAndGreen;
    Results(end).CountRedAndPurple = CountRedAndPurple;
    Results(end).CountGreenAndRedAndPurple = CountGreenAndRedAndPurple;
    Results(end).AreaPurple = AreaPurple;
        
    % Set output file names
    RedOutputFileName = RedFileName.replace('.tif','.pgm');
    GreenOutputFileName = GreenFileName.replace('.tif','.pgm');
    PurpleOutputFileName = PurpleFileName.replace('.tif','.pgm');
    
    % Save output images
    SaveBinaryImage(RedImageBinary, RedOutputFileName);
    SaveBinaryImage(GreenImageBinary, GreenOutputFileName);
    SaveBinaryImage(PurpleImageBinary, PurpleOutputFileName);

    if(ShowFigure)
        close all;
    end;
    
    % Update progress bar
    waitbar(m/numel(InputFileList),WaitBarHandle);
end;
close(WaitBarHandle);

% Save results to csv file
fid = fopen([InputDir '/MayaResults.csv'],'wt');
for m=1:numel(Results)
    if(m == 1)
        fprintf(fid,'Directory,GreenFileName,RedFileName,PurpleFileName,CountGreen,CountRed,CountPurple,CountRedAndGreen,CountPurpleAndGreen,CountRedAndPurple,CountGreenAndRedAndPurple,AreaPurple\n');
    end;
    fprintf(fid,'%s,%s,%s,%s,%u,%u,%u,%u,%u,%u,%u,%u\n',Results(m).Directory.char,...
                                                     Results(m).GreenFileName.char,...
                                                     Results(m).RedFileName.char,...
                                                     Results(m).PurpleFileName.char,...
                                                     Results(m).CountGreen,...
                                                     Results(m).CountRed,...
                                                     Results(m).CountPurple,...
                                                     Results(m).CountRedAndGreen,...
                                                     Results(m).CountPurpleAndGreen,...
                                                     Results(m).CountRedAndPurple,...
                                                     Results(m).CountGreenAndRedAndPurple,...
                                                     Results(m).AreaPurple);
end;
fclose(fid);

function Status = SaveBinaryImage(BinaryImage, FileName)

    % Initialize status
    Status = false;
    
    % Save output image
    imwrite(BinaryImage,FileName.char,'pgm');
    
    % Set status
    Status = true;
end


function Status = ProcessGreenImage(GreenImage, ShowFigure)

    % Initialize show figure
    if(nargin < 2)
        ShowFigure = false;
    end;
    
    % Calculate statistics
    MED = median(GreenImage(:));
    MAD = median(abs(GreenImage(:)-MED));
    
    % Apply threshold
    GreenImageBinary = zeros(size(GreenImage),'uint8');
    GreenImageBinary(GreenImage>(MED+4*1.45*MAD))=255;
    
    % Apply morphological operations
    SE = strel('disk',1,0);
    for m=1:3
        GreenImageBinary = imdilate(GreenImageBinary,SE,'same');
    end;
    for m=1:6
        GreenImageBinary = imerode(GreenImageBinary,SE,'same');
    end;
    for m=1:3
        GreenImageBinary = imdilate(GreenImageBinary,SE,'same');
    end;
    
    % Display images
    if(ShowFigure)
        figure;
        H(1)=subplot(1,2,1);
        image(uint8(GreenImage/256));
        colormap(gray(256));
        axis image;
        H(2)=subplot(1,2,2);    
        image(GreenImageBinary);
        colormap(gray(256));
        axis image;
        linkaxes(H,'xy');
    end;

%     figure;
%     image(uint8(GreenImage/256));
%     colormap(gray(256));
%     axis image;
% 
%     figure;
%     image(GreenImageBinary);
%     colormap(gray(256));
%     axis image;
    
    % Calculate histogram
%     Hist=zeros(1,256,'uint32');
%     I = find(GreenImageBinary > 0);
%     for m=1:numel(I)
%         GL = uint8(GreenImage(I(m))/256);
%         Hist(GL) = Hist(GL) + 1;
%     end;
%     
%     figure
%     plot(0:255,Hist);
    
    

    Status = GreenImageBinary;
end

function Status = ProcessRedImage(RedImage, ShowFigure)

    % Initialize show figure
    if(nargin < 2)
        ShowFigure = false;
    end;

    % Calculate statistics    
    MED = median(RedImage(:));
    MAD = median(abs(RedImage(:)-MED));
    
    % Apply threshold
    Sensitivity = 4;
    RedImageBinary = zeros(size(RedImage),'uint8');
    RedImageBinary(RedImage>(MED+Sensitivity*1.45*MAD)) = 255;
    
    % Apply morphological operations
    SE = strel('disk',1,0);
    for m=1:3
        RedImageBinary = imdilate(RedImageBinary,SE,'same');
    end;
    for m=1:6
        RedImageBinary = imerode(RedImageBinary,SE,'same');
    end;
    for m=1:3
        RedImageBinary = imdilate(RedImageBinary,SE,'same');
    end;
    
    % Perform connected components
    CC = bwconncomp(RedImageBinary);
    StatsCC = regionprops(CC,'BoundingBox','Area','Extent');
    
    % Retain only biger 
    MinSize = 20;
    for m=1:numel(StatsCC) 
        BoundingBox = StatsCC(m).BoundingBox;
        if((BoundingBox(3) < MinSize) || (BoundingBox(4) < MinSize))
            RedImageBinary(BoundingBox(2)-0.5+(1:BoundingBox(4)),BoundingBox(1)-0.5+(1:BoundingBox(3))) = 0;            
        end;
    end;
    
    % Display images
    if(ShowFigure)
        figure;
        H(1)=subplot(1,2,1);
        image(uint8(RedImage/256));
        colormap(gray(256));
        axis image;
        H(2)=subplot(1,2,2);    
        image(RedImageBinary);
        colormap(gray(256));
        axis image;
        linkaxes(H,'xy');
    end;

%     figure;
%     image(uint8(GreenImage/256));
%     colormap(gray(256));
%     axis image;
% 
%     figure;
%     image(GreenImageBinary);
%     colormap(gray(256));
%     axis image;
    
    % Calculate histogram
%     Hist=zeros(1,256,'uint32');
%     I = find(RedImageBinary > 0);
%     for m=1:numel(I)
%         GL = uint8(RedImage(I(m))/256);
%         Hist(GL) = Hist(GL) + 1;
%     end;
%     
%     figure
%     plot(0:255,Hist);
    
    

    Status = RedImageBinary;
end

function Status = ProcessPurpleImage(PurpleImage, ShowFigure)

    % Initialize show figure
    if(nargin < 2)
        ShowFigure = false;
    end;
    
    % Calculate OTSU threshold
    otsu = graythresh(uint8(PurpleImage/256));
    
    % Apply threshold
    PurpleImageBinary = zeros(size(PurpleImage),'uint8');
    PurpleImageBinary(uint8(PurpleImage/256) > otsu*255) = 255;
    
    % Check statistics of background
    Sensitivity = 4;
    Background = PurpleImage(PurpleImageBinary == 0)/256;
    MED = median(Background);
    MAD = median(abs(Background-MED));
    if((otsu*255) < (MED+Sensitivity*1.45*MAD))
        UpdateThreshold = MED+Sensitivity*1.45*MAD;
        PurpleImageBinary = zeros(size(PurpleImage),'uint8');
        PurpleImageBinary(uint8(PurpleImage/256) > UpdateThreshold) = 255;
    end;  
        
    % Apply morphological operations
    SE = strel('disk',1,0);
    for m=1:3
        PurpleImageBinary = imdilate(PurpleImageBinary,SE,'same');
        %PurpleImageBinary = imclose(PurpleImageBinary,SE);
    end;
    for m=1:3
        PurpleImageBinary = imerode(PurpleImageBinary,SE,'same');
        %PurpleImageBinary = imopen(PurpleImageBinary,SE);
    end;
    
    % Perform connected components
    CC = bwconncomp(PurpleImageBinary);
    StatsCC = regionprops(CC,'BoundingBox','Area','Extent');
    
    % Retain only biger 
    MinSize = 10;
    MinExtent = 0;
    for m=1:numel(StatsCC) 
        BoundingBox = StatsCC(m).BoundingBox;
        Extent = StatsCC(m).Extent;
        if((BoundingBox(3) < MinSize) || (BoundingBox(4) < MinSize) || (Extent < MinExtent))
            PurpleImageBinary(BoundingBox(2)-0.5+(1:BoundingBox(4)),BoundingBox(1)-0.5+(1:BoundingBox(3))) = 0;            
        end;
    end;
    
    % Display images
    if(ShowFigure)
        figure;
        H(1)=subplot(1,2,1);
        image(uint8(PurpleImage/256));
        colormap(gray(256));
        axis image;
        H(2)=subplot(1,2,2);    
        image(PurpleImageBinary);
        colormap(gray(256));
        axis image;
        linkaxes(H,'xy');
    end;    

    Status = PurpleImageBinary;
end


