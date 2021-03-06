function varargout = trackBall(varargin)
% TRACKBALL MATLAB code for trackBall.fig
%      TRACKBALL, by itself, creates a new TRACKBALL or raises the existing
%      singleton*.
%
%      H = TRACKBALL returns the handle to a new TRACKBALL or the handle to
%      the existing singleton*.
%
%      TRACKBALL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACKBALL.M with the given input arguments.
%
%      TRACKBALL('Property','Value',...) creates a new TRACKBALL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trackBall_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trackBall_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trackBall

% Last Modified by GUIDE v2.5 04-Jan-2021 00:38:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trackBall_OpeningFcn, ...
                   'gui_OutputFcn',  @trackBall_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before trackBall is made visible.
function trackBall_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to trackBall (see VARARGIN)


set(hObject,'WindowButtonDownFcn',{@my_MouseClickFcn,handles.axes1});
set(hObject,'WindowButtonUpFcn',{@my_MouseReleaseFcn,handles.axes1});
axes(handles.axes1);

handles.Cube=DrawCube();

handles.q0 = [1;0;0;0];
set(handles.axes1,'CameraPosition',...
    [0 0 5],'CameraTarget',...
    [0 0 -5],'CameraUpVector',...
    [0 1 0],'DataAspectRatio',...
    [1 1 1]);

set(handles.axes1,'xlim',[-3 3],'ylim',[-3 3],'visible','off','color','none');

% Choose default command line output for trackBall
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes trackBall wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = trackBall_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function my_MouseClickFcn(obj,event,hObject)

handles=guidata(obj);
xlim = get(handles.axes1,'xlim');
ylim = get(handles.axes1,'ylim');
mousepos=get(handles.axes1,'CurrentPoint');
xmouse = mousepos(1,1);
ymouse = mousepos(1,2);

if xmouse > xlim(1) && xmouse < xlim(2) && ymouse > ylim(1) && ymouse < ylim(2)
    handles.m0 = Map2DPointsTo3D(xmouse, ymouse);
    set(handles.figure1,'WindowButtonMotionFcn',{@my_MouseMoveFcn,hObject});
end
guidata(hObject,handles)

function my_MouseReleaseFcn(obj,event,hObject)
handles=guidata(hObject);
set(handles.figure1,'WindowButtonMotionFcn','');
guidata(hObject,handles);

function my_MouseMoveFcn(obj,event,hObject)

handles=guidata(obj);
xlim = get(handles.axes1,'xlim');
ylim = get(handles.axes1,'ylim');
mousepos=get(handles.axes1,'CurrentPoint');
xmouse = mousepos(1,1);
ymouse = mousepos(1,2);

if xmouse > xlim(1) && xmouse < xlim(2) && ymouse > ylim(1) && ymouse < ylim(2)
    
    % Calculate m1
    m1 = Map2DPointsTo3D(xmouse,ymouse);
    % Get past info
    m0 = handles.m0;
    q0 = handles.q0;
    % Calculate delta quaternoin
    dq = QuaternionFromTwoVectors(m0,m1);
    dq = dq/norm(dq);
    % Calculate actual quaternion
    qk = MultQuaternion(dq,q0);
    % Transform and publish differents attitudes
    UpdateAttitudes(qk, handles);
    % Redraw Cube
    handles.Cube = RedrawCube(qk,handles.Cube);
    % Save actual data
    handles.m0 = m1;
    handles.q0 = qk;
    
end
guidata(hObject,handles);

function h = DrawCube()

M = [-2 -2  2;  %Node 1 suelo caraIzquierda caraDelantera
      0  2  0;  %Node 2 caraIzquierda caraDelantera
      0  2  0;  %Node 3 caraDerecha caraDelantera
      2 -2  2;  %Node 4 suelo caraDerecha caraDelantera
     -2 -2 -2;  %Node 5 suelo caraIzquierda caraTrasera
      0  2  0;  %Node 6 caraIzquierda caraTrasera
      0  2  0;  %Node 7 caraDerecha caraTrasera
      2 -2 -2]; %Node 8 suelo caraDerecha caraTrasera

x = M(:,1);
y = M(:,2);
z = M(:,3);


