function varargout = Mammography(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Mammography_OpeningFcn, ...
                   'gui_OutputFcn',  @Mammography_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end




function Mammography_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;
    guidata(hObject, handles);

function varargout = Mammography_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

function viewXRay_Callback(hObject, eventdata, handles)

    set(Mammography, 'HandleVisibility', 'off');
    close all;
    set(Mammography, 'HandleVisibility', 'on');

    im_size = 1000;
    Io = str2num(get(handles.intensityText,'String')); %since I / Io is just a ratio going to just set Io to 1 for our calculations

    attenuationBreastTissue = .07031; %from website http://physics.nist.gov/PhysRefData/XrayMassCoef/ComTab/breast.html u/p=7.031E-02
    densityBreast = .0102; %g/cm^2 from website http://physics.nist.gov/PhysRefData/XrayMassCoef/tab2.html

    attenuationCancerTissue = attenuationBreastTissue*2; %using a ratio, so its 2x lighter than breast tissue
    densityCancerTissue = densityBreast*2;

    breastSize = str2num(get(handles.breastSizeText,'String'));
    cancerSize1 = str2num(get(handles.cancerSizeText1,'String'));
    cancerSize2 = str2num(get(handles.cancerSizeText2,'String'));
    cancerSize3 = str2num(get(handles.cancerSizeText3,'String'));
    cancerSize4 = str2num(get(handles.cancerSizeText4,'String'));

    breastStart = (im_size-breastSize) / 2;
    breastEnd = breastStart + breastSize;

    cancerValues = zeros(3, 7); %each column is a cancer attenuation, density, x start, x end, y start, y end, size for one cancer
    %cancer 1 is 2x ratio to breast tissue
    cancerValues(1,1) = 2*attenuationBreastTissue;
    cancerValues(1,2) = 2*densityBreast;
    cancerValues(1,3) = breastStart + (randi(breastSize-cancerSize1));
    cancerValues(1,4) = cancerValues(1,3) + cancerSize1;
    cancerValues(1,5) = breastStart + (randi(breastSize-cancerSize1));
    cancerValues(1,6) = cancerValues(1,5) + cancerSize1;
    cancerValues(1,7) = cancerSize1;

    %cancer 2 is 5x ratio to breast tissue
    cancerValues(2,1) = 5*attenuationBreastTissue;
    cancerValues(2,2) = 5*densityBreast;
    cancerValues(2,3) = breastStart + (randi(breastSize-cancerSize2));
    cancerValues(2,4) = cancerValues(2,3) + cancerSize2;
    cancerValues(2,5) = breastStart + (randi(breastSize-cancerSize2));
    cancerValues(2,6) = cancerValues(2,5) + cancerSize2;
    cancerValues(2,7) = cancerSize2;
    %cancer 3 is 10x ratio to breastTissue
    cancerValues(3,1) = 10*attenuationBreastTissue;
    cancerValues(3,2) = 10*densityBreast;
    cancerValues(3,3) = breastStart + (randi(breastSize-cancerSize3));
    cancerValues(3,4) = cancerValues(3,3) + cancerSize3;
    cancerValues(3,5) = breastStart + (randi(breastSize-cancerSize3));
    cancerValues(3,6) = cancerValues(3,5) + cancerSize3;
    cancerValues(3,7) = cancerSize3;
    %cancer 4 is 30x ratio to breastTissue
    cancerValues(4,1) = 30*attenuationBreastTissue;
    cancerValues(4,2) = 30*densityBreast;
    cancerValues(4,3) = breastStart + (randi(breastSize-cancerSize4));
    cancerValues(4,4) = cancerValues(4,3) + cancerSize4;
    cancerValues(4,5) = breastStart + (randi(breastSize-cancerSize4));
    cancerValues(4,6) = cancerValues(4,5) + cancerSize4;
    cancerValues(4,7) = cancerSize4;

    imageArrayPhantom = zeros(im_size, im_size); %create phantom with all 0 attenuation (air space)
    densityArrayPhantom = zeros(im_size, im_size); %air has 0 density right?!

    for i=breastStart:breastEnd
        for j=breastStart:breastEnd
            imageArrayPhantom(i, j) = attenuationBreastTissue;
            densityArrayPhantom(i,j) = densityBreast;
        end
    end

    for k=1:4
        if (cancerValues(k,7) ~=0) %if the cancer size is not 0, create it
            for i=cancerValues(k,3):cancerValues(k,4)
                for j=cancerValues(k,5):cancerValues(k,6)
                    imageArrayPhantom(i,j) = cancerValues(k,1);
                    densityArrayPhantom(i,j) = cancerValues(k,2);
                end
            end
        end
    end


    figure;
    imshow(imageArrayPhantom);
    
    intensityArray = ones(im_size, 1);

    for col = 1 : im_size %this is the slices going top down
       length = 1;
       currentAttenuation = imageArrayPhantom(1, col); %get attenuation of first row of verticle slice
       currentDensity = densityArrayPhantom(1,col);
       for row = 1 : im_size
           if (currentAttenuation == imageArrayPhantom(row, col))
               length = length + 1; %row has same attenuation coef so add 1 to length
           else
               intensityArray(col) = intensityArray(col) * (Io * exp((-currentAttenuation)*currentDensity*length)); %equation u/p length
               %set values for next L measurements
               length = 1;
               currentAttenuation = imageArrayPhantom(row,col); %set new attenuation level to measure length of
               currentDensity = densityArrayPhantom(row,col);
           end
       end
    end
    %display the graph of intensities
    figure
    plot(intensityArray);


function slider1_Callback(hObject, eventdata, handles)

function slider1_CreateFcn(hObject, eventdata, handles)
    if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor',[.9 .9 .9]);
    end

function slider1_KeyPressFcn(hObject, eventdata, handles)

function breastSizeText_Callback(hObject, eventdata, handles)

function breastSizeText_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end



function cancerSizeText1_Callback(hObject, eventdata, handles)

function cancerSizeText1_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end



function cancerSizeText2_Callback(hObject, eventdata, handles)

function cancerSizeText2_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end



function cancerSizeText3_Callback(hObject, eventdata, handles)

function cancerSizeText3_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
function cancerSizeText4_Callback(hObject, eventdata, handles)

function cancerSizeText4_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function intensityText_Callback(hObject, eventdata, handles)

function intensityText_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end



function edit6_Callback(hObject, eventdata, handles)

function edit6_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function text9_CreateFcn(hObject, eventdata, handles)