con = [1 2 3 4;
       5 6 7 8;
       4 3 7 8;
       1 2 6 5;
       1 4 8 5;
       2 3 7 6]';

x = reshape(x(con(:)),[4,6]);
y = reshape(y(con(:)),[4,6]);
z = reshape(z(con(:)),[4,6]);

c = 1/255*[255 178 0;
    255 255 255;
    57 183 225;
    57 183 0;
    255 248 88;
    255 0 0];

h = fill3(x,y,z, 1:6);

for q = 1:length(c)
    h(q).FaceColor = c(q,:);
end

function h = RedrawCube(q,hin)

h = hin;
c = 1/255*[255 178 0;
    255 255 255;
    57 183 225;
    57 183 0;
    255 248 88;
    255 0 0];

M = [-2 -2  2;  %Node 1 suelo caraIzquierda caraDelantera
      0  2  0;  %Node 2 caraIzquierda caraDelantera
      0  2  0;  %Node 3 caraDerecha caraDelantera
      2 -2  2;  %Node 4 suelo caraDerecha caraDelantera
     -2 -2 -2;  %Node 5 suelo caraIzquierda caraTrasera
      0  2  0;  %Node 6 caraIzquierda caraTrasera
      0  2  0;  %Node 7 caraDerecha caraTrasera
      2 -2 -2]; %Node 8 suelo caraDerecha caraTrasera

%% TODO rotate M by using q
% Calculate rotation matrix
R = RotationMatrix(q);
% Rotate Cube
M=(R*M')';

x = M(:,1);
y = M(:,2);
z = M(:,3);


con = [1 2 3 4;
       5 6 7 8;
       4 3 7 8;
       1 2 6 5;
       1 4 8 5;
       2 3 7 6]';

x = reshape(x(con(:)),[4,6]);
y = reshape(y(con(:)),[4,6]);
z = reshape(z(con(:)),[4,6]);

for q = 1:6
    h(q).Vertices = [x(:,q) y(:,q) z(:,q)];
    h(q).FaceColor = c(q,:);
end

function euler_x_Callback(hObject, eventdata, handles)
% hObject    handle to euler_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_x as text
%        str2double(get(hObject,'String')) returns contents of euler_x as a double


% --- Executes during object creation, after setting all properties.
function euler_x_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_y_Callback(hObject, eventdata, handles)
% hObject    handle to euler_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_y as text
%        str2double(get(hObject,'String')) returns contents of euler_y as a double


% --- Executes during object creation, after setting all properties.
function euler_y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_z_Callback(hObject, eventdata, handles)
% hObject    handle to euler_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_z as text
%        str2double(get(hObject,'String')) returns contents of euler_z as a double


% --- Executes during object creation, after setting all properties.
function euler_z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function euler_angle_Callback(hObject, eventdata, handles)
% hObject    handle to euler_angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of euler_angle as text
%        str2double(get(hObject,'String')) returns contents of euler_angle as a double


% --- Executes during object creation, after setting all properties.
function euler_angle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to euler_angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function q0_0_Callback(hObject, eventdata, handles)
% hObject    handle to q0_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q0_0 as text
%        str2double(get(hObject,'String')) returns contents of q0_0 as a double


% --- Executes during object creation, after setting all properties.
function q0_0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q0_0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function q1_Callback(hObject, eventdata, handles)
% hObject    handle to q1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q1 as text
%        str2double(get(hObject,'String')) returns contents of q1 as a double


% --- Executes during object creation, after setting all properties.
function q1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function q2_Callback(hObject, eventdata, handles)
% hObject    handle to q2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q2 as text
%        str2double(get(hObject,'String')) returns contents of q2 as a double


% --- Executes during object creation, after setting all properties.
function q2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function q3_Callback(hObject, eventdata, handles)
% hObject    handle to q3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of q3 as text
%        str2double(get(hObject,'String')) returns contents of q3 as a double


% --- Executes during object creation, after setting all properties.
function q3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to q3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in UpdateQuaternion.
function UpdateQuaternion_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateQuaternion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

q(1) = str2double(get(handles.q0_0, 'String'));
q(2) = str2double(get(handles.q1, 'String'));
q(3) = str2double(get(handles.q2, 'String'));
q(4) = str2double(get(handles.q3, 'String'));

q=q';
q=q/norm(q);
handles.q0=q;

% Transform and publish differents attitudes
UpdateAttitudes(q, handles);
% Redraw Cube
handles.Cube = RedrawCube(q,handles.Cube);

% --- Executes on button press in UpdateAngleAxis.
function UpdateAngleAxis_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateAngleAxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

u(1) = str2double(get(handles.euler_x, 'String'));
u(2) = str2double(get(handles.euler_y, 'String'));
u(3) = str2double(get(handles.euler_z, 'String'));
angle = str2double(get(handles.euler_angle, 'String'));
u = u/norm(u);
u=u';

R = Eaa2rotMat(angle,u);
q = RotationMatrix2Quaternion(R);
q = q/norm(q);
q=q';
handles.q0=q;
% Transform and publish differents attitudes
UpdateAttitudes(q, handles);
% Redraw Cube
handles.Cube = RedrawCube(q,handles.Cube);

% --- Executes on button press in UpdateEulerAngles.
function UpdateEulerAngles_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateEulerAngles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

roll = str2double(get(handles.roll, 'String'));
pitch = str2double(get(handles.pitch, 'String'));
yaw = str2double(get(handles.yaw, 'String'));

R = eAngles2rotM(roll,pitch,yaw);
q = RotationMatrix2Quaternion(R);
q = q/norm(q);
q=q';
handles.q0=q;
% Transform and publish differents attitudes
UpdateAttitudes(q, handles);
% Redraw Cube
handles.Cube = RedrawCube(q,handles.Cube);

% --- Executes on button press in UpdateRotationVector.
function UpdateRotationVector_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateRotationVector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Rotation Vector
vr(1) = str2double(get(handles.v1, 'String'));
vr(2) = str2double(get(handles.v2, 'String'));
vr(3) = str2double(get(handles.v3, 'String'));
vr = vr';

%Euler angle axis
a = norm(vr);

if norm(vr) == 0
    u = [1;0;0];
else
    u = vr/norm(vr);
end

q = [cosd(a/2); sind(a/2) * u]; 
q=q/norm(q);
handles.q0=q;
% Transform and publish differents attitudes
UpdateAttitudes(q, handles);
% Redraw Cube
handles.Cube = RedrawCube(q,handles.Cube);

% --- Executes on button press in ResetCube.
function ResetCube_Callback(hObject, eventdata, handles)
% hObject    handle to ResetCube (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.m0 = [0;0;0];
handles.q0 = [1;0;0;0];

UpdateAttitudes(handles.q0,handles);
handles.Cube = RedrawCube(handles.q0,handles.Cube);
guidata(hObject, handles);

function v1_Callback(hObject, eventdata, handles)
% hObject    handle to v1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of v1 as text
%        str2double(get(hObject,'String')) returns contents of v1 as a double


% --- Executes during object creation, after setting all properties.
function v1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to v1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function v2_Callback(hObject, eventdata, handles)
% hObject    handle to v2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of v2 as text
%        str2double(get(hObject,'String')) returns contents of v2 as a double


% --- Executes during object creation, after setting all properties.
function v2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to v2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function v3_Callback(hObject, eventdata, handles)
% hObject    handle to v3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of v3 as text
%        str2double(get(hObject,'String')) returns contents of v3 as a double


% --- Executes during object creation, after setting all properties.
function v3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to v3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function roll_Callback(hObject, eventdata, handles)
% hObject    handle to roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of roll as text
%        str2double(get(hObject,'String')) returns contents of roll as a double


% --- Executes during object creation, after setting all properties.
function roll_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pitch_Callback(hObject, eventdata, handles)
% hObject    handle to pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pitch as text
%        str2double(get(hObject,'String')) returns contents of pitch as a double


% --- Executes during object creation, after setting all properties.
function pitch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pitch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function yaw_Callback(hObject, eventdata, handles)
% hObject    handle to yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yaw as text
%        str2double(get(hObject,'String')) returns contents of yaw as a double


% --- Executes during object creation, after setting all properties.
function yaw_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yaw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% Functions

function UpdateAttitudes(q, handles)
R = RotationMatrix(q);
% Set Quaternion
set(handles.q0_0,'String', num2str(q(1)));
set(handles.q1,'String', num2str(q(2)));
set(handles.q2,'String', num2str(q(3)));
set(handles.q3,'String', num2str(q(4)));

% Set Euler principal Angles and axis
[angle,u] = rotMat2Eaa(R);
set(handles.euler_x,'String', num2str(u(1)));
set(handles.euler_y,'String', num2str(u(2)));
set(handles.euler_z,'String', num2str(u(3)));
set(handles.euler_angle,'String', num2str(angle));

% Set Euler Angles
[yaw,pitch,roll] = rotM2eAngles(R);
set(handles.roll,'String', num2str(roll));
set(handles.pitch,'String', num2str(pitch));
set(handles.yaw,'String', num2str(yaw));

% Set Rotation Vector
vec = u*angle;
set(handles.v1,'String', num2str(vec(1)));
set(handles.v2,'String', num2str(vec(2)));
set(handles.v3,'String', num2str(vec(3)));


% Set Rotation Matrix 
set(handles.m1,'String',num2str(R(1,1)));
set(handles.m2,'String',num2str(R(1,2)));
set(handles.m3,'String',num2str(R(1,3)));
set(handles.m4,'String',num2str(R(2,1)));
set(handles.m5,'String',num2str(R(2,2)));
set(handles.m6,'String',num2str(R(2,3)));
set(handles.m7,'String',num2str(R(3,1)));
set(handles.m8,'String',num2str(R(3,2)));
set(handles.m9,'String',num2str(R(3,3)));

% Convert a 2d point to 3d 
function m = Map2DPointsTo3D(x,y)
r = sqrt(3);

if x*x+y*y < 0.5*r*r
    z = abs(sqrt(r*r-(x*x)-(y*y))); 
else
    z = (r*r)/(2*sqrt(x*x+y*y));
    modulePoint = norm([x;y;z]); 
    x = r*x/modulePoint;
    y = r*y/modulePoint;
    z = r*z/modulePoint;
end
m=[x;y;z];

% Convert 2 vectors into a quaternion
function q = QuaternionFromTwoVectors(u,v)
m = sqrt(2 + 2 * dot(u, v));
w = (1 / m) * cross(u, v);
q =[0.5 * m; w(1); w(2); w(3)];

% Multiply two quaternions
function w = MultQuaternion(q,v)
q0=q(1);
v0=v(1);
qv=q(2:4);
vv=v(2:4);

w=zeros(4,1);
w(1)=q0*v0-(qv'*vv);
w(2:4)=q0*vv +v0*qv +cross(qv,vv);

function R = RotationMatrix(q)
if q(1)==1
    R=eye(3);
else
    qv=q(2:4);
    qx = [0, -qv(3), qv(2); qv(3), 0, -qv(1); -qv(2), qv(1), 0];
    a=((q(1)*q(1))-(qv'*qv))*eye(3);
    b=2*(qv*qv');
    c=2*q(1)*qx;
    R= a+b+c;
    R=R/norm(R);
end

function q = RotationMatrix2Quaternion(R)
q(1) = sqrt((1+trace(R))/4);
q(2) = sqrt((1-trace(R)+2*R(1,1))/4);
q(3) = sqrt((1-trace(R)+2*R(2,2))/4);
q(4) = sqrt((1-trace(R)+2*R(3,3))/4);

ret=false;

for i=2:4
    if q(1)*q(1) > q(i)*q(i) && trace(R)>=0
        q(1) = sqrt(1+R(1,1)+R(2,2)+R(3,3));
        q(2) = (R(3,2)-R(2,3))/q(1);
        q(3) = (R(1,3)-R(3,1))/q(1);
        q(4) = (R(2,1)-R(1,2))/q(1);
        ret=true;
    end
end

if ret==false && trace(R)<0
    qmax = max([R(1,1),R(2,2),R(3,3)]);
    if R(1,1) == qmax
      for i=1:4
          if i==2
              i=3;
          end
          if q(2)*q(2) > q(i)*q(i)
              q(2) = sqrt(1+R(1,1)-R(2,2)-R(3,3));
              q(1) = (R(3,2)-R(2,3))/q(2);
              q(3) = (R(2,1)+R(1,2))/q(2);
              q(4) = (R(1,3)+R(3,1))/q(2);              
          end
      end

    elseif R(2,2) == qmax
      for i=1:4
          if i==3
              i=4;
          end
          if q(3)*q(3) > q(i)*q(i)
              q(3) = sqrt(1-R(1,1)+R(2,2)+R(3,3));
              q(1) = (R(1,3)-R(3,1))/q(3);
              q(2) = (R(2,1)+R(1,2))/q(3);
              q(4) = (R(3,2)+R(2,3))/q(3);              
          end
      end

    elseif R(3,3) == qmax
      for i=1:3
          if q(3)*q(3) > q(i)*q(i)
              q(4) = sqrt(1-R(1,1)-R(2,2)+R(3,3));
              q(1) = (R(2,1)-R(1,2))/q(4);
              q(2) = (R(1,3)+R(3,1))/q(4);
              q(3) = (R(3,2)+R(2,3))/q(4);              
          end
      end
    end
end
q=0.5*q;

function R = Eaa2rotMat(a,u)
% [R] = Eaa2rotMat(a,u)
% Computes the rotation matrix R given an angle and axis of rotation. 
% Inputs:
%	a: angle of rotation
%	u: axis of rotation 
% Outputs:
%	R: generated rotation matrix
u = u/norm(u);
I = eye(3);
Ux = [0,-u(3),u(2);u(3),0,-u(1);-u(2),u(1),0];
R = I*cosd(a) + (1-cosd(a))*(u*u') + Ux*sind(a);

function R = eAngles2rotM(roll, pitch, yaw)
% [R] = eAngles2rotM(roll, pitch, yaw)
% Computes the rotation matrix R given the Euler angles (yaw, pitch, roll). 
% Inputs:
%	yaw: angle of rotation around the z axis
%	pitch: angle of rotation around the y axis
%	roll: angle of rotation around the x axis
% Outputs:
%	R: rotation matrix
Ryaw=[cosd(yaw),sind(yaw),0;-sind(yaw),cosd(yaw),0;0,0,1];
Rpitch=[cosd(pitch),0,-sind(pitch);0,1,0;sind(pitch),0,cosd(pitch)];
Rroll=[1,0,0;0,cosd(roll),sind(roll);0,-sind(roll),cosd(roll)];
R=Ryaw'*Rpitch'*Rroll';


function [yaw, pitch, roll] = rotM2eAngles(R)
% [yaw, pitch, roll] = rotM2eAngles(R)
% Computes the Euler angles (yaw, pitch, roll) given an input rotation matrix R.
% Inputs:
%	R: rotation matrix
% Outputs:
%	yaw: angle of rotation around the z axis
%	pitch: angle of rotation around the y axis
%	roll: angle of rotation around the x axis
pitch=asind(-R(3,1));
if sind(pitch)==1
    roll=acosd(R(2,2));
    yaw=0;

elseif sind(pitch)==-1
    roll=acosd(R(2,2));
    yaw=0;

else
    roll=asind(R(3,2)/cosd(pitch));
    yaw=asind(R(2,1)/cosd(pitch));
end

function [a,u] = rotMat2Eaa(R)
% [a,u] = rotMat2Eaa(R)
% Computes the angle and principal axis of rotation given a rotation matrix R. 
% Inputs:
%	R: rotation matrix
% Outputs:
%	a: angle of rotation
%	u: axis of rotation 

a=acosd((trace(R)-1)/2);
if a==0
    u=[1;0;0];

elseif a==180
    M=(R+eye(3))/2;
    if (M(1,1))~= 0
        u(1)=sqrt(M(1,1));
        u(2)=M(1,2)/u(1);
        u(3)=M(1,3)/u(1);

    elseif (M(2,2))~= 0
        u(2)=sqrt(M(2,2));
        u(1)=M(2,1)/u(2);
        u(3)=M(2,3)/u(2);

    elseif (M(3,3))~= 0
        u(3)=sqrt(M(3,3));
        u(1)=M(3,1)/u(3);
        u(3)=M(3,2)/u(3);
    end
else
    Ux=(R-R')/(2*sind(a));
    u(1)=Ux(3,2);
    u(2)=Ux(1,3);
    u(3)=Ux(2,1);
end
